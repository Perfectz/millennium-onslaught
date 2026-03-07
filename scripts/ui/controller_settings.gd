## Control remapping screen — shows keyboard + joypad bindings and lets the user reassign them.
## Code-only CanvasLayer, opened from the settings menu or pause menu.
class_name ControllerSettings
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")
const MENU_CONFIRM_ACTIONS: Array[StringName] = [&"attack_light", &"jump", &"ui_accept"]
const MENU_BACK_ACTIONS: Array[StringName] = [&"pause", &"dodge", &"ui_cancel"]

var _overlay: ColorRect
var _card: PanelContainer
## Per-action row data: {key_label, joy_label, key_btn, joy_btn}
var _rows: Dictionary = {}
var _back_btn: Button
var _reset_kb_btn: Button
var _reset_joy_btn: Button
## Listening state: &"" = idle, &"keyboard" = waiting for key, &"joypad" = waiting for button.
var _listening_mode: StringName = &""
var _listening_action: StringName = &""
var _listening_label: Label = null


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.08, 0.88)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	UIStyleRef.apply_screen_effects(_overlay, Color(0.3, 0.5, 1.0, 0.08), 12, Color(0.1, 0.3, 0.7))

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -530
	_card.offset_top = -340
	_card.offset_right = 530
	_card.offset_bottom = 340
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.96),
		Color(0.3, 0.55, 0.85, 0.96),
		14
	))
	UIStyleRef.apply_theme(_card)
	_overlay.add_child(_card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_card.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# Header.
	var title := Label.new()
	title.text = "CONTROL SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 2)
	root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Click Remap then press the key or button you want to assign"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	root_vbox.add_child(subtitle)

	root_vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.25)))

	# Column headers.
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(header_row)
	_add_header_label(header_row, "Action", 170)
	_add_header_label(header_row, "Keyboard", 130)
	_add_header_label(header_row, "", 100)  # Remap Key button column
	_add_header_label(header_row, "Controller", 160)
	_add_header_label(header_row, "", 100)  # Remap Joy button column

	# Scrollable binding list.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(list_vbox)

	# Build a row for each remappable action.
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		var row := _build_binding_row(action)
		list_vbox.add_child(row["container"] as Control)
		_rows[action] = row

	root_vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.2)))

	# Footer buttons.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(footer)

	_reset_kb_btn = _make_button("Reset Keys", Color(0.5, 0.35, 0.2), Color(1.0, 0.8, 0.5))
	_reset_kb_btn.pressed.connect(_on_reset_keyboard)
	footer.add_child(_reset_kb_btn)

	_reset_joy_btn = _make_button("Reset Pad", Color(0.5, 0.35, 0.2), Color(1.0, 0.8, 0.5))
	_reset_joy_btn.pressed.connect(_on_reset_controller)
	footer.add_child(_reset_joy_btn)

	_back_btn = _make_button("Back", Color(0.18, 0.42, 0.7), Color(0.7, 0.88, 1.0))
	_back_btn.pressed.connect(_on_back)
	footer.add_child(_back_btn)

	for btn in [_reset_kb_btn, _reset_joy_btn, _back_btn]:
		UIStyleRef.wire_button_sounds(btn)

	# Focus chain: key remap buttons, then joy remap buttons, then footer.
	var focusables: Array[Control] = []
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		focusables.append(_rows[action]["key_btn"] as Button)
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		focusables.append(_rows[action]["joy_btn"] as Button)
	focusables.append(_reset_kb_btn)
	focusables.append(_reset_joy_btn)
	focusables.append(_back_btn)
	_configure_focus_chain(focusables)

	var first_btn: Button = null
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		first_btn = _rows[action]["key_btn"] as Button
		break
	if first_btn:
		first_btn.grab_focus()

	UIStyleRef.play_modal_intro(_overlay, _card)


## Build one row: [Action] [Key Binding] [Remap Key] [Joy Binding] [Remap Joy].
func _build_binding_row(action: StringName) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Action name.
	var name_label := Label.new()
	name_label.text = InputManager.ACTION_DISPLAY_NAMES.get(action, str(action))
	name_label.custom_minimum_size = Vector2(170, 0)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	hbox.add_child(name_label)

	# Keyboard binding label.
	var key_label := Label.new()
	key_label.custom_minimum_size = Vector2(130, 0)
	key_label.add_theme_font_size_override("font_size", 18)
	_update_key_label(key_label, action)
	hbox.add_child(key_label)

	# Remap Key button.
	var key_btn := _make_button("Remap", Color(0.25, 0.4, 0.55), Color(0.6, 0.85, 1.0))
	key_btn.custom_minimum_size = Vector2(100, 38)
	key_btn.pressed.connect(func() -> void: _start_listening(action, key_label, &"keyboard"))
	UIStyleRef.wire_button_sounds(key_btn)
	hbox.add_child(key_btn)

	# Joypad binding label.
	var joy_label := Label.new()
	joy_label.custom_minimum_size = Vector2(160, 0)
	joy_label.add_theme_font_size_override("font_size", 18)
	_update_joy_label(joy_label, action)
	hbox.add_child(joy_label)

	# Remap Joy button.
	var joy_btn := _make_button("Remap", Color(0.25, 0.4, 0.55), Color(0.6, 0.85, 1.0))
	joy_btn.custom_minimum_size = Vector2(100, 38)
	joy_btn.pressed.connect(func() -> void: _start_listening(action, joy_label, &"joypad"))
	UIStyleRef.wire_button_sounds(joy_btn)
	hbox.add_child(joy_btn)

	return {"container": hbox, "key_label": key_label, "joy_label": joy_label, "key_btn": key_btn, "joy_btn": joy_btn}


func _update_key_label(label: Label, action: StringName) -> void:
	var keycode: int = InputManager.get_keyboard_key_for_action(action)
	if keycode > 0:
		label.text = InputManager.get_key_display_name(keycode)
		label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	else:
		label.text = "Not Bound"
		label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))


func _update_joy_label(label: Label, action: StringName) -> void:
	var btn_idx := InputManager.get_joypad_button_for_action(action)
	if btn_idx >= 0:
		label.text = InputManager.get_button_display_name(btn_idx)
		label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	else:
		label.text = "Not Bound"
		label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))


func _start_listening(action: StringName, label: Label, mode: StringName) -> void:
	_listening_mode = mode
	_listening_action = action
	_listening_label = label
	if mode == &"keyboard":
		label.text = "Press key..."
	else:
		label.text = "Press button..."
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))


func _input(event: InputEvent) -> void:
	if _listening_mode == &"":
		return
	if event.is_echo():
		return

	if _listening_mode == &"keyboard":
		if event is InputEventKey and event.is_pressed():
			var key_event := event as InputEventKey
			# Escape cancels listening.
			if key_event.keycode == KEY_ESCAPE:
				_cancel_listening()
				get_viewport().set_input_as_handled()
				return
			# Reject modifier-only keys.
			if key_event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
				return
			InputManager.remap_action_keyboard(_listening_action, key_event.keycode)
			InputManager.save_keyboard_bindings()
			_update_key_label(_listening_label, _listening_action)
			_refresh_all_labels()
			_finish_listening()
			get_viewport().set_input_as_handled()

	elif _listening_mode == &"joypad":
		if event is InputEventJoypadButton and event.is_pressed():
			var joy_event := event as InputEventJoypadButton
			InputManager.remap_action_joypad(_listening_action, joy_event.button_index)
			InputManager.save_controller_bindings()
			_update_joy_label(_listening_label, _listening_action)
			_refresh_all_labels()
			_finish_listening()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.is_pressed():
			# Cancel joypad listening on keyboard press.
			_cancel_listening()


func _cancel_listening() -> void:
	if _listening_label and _listening_action != &"":
		if _listening_mode == &"keyboard":
			_update_key_label(_listening_label, _listening_action)
		else:
			_update_joy_label(_listening_label, _listening_action)
	_finish_listening()


func _finish_listening() -> void:
	_listening_mode = &""
	_listening_action = &""
	_listening_label = null


func _refresh_all_labels() -> void:
	for action: StringName in _rows:
		var row: Dictionary = _rows[action]
		_update_key_label(row["key_label"] as Label, action)
		_update_joy_label(row["joy_label"] as Label, action)


func _on_reset_keyboard() -> void:
	InputManager.reset_keyboard_defaults()
	_refresh_all_labels()
	if ToastSystem:
		ToastSystem.show_toast("Keyboard reset to defaults", Color(0.5, 0.85, 1.0))
	UIStyleRef.punch(_reset_kb_btn, 0.04)


func _on_reset_controller() -> void:
	InputManager.reset_controller_defaults()
	_refresh_all_labels()
	if ToastSystem:
		ToastSystem.show_toast("Controller reset to defaults", Color(0.5, 0.85, 1.0))
	UIStyleRef.punch(_reset_joy_btn, 0.04)


func _on_back() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _listening_mode != &"":
		return
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if _event_matches_any_action(event, MENU_BACK_ACTIONS):
		vp.set_input_as_handled()
		_on_back()
	elif _event_matches_any_action(event, MENU_CONFIRM_ACTIONS):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")


func _make_button(text: String, base_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 40)
	UIStyleRef.style_button(btn, base_color, border_color, 17)
	return btn


func _add_header_label(parent: HBoxContainer, text: String, min_width: float) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(min_width, 0)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.6, 0.8))
	parent.add_child(lbl)


func _configure_focus_chain(controls: Array[Control]) -> void:
	for i in controls.size():
		var current := controls[i]
		var next := controls[(i + 1) % controls.size()]
		var prev := controls[(i - 1 + controls.size()) % controls.size()]
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_top = current.get_path_to(prev)


func _event_matches_any_action(event: InputEvent, actions: Array[StringName]) -> bool:
	for action: StringName in actions:
		if event.is_action_pressed(action):
			return true
	return false
