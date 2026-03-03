## Unified settings screen — Audio, Display, Controls tabs.
## Code-only CanvasLayer, opened from pause menu or title screen.
class_name SettingsMenu
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _overlay: ColorRect
var _card: PanelContainer
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
## Back button.
var _back_btn: Button


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
	root_hbox.add_theme_constant_override("separation", 16)
	margin.add_child(root_hbox)

	# Left sidebar with tab buttons.
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(140, 0)
	sidebar.add_theme_constant_override("separation", 8)
	sidebar.alignment = BoxContainer.ALIGNMENT_BEGIN
	root_hbox.add_child(sidebar)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 2)
	sidebar.add_child(title)
	sidebar.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.25)))

	_audio_tab_btn = _make_tab_button("Audio")
	_audio_tab_btn.pressed.connect(func() -> void: _switch_tab(&"audio"))
	sidebar.add_child(_audio_tab_btn)

	_display_tab_btn = _make_tab_button("Display")
	_display_tab_btn.pressed.connect(func() -> void: _switch_tab(&"display"))
	sidebar.add_child(_display_tab_btn)

	_controls_tab_btn = _make_tab_button("Controls")
	_controls_tab_btn.pressed.connect(func() -> void: _switch_tab(&"controls"))
	sidebar.add_child(_controls_tab_btn)

	sidebar.add_child(Control.new())  # Spacer.

	_back_btn = _make_tab_button("Back")
	UIStyleRef.style_button(_back_btn, Color(0.45, 0.2, 0.25), Color(1.0, 0.7, 0.72), 18)
	_back_btn.pressed.connect(_on_back)
	sidebar.add_child(_back_btn)

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

	# Focus chain.
	var focusables: Array[Control] = [
		_audio_tab_btn, _display_tab_btn, _controls_tab_btn, _back_btn,
	]
	_configure_focus_chain(focusables)

	_switch_tab(&"audio")
	_audio_tab_btn.grab_focus()

	UIStyleRef.play_modal_intro(_overlay, _card)


# --- Tab Switching ---

func _switch_tab(tab: StringName) -> void:
	_audio_panel.visible = (tab == &"audio")
	_display_panel.visible = (tab == &"display")
	_controls_panel.visible = (tab == &"controls")
	# Highlight active tab.
	_set_tab_active(_audio_tab_btn, tab == &"audio")
	_set_tab_active(_display_tab_btn, tab == &"display")
	_set_tab_active(_controls_tab_btn, tab == &"controls")


func _set_tab_active(btn: Button, active: bool) -> void:
	btn.modulate = Color(1.0, 1.0, 1.0) if active else Color(0.6, 0.6, 0.6)


# --- Audio Tab ---

func _build_audio_tab() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var header := Label.new()
	header.text = "Audio"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	vbox.add_child(header)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

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
	_mute_check.focus_mode = Control.FOCUS_ALL
	_mute_check.add_theme_font_size_override("font_size", 17)
	_mute_check.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	vbox.add_child(_mute_check)

	return vbox


# --- Display Tab ---

func _build_display_tab() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	var header := Label.new()
	header.text = "Display"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	vbox.add_child(header)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.focus_mode = Control.FOCUS_ALL
	_fullscreen_check.add_theme_font_size_override("font_size", 20)
	_fullscreen_check.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	vbox.add_child(_fullscreen_check)

	_scanlines_check = CheckBox.new()
	_scanlines_check.text = "Scanline Overlay"
	_scanlines_check.focus_mode = Control.FOCUS_ALL
	_scanlines_check.add_theme_font_size_override("font_size", 20)
	_scanlines_check.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
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
	header.add_theme_font_size_override("font_size", 24)
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

	var remap_btn := Button.new()
	remap_btn.text = "Remap Controls"
	remap_btn.custom_minimum_size = Vector2(280, 52)
	UIStyleRef.style_button(remap_btn, Color(0.2, 0.48, 0.58), Color(0.55, 0.9, 0.95), 20)
	UIStyleRef.wire_button_sounds(remap_btn)
	remap_btn.pressed.connect(_on_open_remap)
	vbox.add_child(remap_btn)

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
	var ctrl_screen := ControllerSettings.new()
	ctrl_screen.closed.connect(func() -> void:
		ctrl_screen.queue_free()
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
	slider.focus_mode = Control.FOCUS_ALL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	UIStyleRef.style_button(btn, Color(0.15, 0.35, 0.55), Color(0.5, 0.78, 1.0), 18)
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
