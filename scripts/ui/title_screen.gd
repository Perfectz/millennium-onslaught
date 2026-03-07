## Modern title screen with video reel and glass UI.
extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var _bg: ColorRect = $Background
@onready var _bg_glow: ColorRect = $BackgroundGlow
@onready var _content_margin: MarginContainer = $Content
@onready var _content_split: HBoxContainer = $Content/HBox
@onready var _title_label: Label = $Content/HBox/LeftColumn/BrandBlock/TitleLabel
@onready var _subtitle_label: Label = $Content/HBox/LeftColumn/BrandBlock/SubTitleLabel
@onready var _button_rows: VBoxContainer = $Content/HBox/LeftColumn/ButtonRows
@onready var _video_player: VideoStreamPlayer = $Content/HBox/RightColumn/VideoFrame/KeyArt
@onready var _status_panel: PanelContainer = $Content/HBox/LeftColumn/StatusPanel
@onready var _save_summary_label: Label = $Content/HBox/LeftColumn/StatusPanel/StatusMargin/StatusVBox/SaveSummaryLabel
@onready var _build_summary_label: Label = $Content/HBox/LeftColumn/StatusPanel/StatusMargin/StatusVBox/BuildSummaryLabel
@onready var _status_label: Label = $Content/HBox/LeftColumn/StatusLabel
@onready var _new_game_btn: Button = $Content/HBox/LeftColumn/ButtonRows/NewGameButton
@onready var _continue_btn: Button = $Content/HBox/LeftColumn/ButtonRows/ContinueButton
@onready var _options_btn: Button = $Content/HBox/LeftColumn/ButtonRows/OptionsButton
@onready var _quit_btn: Button = $Content/HBox/LeftColumn/ButtonRows/QuitButton
@onready var _nebula_frame: AspectRatioContainer = $Content/HBox/LeftColumn/NebulaFrame
@onready var _nebula_video: VideoStreamPlayer = $Content/HBox/LeftColumn/NebulaFrame/NebulaVideo
@onready var _right_column: VBoxContainer = $Content/HBox/RightColumn
@onready var _version_label: Label = $VersionLabel

var _video_streams: Array = []
var _current_video_index: int = 0
var _video_crossfade_tween: Tween = null
var _menu_buttons: Array[Button] = []
var _default_status_text: String = ""


func _ready() -> void:
	UIStyleRef.apply_theme(self)
	GameManager.change_phase(GameManager.Phase.MAIN_MENU)
	InputManager.set_context(InputManager.InputContext.MENU)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_background_effects()
	_style_buttons()
	_style_status_panel()
	_bind_buttons()
	_setup_video_reel()
	_setup_nebula_video()
	_refresh_continue_state()
	_setup_controller_navigation()
	_build_screen_fx()
	_refresh_layout()
	get_viewport().size_changed.connect(_refresh_layout)
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
	for btn in [_new_game_btn, _continue_btn, _options_btn, _quit_btn]:
		UIStyleRef.add_press_feedback(btn, 0.975)


func _style_status_panel() -> void:
	var s := UIStyleRef.create_panel_style(
		Color(0.04, 0.07, 0.12, 0.78),
		Color(0.38, 0.74, 0.98, 0.48),
		8
	)
	_status_panel.add_theme_stylebox_override("panel", s)


func _build_screen_fx() -> void:
	var fx := Control.new()
	fx.name = "FXLayer"
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	fx.add_child(UIStyleRef.create_particle_field(get_viewport_rect().size, Color(0.3, 0.6, 1.0, 0.06), 12))
	if GameState.scanlines_enabled:
		fx.add_child(UIStyleRef.create_scanlines(0.02))
	fx.add_child(UIStyleRef.create_vignette(0.42))


# ── Buttons & Navigation ────────────────────────────────────────────


func _bind_buttons() -> void:
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_options_btn.pressed.connect(_on_options_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	# Wire UI sounds to all menu buttons.
	for btn in [_new_game_btn, _continue_btn, _options_btn, _quit_btn]:
		UIStyleRef.wire_button_sounds(btn)
		btn.focus_entered.connect(_preview_button.bind(btn))
		btn.mouse_entered.connect(_preview_button.bind(btn))


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
			_preview_button(button)
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
		_continue_btn.text = "CONTINUE"
		_save_summary_label.text = "%d ACTIVE CAMPAIGN%s" % [save_count, "" if save_count == 1 else "S"]
		_build_summary_label.text = "Resume your latest deployment or open the load menu from Continue."
		_default_status_text = "Options includes audio, display, and remapping controls."
		_status_label.text = _default_status_text
		return

	_continue_btn.disabled = true
	_continue_btn.text = "CONTINUE"
	_save_summary_label.text = "NO CAMPAIGN DATA DETECTED"
	_build_summary_label.text = "Start a new run or configure graphics, audio, and controls from Options."
	_default_status_text = "Keyboard and controller inputs are fully supported."
	_status_label.text = _default_status_text


func _refresh_layout() -> void:
	var size := get_viewport_rect().size
	var compact := size.x < 1360.0 or size.y < 860.0
	_content_margin.add_theme_constant_override("margin_left", int(clampf(size.x * 0.055, 28.0, 88.0)))
	_content_margin.add_theme_constant_override("margin_right", int(clampf(size.x * 0.045, 28.0, 72.0)))
	_content_margin.add_theme_constant_override("margin_top", int(clampf(size.y * 0.06, 28.0, 72.0)))
	_content_margin.add_theme_constant_override("margin_bottom", int(clampf(size.y * 0.05, 24.0, 56.0)))
	_content_split.add_theme_constant_override("separation", 36 if compact else 60)
	_title_label.add_theme_font_size_override("font_size", 56 if compact else 68)
	_subtitle_label.add_theme_font_size_override("font_size", 15 if compact else 17)
	_status_label.add_theme_font_size_override("font_size", 13 if compact else 14)
	_button_rows.custom_minimum_size.x = clampf(size.x * 0.26, 320.0, 408.0)
	_nebula_frame.visible = size.y >= 900.0
	_right_column.visible = size.x >= 1180.0
	_version_label.add_theme_color_override("font_color", Color(0.5, 0.68, 0.86, 0.58))


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
	visible = false
	var save_load_menu := preload("res://scripts/ui/save_load_menu.gd").new()
	save_load_menu.load_only = true
	save_load_menu.closed.connect(func() -> void:
		save_load_menu.queue_free()
		visible = true
		_focus_first_available()
	)
	add_child(save_load_menu)


func _on_options_pressed() -> void:
	visible = false
	var settings := SettingsMenu.new()
	settings.closed.connect(func() -> void:
		settings.queue_free()
		visible = true
		_focus_first_available()
	)
	add_child(settings)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _preview_button(button: Button) -> void:
	if button == null:
		_status_label.text = _default_status_text
		return
	if button == _new_game_btn:
		_status_label.text = "Start a fresh deployment and enter the campaign from the opening sequence."
	elif button == _continue_btn:
		_status_label.text = "Continue is unavailable until at least one save slot exists." \
			if button.disabled else "Open the save list and resume the latest active campaign."
	elif button == _options_btn:
		_status_label.text = "Adjust audio, display, accessibility-adjacent visuals, and control mappings."
	elif button == _quit_btn:
		_status_label.text = "Exit the current session and close the application."
	else:
		_status_label.text = _default_status_text


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
		if focused is Button and not (focused as Button).disabled:
			(focused as Button).emit_signal("pressed")
			vp.set_input_as_handled()
