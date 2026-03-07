## Unified settings screen — Audio, Display, Controls tabs.
## Code-only CanvasLayer, opened from pause menu or title screen.
class_name SettingsMenu
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _overlay: ColorRect
var _card: PanelContainer
var _sidebar: VBoxContainer
var _title_label: Label
## Tab buttons.
var _audio_tab_btn: Button
var _display_tab_btn: Button
var _controls_tab_btn: Button
## Content panels for each tab.
var _audio_panel: VBoxContainer
var _display_panel: VBoxContainer
var _controls_panel: VBoxContainer
## Audio controls.
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _master_value_label: Label
var _music_value_label: Label
var _sfx_value_label: Label
var _mute_check: CheckBox
var _track_selector: OptionButton
var _track_ids: Array[StringName] = []
## Display controls.
var _fullscreen_check: CheckBox
var _scanlines_check: CheckBox
var _remap_btn: Button
## Back button.
var _back_btn: Button
var _active_tab: StringName = &"audio"


func _ready() -> void:
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.08, 0.88)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	UIStyleRef.apply_screen_effects(_overlay, Color(0.3, 0.5, 1.0, 0.08), 12, Color(0.1, 0.3, 0.7))

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -480
	_card.offset_top = -300
	_card.offset_right = 480
	_card.offset_bottom = 300
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.96),
		Color(0.3, 0.55, 0.85, 0.96),
		14
	))
	UIStyleRef.apply_theme(_card)
	_overlay.add_child(_card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_card.add_child(margin)

	var root_hbox := HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 20)
	margin.add_child(root_hbox)

	# Left sidebar with tab buttons.
	_sidebar = VBoxContainer.new()
	_sidebar.custom_minimum_size = Vector2(160, 0)
	_sidebar.add_theme_constant_override("separation", 8)
	_sidebar.alignment = BoxContainer.ALIGNMENT_BEGIN
	root_hbox.add_child(_sidebar)

	_title_label = Label.new()
	_title_label.text = "SETTINGS"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title_label.add_theme_constant_override("outline_size", 2)
	_sidebar.add_child(_title_label)
	_sidebar.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.25)))

	_audio_tab_btn = _make_tab_button("Audio")
	_audio_tab_btn.pressed.connect(func() -> void: _switch_tab(&"audio"))
	_sidebar.add_child(_audio_tab_btn)

	_display_tab_btn = _make_tab_button("Display")
	_display_tab_btn.pressed.connect(func() -> void: _switch_tab(&"display"))
	_sidebar.add_child(_display_tab_btn)

	_controls_tab_btn = _make_tab_button("Controls")
	_controls_tab_btn.pressed.connect(func() -> void: _switch_tab(&"controls"))
	_sidebar.add_child(_controls_tab_btn)

	_sidebar.add_child(Control.new())  # Spacer.

	_back_btn = _make_tab_button("Back")
	UIStyleRef.style_button(_back_btn, Color(0.45, 0.2, 0.25), Color(1.0, 0.7, 0.72), 18)
	UIStyleRef.add_press_feedback(_back_btn, 0.975)
	_back_btn.pressed.connect(_on_back)
	_sidebar.add_child(_back_btn)

	for btn in [_audio_tab_btn, _display_tab_btn, _controls_tab_btn, _back_btn]:
		UIStyleRef.wire_button_sounds(btn)

	# Vertical separator.
	var sep_line := UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2), 0.0)
	sep_line.custom_minimum_size = Vector2(2, 0)
	sep_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sep_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_hbox.add_child(sep_line)

	# Right content area.
	var content := Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(content)

	_audio_panel = _build_audio_tab()
	_audio_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(_audio_panel)

	_display_panel = _build_display_tab()
	_display_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(_display_panel)

	_controls_panel = _build_controls_tab()
	_controls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(_controls_panel)

	_initialize_audio_controls()
	_initialize_display_controls()

	_switch_tab(&"audio")
	_audio_tab_btn.grab_focus()
	call_deferred("_refresh_layout")
	get_viewport().size_changed.connect(_refresh_layout)

	UIStyleRef.play_modal_intro(_overlay, _card)


# --- Tab Switching ---

func _switch_tab(tab: StringName) -> void:
	_active_tab = tab
	_audio_panel.visible = (tab == &"audio")
	_display_panel.visible = (tab == &"display")
	_controls_panel.visible = (tab == &"controls")
	_set_tab_active(_audio_tab_btn, tab == &"audio", _tab_accent(&"audio"))
	_set_tab_active(_display_tab_btn, tab == &"display", _tab_accent(&"display"))
	_set_tab_active(_controls_tab_btn, tab == &"controls", _tab_accent(&"controls"))
	_configure_focus_chain(_focusables_for_tab(tab))


func _set_tab_active(btn: Button, active: bool, accent: Color) -> void:
	UIStyleRef.style_tab_button(btn, accent, active)


func _tab_accent(tab: StringName) -> Color:
	match tab:
		&"display":
			return Color(0.98, 0.78, 0.42)
		&"controls":
			return Color(0.5, 0.9, 0.82)
		_:
			return Color(0.55, 0.84, 1.0)


# --- Audio Tab ---

func _build_audio_tab() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var header := Label.new()
	header.text = "Audio"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	vbox.add_child(header)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

	var intro := Label.new()
	intro.text = "Adjust the live mix, preview the soundtrack, and mute audio globally without leaving the menu."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 15)
	intro.add_theme_color_override("font_color", Color(0.66, 0.8, 0.96))
	vbox.add_child(intro)

	# Track selector.
	var track_row := HBoxContainer.new()
	track_row.add_theme_constant_override("separation", 10)
	var track_label := Label.new()
	track_label.text = "Track"
	track_label.custom_minimum_size = Vector2(80, 0)
	track_label.add_theme_font_size_override("font_size", 17)
	track_label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	_track_selector = OptionButton.new()
	_track_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track_selector.custom_minimum_size = Vector2(0, 40)
	_track_selector.focus_mode = Control.FOCUS_ALL
	UIStyleRef.style_option_button(_track_selector, _tab_accent(&"audio"), 17)
	track_row.add_child(track_label)
	track_row.add_child(_track_selector)
	vbox.add_child(track_row)

	# Volume sliders.
	var master_row := _build_slider_row("Master")
	_master_slider = master_row["slider"] as HSlider
	_master_value_label = master_row["value"] as Label
	vbox.add_child(master_row["row"] as HBoxContainer)

	var music_row := _build_slider_row("Music")
	_music_slider = music_row["slider"] as HSlider
	_music_value_label = music_row["value"] as Label
	vbox.add_child(music_row["row"] as HBoxContainer)

	var sfx_row := _build_slider_row("SFX")
	_sfx_slider = sfx_row["slider"] as HSlider
	_sfx_value_label = sfx_row["value"] as Label
	vbox.add_child(sfx_row["row"] as HBoxContainer)

	_mute_check = CheckBox.new()
	_mute_check.text = "Mute All Audio"
	UIStyleRef.style_check_box(_mute_check, _tab_accent(&"audio"), 17)
	vbox.add_child(_mute_check)

	return vbox


# --- Display Tab ---

func _build_display_tab() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var header := Label.new()
	header.text = "Display"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	vbox.add_child(header)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "Fullscreen"
	UIStyleRef.style_check_box(_fullscreen_check, _tab_accent(&"display"), 19)
	vbox.add_child(_fullscreen_check)

	_scanlines_check = CheckBox.new()
	_scanlines_check.text = "Scanline Overlay"
	UIStyleRef.style_check_box(_scanlines_check, _tab_accent(&"display"), 19)
	vbox.add_child(_scanlines_check)

	var hint := Label.new()
	hint.text = "Changes apply immediately."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.52, 0.72, 0.92))
	vbox.add_child(hint)

	return vbox


# --- Controls Tab ---

func _build_controls_tab() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var header := Label.new()
	header.text = "Controls"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	vbox.add_child(header)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

	# Quick summary of current bindings.
	var summary := Label.new()
	summary.text = "Keyboard: WASD + action keys\nController: Left stick + face buttons"
	summary.add_theme_font_size_override("font_size", 16)
	summary.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(summary)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_remap_btn = Button.new()
	_remap_btn.text = "Remap Controls"
	_remap_btn.custom_minimum_size = Vector2(280, 52)
	UIStyleRef.style_button(_remap_btn, Color(0.2, 0.48, 0.58), Color(0.55, 0.9, 0.95), 20)
	UIStyleRef.add_press_feedback(_remap_btn, 0.975)
	UIStyleRef.wire_button_sounds(_remap_btn)
	_remap_btn.pressed.connect(_on_open_remap)
	vbox.add_child(_remap_btn)

	var hint := Label.new()
	hint.text = "Rebind keyboard keys and controller buttons."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.52, 0.72, 0.92))
	vbox.add_child(hint)

	return vbox


# --- Initialization ---

func _initialize_audio_controls() -> void:
	_populate_track_selector()

	_master_slider.set_block_signals(true)
	_music_slider.set_block_signals(true)
	_sfx_slider.set_block_signals(true)
	_mute_check.set_block_signals(true)

	_master_slider.value = AudioManager.get_master_volume()
	_music_slider.value = AudioManager.get_music_volume()
	_sfx_slider.value = AudioManager.get_sfx_volume()
	_mute_check.button_pressed = AudioManager.is_muted()

	_master_slider.set_block_signals(false)
	_music_slider.set_block_signals(false)
	_sfx_slider.set_block_signals(false)
	_mute_check.set_block_signals(false)

	_update_percent_label(_master_value_label, _master_slider.value)
	_update_percent_label(_music_value_label, _music_slider.value)
	_update_percent_label(_sfx_value_label, _sfx_slider.value)

	_track_selector.item_selected.connect(_on_track_selected)
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_mute_check.toggled.connect(_on_mute_toggled)


func _initialize_display_controls() -> void:
	_fullscreen_check.set_block_signals(true)
	_scanlines_check.set_block_signals(true)
	_fullscreen_check.button_pressed = GameState.fullscreen_enabled
	_scanlines_check.button_pressed = GameState.scanlines_enabled
	_fullscreen_check.set_block_signals(false)
	_scanlines_check.set_block_signals(false)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_scanlines_check.toggled.connect(_on_scanlines_toggled)


func _populate_track_selector() -> void:
	_track_selector.clear()
	_track_ids = AudioManager.get_playlist_track_ids()
	for i in _track_ids.size():
		var track_id := _track_ids[i]
		var display := AudioManager.get_track_display_name(track_id)
		_track_selector.add_item(display, i)
		_track_selector.set_item_metadata(i, track_id)
	var current_id := AudioManager.get_current_track_id()
	if current_id == &"":
		return
	var selected_idx := _track_ids.find(current_id)
	if selected_idx >= 0:
		_track_selector.select(selected_idx)


# --- Callbacks ---

func _on_track_selected(index: int) -> void:
	if index < 0 or index >= _track_ids.size():
		return
	AudioManager.play_track(_track_ids[index], true)


func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)
	_update_percent_label(_master_value_label, value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_update_percent_label(_music_value_label, value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	_update_percent_label(_sfx_value_label, value)


func _on_mute_toggled(is_muted: bool) -> void:
	AudioManager.set_muted(is_muted)


func _on_fullscreen_toggled(enabled: bool) -> void:
	GameState.fullscreen_enabled = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	GameState._save_display_settings()


func _on_scanlines_toggled(enabled: bool) -> void:
	GameState.set_scanlines_enabled(enabled)


func _on_open_remap() -> void:
	visible = false
	var ctrl_screen := ControllerSettings.new()
	ctrl_screen.closed.connect(func() -> void:
		ctrl_screen.queue_free()
		visible = true
		_controls_tab_btn.grab_focus()
	)
	add_child(ctrl_screen)


func _on_back() -> void:
	closed.emit()


# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		_on_back()
	elif event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")


# --- Helpers ---

func _build_slider_row(slider_name: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = slider_name
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyleRef.style_slider(slider, _tab_accent(&"audio"))
	var value := Label.new()
	value.custom_minimum_size = Vector2(64, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	value.text = "100%"
	row.add_child(label)
	row.add_child(slider)
	row.add_child(value)
	return {"row": row, "slider": slider, "value": value}


func _make_tab_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(130, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyleRef.style_tab_button(btn, Color(0.55, 0.84, 1.0), false)
	return btn


func _update_percent_label(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value * 100.0))


func _configure_focus_chain(controls: Array[Control]) -> void:
	for i in controls.size():
		var current := controls[i]
		var next := controls[(i + 1) % controls.size()]
		var prev := controls[(i - 1 + controls.size()) % controls.size()]
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_top = current.get_path_to(prev)


func _focusables_for_tab(tab: StringName) -> Array[Control]:
	var base: Array[Control] = [_audio_tab_btn, _display_tab_btn, _controls_tab_btn]
	match tab:
		&"display":
			base.append_array([_fullscreen_check, _scanlines_check, _back_btn])
		&"controls":
			base.append_array([_remap_btn, _back_btn])
		_:
			base.append_array([_track_selector, _master_slider, _music_slider, _sfx_slider, _mute_check, _back_btn])
	return base


func _refresh_layout() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var viewport_size := vp.get_visible_rect().size
	var width := clampf(viewport_size.x * 0.76, 760.0, 1080.0)
	var height := clampf(viewport_size.y * 0.74, 520.0, 700.0)
	_card.offset_left = -width * 0.5
	_card.offset_top = -height * 0.5
	_card.offset_right = width * 0.5
	_card.offset_bottom = height * 0.5
	_sidebar.custom_minimum_size.x = clampf(width * 0.18, 150.0, 220.0)
	var compact := viewport_size.x < 1280.0 or viewport_size.y < 820.0
	_title_label.add_theme_font_size_override("font_size", 25 if compact else 28)
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.96),
		Color(0.3, 0.55, 0.85, 0.96),
		10 if compact else 14
	))
	_configure_focus_chain(_focusables_for_tab(_active_tab))
