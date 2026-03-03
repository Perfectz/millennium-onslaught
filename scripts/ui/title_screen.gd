## Modern title screen with video reel and glass UI.
extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var _bg: ColorRect = $Background
@onready var _bg_glow: ColorRect = $BackgroundGlow
@onready var _video_player: VideoStreamPlayer = $Content/HBox/RightColumn/VideoFrame/KeyArt
@onready var _options_panel: PanelContainer = $Content/HBox/LeftColumn/OptionsPanel
@onready var _status_label: Label = $Content/HBox/LeftColumn/StatusLabel
@onready var _new_game_btn: Button = $Content/HBox/LeftColumn/ButtonRows/NewGameButton
@onready var _continue_btn: Button = $Content/HBox/LeftColumn/ButtonRows/ContinueButton
@onready var _options_btn: Button = $Content/HBox/LeftColumn/ButtonRows/OptionsButton
@onready var _quit_btn: Button = $Content/HBox/LeftColumn/ButtonRows/QuitButton
@onready var _nebula_video: VideoStreamPlayer = $Content/HBox/LeftColumn/NebulaFrame/NebulaVideo
@onready var _scanline_check: CheckBox = $Content/HBox/LeftColumn/OptionsPanel/OptionsMargin/OptionsVBox/ScanlineCheck

var _video_streams: Array = []
var _current_video_index: int = 0
var _bg_time: float = 0.0
var _options_open: bool = false
var _options_tween: Tween = null
var _video_crossfade_tween: Tween = null
var _menu_buttons: Array[Button] = []


func _ready() -> void:
	UIStyleRef.apply_theme(self)
	GameManager.change_phase(GameManager.Phase.MAIN_MENU)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_background_effects()
	_style_buttons()
	_style_options_panel()
	_bind_buttons()
	_setup_video_reel()
	_setup_nebula_video()
	_refresh_continue_state()
	_prepare_options_panel()
	_setup_controller_navigation()
	_build_screen_fx()
	_play_intro()
	EventBus.audio_music_requested.emit(&"title", true)


func _process(_delta: float) -> void:
	pass


# ── Visual Setup ─────────────────────────────────────────────────────


func _apply_background_effects() -> void:
	var bg_shader := Shader.new()
	bg_shader.code = """
shader_type canvas_item;
void fragment() {
	vec3 top = vec3(0.02, 0.02, 0.06);
	vec3 bot = vec3(0.05, 0.06, 0.12);
	COLOR = vec4(mix(top, bot, UV.y), 1.0);
}
"""
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = bg_shader
	_bg.material = bg_mat

	# Reuse shared glow orb shader on existing BackgroundGlow node.
	var glow_ref := UIStyleRef.create_glow_orb(Color(0.12, 0.35, 0.8), 0.18)
	_bg_glow.material = glow_ref.material


func _style_buttons() -> void:
	var accent := Color(0.3, 0.72, 1.0)
	var quit_accent := Color(0.85, 0.35, 0.4)
	UIStyleRef.style_button(_new_game_btn, Color.BLACK, accent, 20)
	UIStyleRef.style_button(_continue_btn, Color.BLACK, accent, 20)
	UIStyleRef.style_button(_options_btn, Color.BLACK, accent, 20)
	UIStyleRef.style_button(_quit_btn, Color.BLACK, quit_accent, 20)


func _style_options_panel() -> void:
	var s := UIStyleRef.create_panel_style(
		Color(0.04, 0.07, 0.12, 0.55),
		Color(0.3, 0.6, 0.9, 0.35),
		4
	)
	s.content_margin_left = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	_options_panel.add_theme_stylebox_override("panel", s)


func _build_screen_fx() -> void:
	var fx := Control.new()
	fx.name = "FXLayer"
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	fx.add_child(UIStyleRef.create_particle_field(Vector2(1920, 1080), Color(0.3, 0.6, 1.0, 0.08), 20))
	if GameState.scanlines_enabled:
		fx.add_child(UIStyleRef.create_scanlines(0.035))
	fx.add_child(UIStyleRef.create_vignette(0.55))


# ── Buttons & Navigation ────────────────────────────────────────────


func _bind_buttons() -> void:
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_options_btn.pressed.connect(_on_options_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	# Wire UI sounds to all menu buttons.
	for btn in [_new_game_btn, _continue_btn, _options_btn, _quit_btn]:
		UIStyleRef.wire_button_sounds(btn)


func _setup_controller_navigation() -> void:
	_menu_buttons = [_new_game_btn, _continue_btn, _options_btn, _quit_btn]
	for i in _menu_buttons.size():
		var current := _menu_buttons[i]
		var next := _menu_buttons[(i + 1) % _menu_buttons.size()]
		var prev := _menu_buttons[(i - 1 + _menu_buttons.size()) % _menu_buttons.size()]
		current.focus_mode = Control.FOCUS_ALL
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_top = current.get_path_to(prev)
	_focus_first_available()


func _focus_first_available() -> void:
	for button in _menu_buttons:
		if button.visible and not button.disabled:
			button.grab_focus()
			return


func _focus_next(direction: int) -> void:
	if _menu_buttons.is_empty():
		return

	var focused := get_viewport().gui_get_focus_owner()
	var current_idx := _menu_buttons.find(focused as Button)
	if current_idx == -1:
		_focus_first_available()
		return

	var idx := current_idx
	for i in _menu_buttons.size():
		idx = posmod(idx + direction, _menu_buttons.size())
		var candidate := _menu_buttons[idx]
		if candidate.visible and not candidate.disabled:
			candidate.grab_focus()
			return


# ── Video Reel ───────────────────────────────────────────────────────


func _setup_video_reel() -> void:
	_video_streams = [
		preload("res://assets/textures/title_hero_evil_1.ogv"),
		preload("res://assets/textures/title_hero_evil_2.ogv"),
		preload("res://assets/textures/title_hero_move.ogv"),
	]
	_video_player.finished.connect(_on_video_finished)
	_current_video_index = 0
	_play_current_video()


func _play_current_video() -> void:
	_video_player.stream = _video_streams[_current_video_index]
	_video_player.modulate.a = 1.0
	_video_player.play()


func _on_video_finished() -> void:
	_current_video_index = (_current_video_index + 1) % _video_streams.size()
	_crossfade_to_next_video()


func _crossfade_to_next_video() -> void:
	if _video_crossfade_tween != null:
		_video_crossfade_tween.kill()

	_video_crossfade_tween = create_tween()
	_video_crossfade_tween.set_trans(Tween.TRANS_CUBIC)
	_video_crossfade_tween.set_ease(Tween.EASE_IN_OUT)
	# Fade out current video.
	_video_crossfade_tween.tween_property(_video_player, "modulate:a", 0.0, 0.4)
	# Swap stream and fade back in.
	_video_crossfade_tween.tween_callback(func() -> void:
		_video_player.stream = _video_streams[_current_video_index]
		_video_player.play()
	)
	_video_crossfade_tween.tween_property(_video_player, "modulate:a", 1.0, 0.4)


## Set up the nebula background video with feathered edges and 70% opacity.
func _setup_nebula_video() -> void:
	_nebula_video.stream = preload("res://assets/textures/title_galaxy.ogv")
	_nebula_video.modulate = Color(1, 1, 1, 0.7)

	var feather_shader := Shader.new()
	feather_shader.code = """
shader_type canvas_item;
uniform float edge_fade : hint_range(0.0, 0.5) = 0.15;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float fade_x = smoothstep(0.0, edge_fade, UV.x) * smoothstep(0.0, edge_fade, 1.0 - UV.x);
	float fade_y = smoothstep(0.0, edge_fade, UV.y) * smoothstep(0.0, edge_fade, 1.0 - UV.y);
	tex.a *= fade_x * fade_y;
	COLOR = tex;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = feather_shader
	_nebula_video.material = mat
	_nebula_video.play()


# ── State ────────────────────────────────────────────────────────────


func _refresh_continue_state() -> void:
	var save_count := 0
	for slot in 3:
		if SaveManager.has_save(slot):
			save_count += 1
	if save_count > 0:
		_continue_btn.disabled = false
		_continue_btn.text = "Load Game"
		_status_label.text = "%d save%s found" % [save_count, "" if save_count == 1 else "s"]
		return

	_continue_btn.disabled = true
	_continue_btn.text = "Load Game"
	_status_label.text = "No save data found."


func _prepare_options_panel() -> void:
	_options_panel.visible = false
	_options_panel.modulate.a = 0.0
	_scanline_check.button_pressed = GameState.scanlines_enabled
	_scanline_check.toggled.connect(func(pressed: bool) -> void:
		GameState.set_scanlines_enabled(pressed)
	)


func _toggle_options_panel(open: bool) -> void:
	if _options_tween != null:
		_options_tween.kill()
		_options_tween = null

	if open:
		_options_panel.visible = true
		_options_panel.modulate.a = 0.0
		_options_tween = create_tween()
		_options_tween.set_trans(Tween.TRANS_QUAD)
		_options_tween.set_ease(Tween.EASE_OUT)
		_options_tween.tween_property(_options_panel, "modulate:a", 1.0, 0.16)
		return

	_options_tween = create_tween()
	_options_tween.set_trans(Tween.TRANS_QUAD)
	_options_tween.set_ease(Tween.EASE_OUT)
	_options_tween.tween_property(_options_panel, "modulate:a", 0.0, 0.14)
	_options_tween.finished.connect(func() -> void:
		_options_panel.visible = false
	)


# ── Transitions ──────────────────────────────────────────────────────


func _play_intro() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)


func _on_new_game_pressed() -> void:
	GameState.start_new_game()
	GameManager.go_to_cutscene(IntroCutscene.get_scenes(), &"overworld", &"cutscene_intro")


func _on_continue_pressed() -> void:
	var save_load_menu := preload("res://scripts/ui/save_load_menu.gd").new()
	save_load_menu.load_only = true
	save_load_menu.closed.connect(func() -> void:
		save_load_menu.queue_free()
		_focus_first_available()
	)
	add_child(save_load_menu)


func _on_options_pressed() -> void:
	var settings := SettingsMenu.new()
	settings.closed.connect(func() -> void:
		settings.queue_free()
		_focus_first_available()
	)
	add_child(settings)


func _on_quit_pressed() -> void:
	get_tree().quit()


# ── Input ────────────────────────────────────────────────────────────


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if not vp:
		return

	if event.is_action_pressed("move_down"):
		_focus_next(1)
		vp.set_input_as_handled()
		return
	if event.is_action_pressed("move_up"):
		_focus_next(-1)
		vp.set_input_as_handled()
		return

	if event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button:
			(focused as Button).emit_signal("pressed")
			vp.set_input_as_handled()
