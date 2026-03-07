extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

const ADVANCE_ACTIONS := [&"attack_light", &"jump", &"ui_accept"]
const SKIP_HOLD_ACTIONS := [&"pause", &"ui_cancel"]
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
const UI_ACCENT := Color(0.34, 0.78, 0.98)
const UI_WARM_ACCENT := Color(0.96, 0.65, 0.28)
const NARRATOR_COLOR := Color(0.65, 0.78, 0.92, 0.9)
const TEXT_COLOR := Color(0.92, 0.94, 0.97)
const DEFAULT_CHARS_PER_SECOND: float = 35.0
const AUTO_ADVANCE_BASE: float = 1.8
const AUTO_ADVANCE_PER_CHAR: float = 0.035
const CROSSFADE_DURATION: float = 0.8
const VOICE_ADVANCE_PADDING: float = 0.8
const TEXT_LEAD_TIME: float = 0.3
const DIALOGUE_LEAD_IN: float = 0.4
const SKIP_HOLD_DURATION: float = 4.0

signal finished

@onready var _background: ColorRect = $Background
@onready var _title_bar: PanelContainer = $VBoxSplit/TitleBar
@onready var _eyebrow_label: Label = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/TitleStack/EyebrowLabel
@onready var _scene_title: Label = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/TitleStack/SceneTitle
@onready var _page_counter: Label = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/PageCounter
@onready var _skip_frame: PanelContainer = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/SkipFrame
@onready var _skip_prompt: Label = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/SkipFrame/SkipMargin/SkipVBox/SkipTextRow/SkipPrompt
@onready var _skip_countdown: Label = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/SkipFrame/SkipMargin/SkipVBox/SkipTextRow/SkipCountdown
@onready var _skip_track: PanelContainer = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/SkipFrame/SkipMargin/SkipVBox/SkipTrack
@onready var _skip_fill: ColorRect = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/TitleHBox/MetaVBox/SkipFrame/SkipMargin/SkipVBox/SkipTrack/SkipFill
@onready var _scene_progress_track: PanelContainer = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/SceneProgressTrack
@onready var _scene_progress_fill: ColorRect = $VBoxSplit/TitleBar/TitleMargin/TitleVBox/SceneProgressTrack/SceneProgressFill
@onready var _video_player: VideoStreamPlayer = $VBoxSplit/VideoRegion/AspectRatio/VideoPlayer
@onready var _video_region: PanelContainer = $VBoxSplit/VideoRegion
@onready var _dialogue_region: PanelContainer = $VBoxSplit/DialogueRegion
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
var _skip_hold_time: float = 0.0
var _skip_hold_action: StringName = &""
var _skip_prompt_base_text: String = "HOLD TO SKIP"
var _is_transitioning_out: bool = false


func setup(scenes: Array, destination: StringName = &"overworld", music: StringName = &"") -> void:
	_scenes = scenes
	_next_destination = destination
	_music_track = music


func _ready() -> void:
	UIStyleRef.apply_theme(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.change_phase(GameManager.Phase.CUTSCENE)
	InputManager.set_context(InputManager.InputContext.DIALOGUE)

	if _scenes.is_empty():
		_scenes = GameState.pending_cutscene_data
		_next_destination = GameState.pending_cutscene_next
		_music_track = GameState.pending_cutscene_music

	if _music_track != &"":
		EventBus.audio_music_requested.emit(_music_track, true)

	for _idx in 2:
		var voice_player := AudioStreamPlayer.new()
		voice_player.bus = &"Master"
		add_child(voice_player)
		_voice_players.append(voice_player)

	_skip_prompt_base_text = _resolve_skip_prompt_text()

	_apply_styles()
	_build_background_fx()
	_build_screen_fx()
	_play_intro_fade()
	_refresh_scene_progress()
	_refresh_skip_ui()

	if _scenes.is_empty():
		push_error("CutscenePlayer: No scene data provided.")
		_on_cutscene_finished()
		return

	_start_scene(0)


func _process(delta: float) -> void:
	_update_skip_hold(delta)

	if _is_transitioning_out:
		return

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

	if _continue_indicator:
		var pulse: float = 0.35 + 0.65 * abs(sin(Time.get_ticks_msec() * 0.0035))
		_continue_indicator.modulate.a = pulse
		_continue_indicator.visible = _is_waiting


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if _consume_skip_hold_event(event):
		return

	if _is_transitioning_out or not _is_advance_press_event(event):
		return

	get_viewport().set_input_as_handled()

	if _is_typewriting:
		_text_label.visible_characters = -1
		_is_typewriting = false
		_is_waiting = true
		_auto_advance_timer = _get_auto_advance_time()
	elif _is_waiting:
		_advance_line()


func _apply_styles() -> void:
	_eyebrow_label.text = "CUTSCENE"
	_continue_indicator.text = "TAP TO ADVANCE"

	var title_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.10, 0.92),
		Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.34),
		8
	)
	title_style.shadow_size = 18
	title_style.shadow_color = Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.1)
	_title_bar.add_theme_stylebox_override("panel", title_style)

	var video_style := UIStyleRef.create_panel_style(
		Color(0.01, 0.02, 0.04, 0.96),
		Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.42),
		10
	)
	video_style.content_margin_left = 18
	video_style.content_margin_right = 18
	video_style.content_margin_top = 18
	video_style.content_margin_bottom = 18
	video_style.shadow_size = 20
	video_style.shadow_color = Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.12)
	_video_region.add_theme_stylebox_override("panel", video_style)

	var region_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.10, 0.94),
		Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.18),
		0
	)
	_dialogue_region.add_theme_stylebox_override("panel", region_style)

	var panel_style := UIStyleRef.create_panel_style(
		Color(0.05, 0.08, 0.14, 0.72),
		Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.26),
		8
	)
	panel_style.shadow_size = 14
	panel_style.shadow_color = Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.08)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	var portrait_style := UIStyleRef.create_panel_style(
		Color(0.03, 0.05, 0.09, 0.76),
		Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 0.3),
		6
	)
	portrait_style.content_margin_left = 6
	portrait_style.content_margin_right = 6
	portrait_style.content_margin_top = 6
	portrait_style.content_margin_bottom = 6
	_portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	_portrait_frame.visible = false

	var skip_style := UIStyleRef.create_panel_style(
		Color(0.05, 0.08, 0.13, 0.8),
		Color(UI_WARM_ACCENT.r, UI_WARM_ACCENT.g, UI_WARM_ACCENT.b, 0.42),
		8
	)
	skip_style.shadow_size = 14
	skip_style.shadow_color = Color(UI_WARM_ACCENT.r, UI_WARM_ACCENT.g, UI_WARM_ACCENT.b, 0.1)
	_skip_frame.add_theme_stylebox_override("panel", skip_style)

	var scene_progress_style := StyleBoxFlat.new()
	scene_progress_style.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	scene_progress_style.corner_radius_top_left = 4
	scene_progress_style.corner_radius_top_right = 4
	scene_progress_style.corner_radius_bottom_left = 4
	scene_progress_style.corner_radius_bottom_right = 4
	scene_progress_style.anti_aliasing = true
	_scene_progress_track.add_theme_stylebox_override("panel", scene_progress_style)
	_scene_progress_track.clip_contents = true

	var skip_track_style := scene_progress_style.duplicate() as StyleBoxFlat
	skip_track_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	_skip_track.add_theme_stylebox_override("panel", skip_track_style)
	_skip_track.clip_contents = true

	_continue_indicator.add_theme_font_size_override("font_size", 13)
	_continue_indicator.add_theme_color_override("font_color", Color(0.72, 0.84, 0.96, 0.9))
	_continue_indicator.visible = false
	_text_label.scroll_active = false


func _build_background_fx() -> void:
	var bg_gradient := UIStyleRef.create_gradient_bg(Color(0.02, 0.03, 0.07), Color(0.06, 0.09, 0.16))
	_background.material = bg_gradient.material
	_background.add_child(UIStyleRef.create_glow_orb(Color(0.12, 0.35, 0.8), 0.14))


func _build_screen_fx() -> void:
	_fx_layer.add_child(UIStyleRef.create_particle_field(get_viewport_rect().size, Color(0.38, 0.56, 0.92, 0.04), 8))
	if GameState.scanlines_enabled:
		_scanlines_node = UIStyleRef.create_scanlines(0.022)
		_fx_layer.add_child(_scanlines_node)
	_fx_layer.add_child(UIStyleRef.create_vignette(0.46))


func _play_intro_fade() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)


func _get_portrait(speaker: String) -> Texture2D:
	if speaker in _portrait_cache:
		return _portrait_cache[speaker]

	var path: String = PORTRAIT_PATHS.get(speaker, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null

	var texture := load(path) as Texture2D
	_portrait_cache[speaker] = texture
	return texture


func _update_portrait(speaker: String) -> void:
	var texture := _get_portrait(speaker)
	if texture:
		_portrait.texture = texture
		_portrait_frame.visible = true
		var accent: Color = SPEAKER_COLORS.get(speaker, UI_ACCENT)
		var frame_style := UIStyleRef.create_panel_style(
			Color(0.03, 0.05, 0.09, 0.76),
			Color(accent.r, accent.g, accent.b, 0.46),
			6
		)
		frame_style.content_margin_left = 6
		frame_style.content_margin_right = 6
		frame_style.content_margin_top = 6
		frame_style.content_margin_bottom = 6
		frame_style.shadow_size = 12
		frame_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.12)
		_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	else:
		_portrait_frame.visible = false


func _start_scene(index: int) -> void:
	if _is_transitioning_out:
		return

	if index >= _scenes.size():
		_on_cutscene_finished()
		return

	_current_scene_idx = index
	_current_line_idx = 0

	var scene_data: Dictionary = _scenes[index]
	var video_path: String = scene_data.get("video", "")
	var scene_title: String = scene_data.get("title", "")
	var scene_eyebrow: String = scene_data.get("eyebrow", "CUTSCENE")

	_eyebrow_label.text = scene_eyebrow
	_scene_title.text = scene_title
	_page_counter.text = "CARD %d OF %d" % [index + 1, _scenes.size()]
	_refresh_scene_progress()

	if not video_path.is_empty() and ResourceLoader.exists(video_path):
		_video_player.stream = load(video_path)
		_video_player.modulate.a = 1.0
		_video_player.play()
	else:
		_video_player.stop()
		_video_player.stream = null

	_clear_dialogue_state()

	await get_tree().create_timer(DIALOGUE_LEAD_IN).timeout
	if _is_transitioning_out or _current_scene_idx != index:
		return
	_show_line(0)


func _show_line(index: int) -> void:
	if _is_transitioning_out:
		return

	var scene_data: Dictionary = _scenes[_current_scene_idx]
	var lines: Array = scene_data.get("lines", [])
	if index >= lines.size():
		_advance_scene()
		return

	_current_line_idx = index
	var line: Dictionary = lines[index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	if speaker.is_empty() or speaker == "NARRATOR":
		_speaker_label.text = ""
		_speaker_label.visible = false
		_portrait_frame.visible = false
	else:
		_speaker_label.text = speaker
		_speaker_label.visible = true
		_speaker_label.add_theme_color_override("font_color", SPEAKER_COLORS.get(speaker, TEXT_COLOR))
		_update_portrait(speaker)

	_text_label.text = text
	if speaker.is_empty() or speaker == "NARRATOR":
		_text_label.add_theme_color_override("default_color", NARRATOR_COLOR)
	else:
		_text_label.add_theme_color_override("default_color", TEXT_COLOR)

	_play_voice(line.get("voice", ""))

	_total_chars = text.length()
	if _current_voice_duration > 0.0 and _total_chars > 0:
		var target_time := maxf(_current_voice_duration - TEXT_LEAD_TIME, 0.5)
		_line_chars_per_second = _total_chars / target_time
	else:
		_line_chars_per_second = DEFAULT_CHARS_PER_SECOND

	_text_label.visible_characters = 0
	_typewriter_timer = 0.0
	_is_typewriting = true
	_is_waiting = false


func _play_voice(voice_path: String) -> void:
	_voice_players[_active_voice_idx].stop()
	_active_voice_idx = 1 - _active_voice_idx
	_voice_players[_active_voice_idx].stop()
	_current_voice_duration = 0.0

	if voice_path.is_empty():
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
	for voice_player in _voice_players:
		voice_player.stop()
	_current_voice_duration = 0.0


func _get_auto_advance_time() -> float:
	if _current_voice_duration > 0.0:
		var voice_remaining := _current_voice_duration - _typewriter_timer
		return maxf(voice_remaining, 0.0) + VOICE_ADVANCE_PADDING
	return AUTO_ADVANCE_BASE + _total_chars * AUTO_ADVANCE_PER_CHAR


func _advance_line() -> void:
	if _is_transitioning_out:
		return
	_is_waiting = false
	_show_line(_current_line_idx + 1)


func _advance_scene() -> void:
	if _is_transitioning_out:
		return

	var next_idx := _current_scene_idx + 1
	if next_idx >= _scenes.size():
		_on_cutscene_finished()
		return

	if _crossfade_tween != null:
		_crossfade_tween.kill()

	_stop_voice()
	_clear_dialogue_state()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_trans(Tween.TRANS_CUBIC)
	_crossfade_tween.set_ease(Tween.EASE_IN_OUT)
	_crossfade_tween.tween_property(_video_player, "modulate:a", 0.0, CROSSFADE_DURATION * 0.5)
	_crossfade_tween.tween_callback(func() -> void:
		_start_scene(next_idx)
	)
	_crossfade_tween.tween_property(_video_player, "modulate:a", 1.0, CROSSFADE_DURATION * 0.5)


func _clear_dialogue_state() -> void:
	_speaker_label.text = ""
	_speaker_label.visible = false
	_text_label.text = ""
	_text_label.visible_characters = -1
	_portrait_frame.visible = false
	_is_typewriting = false
	_is_waiting = false
	_continue_indicator.visible = false


func _is_advance_press_event(event: InputEvent) -> bool:
	for action in ADVANCE_ACTIONS:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false


func _consume_skip_hold_event(event: InputEvent) -> bool:
	for action in SKIP_HOLD_ACTIONS:
		if not InputMap.has_action(action):
			continue
		if event.is_action_pressed(action):
			_skip_hold_action = action
			_skip_hold_time = 0.0
			_refresh_skip_ui()
			get_viewport().set_input_as_handled()
			return true
		if event.is_action_released(action):
			if _skip_hold_action == action and _skip_hold_time < SKIP_HOLD_DURATION:
				_cancel_skip_hold()
			get_viewport().set_input_as_handled()
			return true
	return false


func _get_active_skip_hold_action() -> StringName:
	if _skip_hold_action != &"" and InputMap.has_action(_skip_hold_action) and Input.is_action_pressed(_skip_hold_action):
		return _skip_hold_action
	for action in SKIP_HOLD_ACTIONS:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return action
	return &""


func _update_skip_hold(delta: float) -> void:
	var active_action := _get_active_skip_hold_action()
	if active_action == &"":
		if _skip_hold_time > 0.0 or _skip_hold_action != &"":
			_cancel_skip_hold()
		return

	if _skip_hold_action != active_action:
		_skip_hold_action = active_action
		_skip_hold_time = 0.0

	if _is_transitioning_out:
		return

	_skip_hold_time = minf(_skip_hold_time + delta, SKIP_HOLD_DURATION)
	_refresh_skip_ui()

	if _skip_hold_time >= SKIP_HOLD_DURATION:
		_trigger_skip()


func _cancel_skip_hold() -> void:
	_skip_hold_action = &""
	_skip_hold_time = 0.0
	_refresh_skip_ui()


func _trigger_skip() -> void:
	if _is_transitioning_out:
		return
	_skip_hold_time = SKIP_HOLD_DURATION
	_refresh_skip_ui()
	_on_cutscene_finished()


func _resolve_skip_prompt_text() -> String:
	if InputMap.has_action(&"pause"):
		return "HOLD ESC / START TO SKIP"
	if InputMap.has_action(&"ui_cancel"):
		return "HOLD CANCEL TO SKIP"
	return "HOLD TO SKIP"


func _refresh_skip_ui() -> void:
	var fill := clampf(_skip_hold_time / SKIP_HOLD_DURATION, 0.0, 1.0)
	var accent := UI_ACCENT.lerp(UI_WARM_ACCENT, fill)
	_skip_fill.scale.x = fill
	_skip_fill.color = Color(accent.r, accent.g, accent.b, 0.96)
	_skip_countdown.modulate = accent

	if _is_transitioning_out and fill >= 1.0:
		_skip_prompt.text = "SKIPPING"
		_skip_countdown.text = "GO"
	elif fill > 0.0:
		_skip_prompt.text = "RELEASE TO CANCEL"
		_skip_countdown.text = "%.1fs" % maxf(SKIP_HOLD_DURATION - _skip_hold_time, 0.0)
	else:
		_skip_prompt.text = _skip_prompt_base_text
		_skip_countdown.text = "%.1fs" % SKIP_HOLD_DURATION

	_skip_frame.modulate.a = 0.86 + fill * 0.14


func _refresh_scene_progress() -> void:
	if _scenes.is_empty():
		_scene_progress_fill.scale.x = 0.0
		return
	var progress := float(_current_scene_idx + 1) / float(maxi(_scenes.size(), 1))
	_scene_progress_fill.scale.x = clampf(progress, 0.0, 1.0)


func _on_cutscene_finished() -> void:
	if _is_transitioning_out:
		return

	_is_transitioning_out = true
	_stop_voice()
	_clear_dialogue_state()
	if _crossfade_tween != null:
		_crossfade_tween.kill()
	_crossfade_tween = null
	finished.emit()
	_refresh_skip_ui()

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
