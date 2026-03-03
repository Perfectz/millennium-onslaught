## Reusable cinematic cutscene player with split layout.
## Title bar at top (scene title + page counter), video centered with aspect
## ratio preserved, portrait + dialogue panel below. Videos loop while
## dialogue auto-advances with typewriter effect. Press to skip or advance.
extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

const SPEAKER_COLORS: Dictionary = {
	"ALYS": Color(0.3, 0.72, 1.0),
	"CHAZ": Color(0.4, 0.9, 0.5),
	"RUNE": Color(0.8, 0.5, 1.0),
	"WREN": Color(1.0, 0.7, 0.3),
}
const PORTRAIT_PATHS: Dictionary = {
	"ALYS": "res://assets/textures/portraits/alys_portrait.png",
	"CHAZ": "res://assets/textures/portraits/chaz_portrait.png",
	"RUNE": "res://assets/textures/portraits/rune_portrait.png",
	"WREN": "res://assets/textures/portraits/wren_portrait.png",
}
const NARRATOR_COLOR := Color(0.65, 0.78, 0.92, 0.9)
const TEXT_COLOR := Color(0.92, 0.94, 0.97)
const DEFAULT_CHARS_PER_SECOND: float = 35.0
const AUTO_ADVANCE_BASE: float = 1.8
const AUTO_ADVANCE_PER_CHAR: float = 0.035
const CROSSFADE_DURATION: float = 0.8
const VOICE_ADVANCE_PADDING: float = 0.8
const TEXT_LEAD_TIME: float = 0.3

signal finished

@onready var _title_bar: PanelContainer = $VBoxSplit/TitleBar
@onready var _scene_title: Label = $VBoxSplit/TitleBar/TitleMargin/TitleHBox/SceneTitle
@onready var _page_counter: Label = $VBoxSplit/TitleBar/TitleMargin/TitleHBox/PageCounter
@onready var _video_player: VideoStreamPlayer = $VBoxSplit/VideoRegion/AspectRatio/VideoPlayer
@onready var _video_region: PanelContainer = $VBoxSplit/VideoRegion
@onready var _dialogue_panel: PanelContainer = $VBoxSplit/DialogueRegion/DialoguePanel
@onready var _portrait_frame: PanelContainer = $VBoxSplit/DialogueRegion/DialoguePanel/DialogueMargin/HBox/PortraitFrame
@onready var _portrait: TextureRect = $VBoxSplit/DialogueRegion/DialoguePanel/DialogueMargin/HBox/PortraitFrame/Portrait
@onready var _speaker_label: Label = $VBoxSplit/DialogueRegion/DialoguePanel/DialogueMargin/HBox/TextColumn/SpeakerLabel
@onready var _text_label: RichTextLabel = $VBoxSplit/DialogueRegion/DialoguePanel/DialogueMargin/HBox/TextColumn/TextLabel
@onready var _continue_indicator: Label = $VBoxSplit/DialogueRegion/ContinueIndicator
@onready var _fx_layer: Control = $FXLayer

var _scenes: Array = []
var _current_scene_idx: int = 0
var _current_line_idx: int = 0
var _typewriter_timer: float = 0.0
var _auto_advance_timer: float = 0.0
var _total_chars: int = 0
var _is_typewriting: bool = false
var _is_waiting: bool = false
var _crossfade_tween: Tween = null
var _portrait_cache: Dictionary = {}
var _next_destination: StringName = &"overworld"
var _music_track: StringName = &""
var _scanlines_node: Control = null
var _voice_players: Array[AudioStreamPlayer] = []
var _active_voice_idx: int = 0
var _voice_cache: Dictionary = {}
var _current_voice_duration: float = 0.0
var _line_chars_per_second: float = DEFAULT_CHARS_PER_SECOND


## Call before adding to scene tree to configure cutscene data.
func setup(scenes: Array, destination: StringName = &"overworld", music: StringName = &"") -> void:
	_scenes = scenes
	_next_destination = destination
	_music_track = music


func _ready() -> void:
	UIStyleRef.apply_theme(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.change_phase(GameManager.Phase.CUTSCENE)

	# Load scenes from GameState if not set via setup().
	if _scenes.is_empty():
		_scenes = GameState.pending_cutscene_data
		_next_destination = GameState.pending_cutscene_next
		_music_track = GameState.pending_cutscene_music

	# Start cutscene music if provided.
	if _music_track != &"":
		EventBus.audio_music_requested.emit(_music_track, true)

	# Two voice players — alternate to avoid stop/play-in-same-frame issues.
	for i in 2:
		var vp := AudioStreamPlayer.new()
		vp.bus = &"Master"
		add_child(vp)
		_voice_players.append(vp)
	_active_voice_idx = 0

	_apply_styles()
	_build_screen_fx()
	_play_intro_fade()

	if _scenes.is_empty():
		push_error("CutscenePlayer: No scene data provided.")
		_on_cutscene_finished()
		return

	_start_scene(0)


func _process(delta: float) -> void:
	if _is_typewriting:
		_typewriter_timer += delta
		var visible_count := int(_typewriter_timer * _line_chars_per_second)
		if visible_count >= _total_chars:
			_text_label.visible_characters = -1
			_is_typewriting = false
			_is_waiting = true
			_auto_advance_timer = _get_auto_advance_time()
		else:
			_text_label.visible_characters = visible_count
	elif _is_waiting:
		_auto_advance_timer -= delta
		if _auto_advance_timer <= 0.0:
			_advance_line()

	# Pulse continue indicator.
	if _continue_indicator:
		_continue_indicator.modulate.a = 0.3 + 0.7 * abs(sin(Time.get_ticks_msec() * 0.003))
		_continue_indicator.visible = _is_waiting


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	var pressed := event.is_action_pressed(&"attack_light") \
		or event.is_action_pressed(&"jump") \
		or event.is_action_pressed(&"ui_accept")
	if not pressed:
		return

	get_viewport().set_input_as_handled()

	if _is_typewriting:
		# Skip typewriter — show full text immediately.
		_text_label.visible_characters = -1
		_is_typewriting = false
		_is_waiting = true
		_auto_advance_timer = _get_auto_advance_time()
	elif _is_waiting:
		_advance_line()


# ── Visual Setup ─────────────────────────────────────────────────────


func _apply_styles() -> void:
	# Title bar — dark glass with subtle bottom accent.
	var title_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.10, 0.90),
		Color(0.25, 0.55, 0.9, 0.2),
		0
	)
	_title_bar.add_theme_stylebox_override("panel", title_style)

	# Video region — black background.
	var video_style := StyleBoxFlat.new()
	video_style.bg_color = Color(0, 0, 0, 1)
	_video_region.add_theme_stylebox_override("panel", video_style)

	# Dialogue region background — dark glass.
	var region_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.10, 0.95),
		Color(0.2, 0.45, 0.8, 0.15),
		0
	)
	$VBoxSplit/DialogueRegion.add_theme_stylebox_override("panel", region_style)

	# Inner dialogue panel — subtle glass with border.
	var panel_style := UIStyleRef.create_panel_style(
		Color(0.04, 0.07, 0.12, 0.55),
		Color(0.3, 0.6, 0.9, 0.2),
		4
	)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	# Portrait frame — accent border glass panel.
	var portrait_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.09, 0.7),
		Color(0.3, 0.6, 0.9, 0.35),
		4
	)
	portrait_style.content_margin_left = 6
	portrait_style.content_margin_right = 6
	portrait_style.content_margin_top = 6
	portrait_style.content_margin_bottom = 6
	_portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	_portrait_frame.visible = false

	# Continue indicator.
	_continue_indicator.visible = false


func _build_screen_fx() -> void:
	if GameState.scanlines_enabled:
		_scanlines_node = UIStyleRef.create_scanlines(0.025)
		_fx_layer.add_child(_scanlines_node)
	_fx_layer.add_child(UIStyleRef.create_vignette(0.4))


func _play_intro_fade() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)


# ── Portraits ────────────────────────────────────────────────────────


func _get_portrait(speaker: String) -> Texture2D:
	if speaker in _portrait_cache:
		return _portrait_cache[speaker]
	var path: String = PORTRAIT_PATHS.get(speaker, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	_portrait_cache[speaker] = tex
	return tex


func _update_portrait(speaker: String) -> void:
	var tex := _get_portrait(speaker)
	if tex:
		_portrait.texture = tex
		_portrait_frame.visible = true
		# Tint portrait border with speaker color.
		var color: Color = SPEAKER_COLORS.get(speaker, Color(0.3, 0.6, 0.9))
		var frame_style := UIStyleRef.create_panel_style(
			Color(0.03, 0.05, 0.09, 0.7),
			Color(color.r, color.g, color.b, 0.4),
			4
		)
		frame_style.content_margin_left = 6
		frame_style.content_margin_right = 6
		frame_style.content_margin_top = 6
		frame_style.content_margin_bottom = 6
		_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	else:
		_portrait_frame.visible = false


# ── Scene Playback ───────────────────────────────────────────────────


func _start_scene(index: int) -> void:
	if index >= _scenes.size():
		_on_cutscene_finished()
		return

	_current_scene_idx = index
	_current_line_idx = 0

	var scene_data: Dictionary = _scenes[index]
	var video_path: String = scene_data.get("video", "")
	var scene_title: String = scene_data.get("title", "")

	# Update title bar.
	_scene_title.text = scene_title
	_page_counter.text = "%d / %d" % [index + 1, _scenes.size()]

	if video_path != "":
		_video_player.stream = load(video_path)
		_video_player.play()

	# Clear dialogue and show first line.
	_speaker_label.text = ""
	_text_label.text = ""
	_text_label.visible_characters = -1
	_portrait_frame.visible = false
	_is_typewriting = false
	_is_waiting = false

	# Brief pause before starting dialogue.
	await get_tree().create_timer(0.4).timeout
	_show_line(0)


func _show_line(index: int) -> void:
	var scene_data: Dictionary = _scenes[_current_scene_idx]
	var lines: Array = scene_data.get("lines", [])

	if index >= lines.size():
		_advance_scene()
		return

	_current_line_idx = index
	var line: Dictionary = lines[index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	# Configure speaker label and portrait.
	if speaker == "" or speaker == "NARRATOR":
		_speaker_label.text = ""
		_speaker_label.visible = false
		_portrait_frame.visible = false
	else:
		_speaker_label.text = speaker
		_speaker_label.visible = true
		_speaker_label.add_theme_color_override("font_color",
			SPEAKER_COLORS.get(speaker, TEXT_COLOR))
		_update_portrait(speaker)

	# Configure text with appropriate color.
	_text_label.text = text
	if speaker == "" or speaker == "NARRATOR":
		_text_label.add_theme_color_override("default_color", NARRATOR_COLOR)
	else:
		_text_label.add_theme_color_override("default_color", TEXT_COLOR)

	# Play voice clip if present.
	_play_voice(line.get("voice", ""))

	# Start typewriter — sync speed to voice clip when available.
	_total_chars = text.length()
	if _current_voice_duration > 0.0 and _total_chars > 0:
		# Text finishes slightly before voice ends so player can read ahead.
		var target_time := maxf(_current_voice_duration - TEXT_LEAD_TIME, 0.5)
		_line_chars_per_second = _total_chars / target_time
	else:
		_line_chars_per_second = DEFAULT_CHARS_PER_SECOND

	_text_label.visible_characters = 0
	_typewriter_timer = 0.0
	_is_typewriting = true
	_is_waiting = false


func _play_voice(voice_path: String) -> void:
	# Stop the previous player and swap to the other one.
	_voice_players[_active_voice_idx].stop()
	_active_voice_idx = 1 - _active_voice_idx
	_voice_players[_active_voice_idx].stop()
	_current_voice_duration = 0.0
	if voice_path == "":
		return
	var stream: AudioStream = _voice_cache.get(voice_path)
	if stream == null and ResourceLoader.exists(voice_path):
		stream = load(voice_path)
		_voice_cache[voice_path] = stream
	if stream:
		var player := _voice_players[_active_voice_idx]
		player.stream = stream
		player.play()
		_current_voice_duration = stream.get_length()


func _stop_voice() -> void:
	for vp in _voice_players:
		vp.stop()
	_current_voice_duration = 0.0


## Return wait time after typewriter finishes. Uses voice remaining time if voiced.
func _get_auto_advance_time() -> float:
	if _current_voice_duration > 0.0:
		# Wait for voice clip to finish, then pause briefly.
		var voice_remaining := _current_voice_duration - _typewriter_timer
		return maxf(voice_remaining, 0.0) + VOICE_ADVANCE_PADDING
	return AUTO_ADVANCE_BASE + _total_chars * AUTO_ADVANCE_PER_CHAR


func _advance_line() -> void:
	_is_waiting = false
	# Don't call _stop_voice() here — _play_voice() handles stopping the
	# previous clip. Double-stopping in the same frame can break playback.
	_show_line(_current_line_idx + 1)


func _advance_scene() -> void:
	var next_idx := _current_scene_idx + 1
	if next_idx >= _scenes.size():
		_on_cutscene_finished()
		return

	# Crossfade to next scene video.
	if _crossfade_tween != null:
		_crossfade_tween.kill()

	_stop_voice()
	_is_typewriting = false
	_is_waiting = false
	_speaker_label.text = ""
	_text_label.text = ""
	_portrait_frame.visible = false
	_continue_indicator.visible = false

	_crossfade_tween = create_tween()
	_crossfade_tween.set_trans(Tween.TRANS_CUBIC)
	_crossfade_tween.set_ease(Tween.EASE_IN_OUT)
	_crossfade_tween.tween_property(_video_player, "modulate:a", 0.0, CROSSFADE_DURATION * 0.5)
	_crossfade_tween.tween_callback(func() -> void:
		_start_scene(next_idx)
	)
	_crossfade_tween.tween_property(_video_player, "modulate:a", 1.0, CROSSFADE_DURATION * 0.5)


func _on_cutscene_finished() -> void:
	_stop_voice()
	finished.emit()

	# Fade out then navigate.
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		match _next_destination:
			&"overworld":
				GameManager.go_to_overworld()
			&"town":
				GameManager.go_to_town(GameState.pending_town_id)
			&"dungeon":
				GameManager.go_to_dungeon(GameState.pending_dungeon_id)
			_:
				GameManager.go_to_overworld()
	)
