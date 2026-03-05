## Virtual touch controls for mobile — joystick (left) + action buttons (right).
## Injects input via Input.parse_input_event() so existing PlayerController works.
extends CanvasLayer


## Virtual joystick state.
var _joystick_touch_idx: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_knob_pos: Vector2 = Vector2.ZERO

## Button touch tracking — maps touch index to action name.
var _button_touches: Dictionary = {}

## UI element references.
var _joystick_base: Control
var _joystick_knob: Control
var _button_nodes: Dictionary = {}

## Half-size of the joystick for radius calculations.
var _joystick_radius: float = 0.0

## Currently injected axis values to avoid duplicate injection.
var _current_h_axis: float = 0.0
var _current_v_axis: float = 0.0


func _ready() -> void:
	layer = Constants.TOUCH_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	# Hide on desktop / when controller connected.
	visible = InputManager.should_show_touch_controls()
	EventBus.input_touch_visibility_changed.connect(func(show: bool) -> void:
		visible = show
	)


func _build_ui() -> void:
	var screen_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1920),
		ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	)
	var joy_size: float = Constants.TOUCH_JOYSTICK_SIZE
	_joystick_radius = joy_size * 0.5

	# --- Left side: Virtual joystick ---
	_joystick_base = _create_circle(joy_size, Color(0.3, 0.5, 0.8, Constants.TOUCH_OPACITY_IDLE))
	_joystick_base.position = Vector2(80, screen_size.y - joy_size - 80)
	_joystick_center = _joystick_base.position + Vector2(joy_size * 0.5, joy_size * 0.5)
	add_child(_joystick_base)

	var knob_size: float = joy_size * 0.4
	_joystick_knob = _create_circle(knob_size, Color(0.5, 0.7, 1.0, Constants.TOUCH_OPACITY_ACTIVE))
	_joystick_knob.position = Vector2(
		(joy_size - knob_size) * 0.5,
		(joy_size - knob_size) * 0.5
	)
	_joystick_base.add_child(_joystick_knob)

	# --- Right side: Action buttons ---
	var btn_size: float = Constants.TOUCH_BUTTON_SIZE
	var btn_small: float = Constants.TOUCH_BUTTON_SMALL_SIZE
	var right_x: float = screen_size.x - btn_size * 3.5
	var bottom_y: float = screen_size.y - btn_size - 80

	# Primary cluster (diamond layout).
	_add_action_button(&"attack_light", "ATK", btn_size,
		Vector2(right_x, bottom_y),
		Color(0.8, 0.3, 0.3, Constants.TOUCH_OPACITY_IDLE))
	_add_action_button(&"attack_heavy", "HVY", btn_size,
		Vector2(right_x + btn_size * 1.1, bottom_y - btn_size * 0.55),
		Color(0.9, 0.4, 0.2, Constants.TOUCH_OPACITY_IDLE))
	_add_action_button(&"jump", "JMP", btn_size,
		Vector2(right_x + btn_size * 1.1, bottom_y + btn_size * 0.55),
		Color(0.3, 0.7, 0.4, Constants.TOUCH_OPACITY_IDLE))
	_add_action_button(&"dodge", "DDG", btn_size,
		Vector2(right_x + btn_size * 2.2, bottom_y),
		Color(0.3, 0.5, 0.8, Constants.TOUCH_OPACITY_IDLE))

	# Secondary row (above primary).
	_add_action_button(&"heal_spell", "HEAL", btn_small,
		Vector2(right_x, bottom_y - btn_size * 1.4),
		Color(0.3, 0.8, 0.4, Constants.TOUCH_OPACITY_IDLE))
	_add_action_button(&"block", "BLK", btn_small,
		Vector2(right_x + btn_small * 1.2, bottom_y - btn_size * 1.4),
		Color(0.4, 0.6, 0.7, Constants.TOUCH_OPACITY_IDLE))

	# Pause button (top-right corner).
	_add_action_button(&"pause", "II", btn_small,
		Vector2(screen_size.x - btn_small - 20, 20),
		Color(0.5, 0.5, 0.5, Constants.TOUCH_OPACITY_IDLE))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_touch_start(touch.index, touch.position)
		else:
			_on_touch_end(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_on_touch_move(drag.index, drag.position)


func _on_touch_start(idx: int, pos: Vector2) -> void:
	# Check if touching joystick area (left half of screen).
	var screen_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	if pos.x < screen_w * 0.4 and _joystick_touch_idx < 0:
		_joystick_touch_idx = idx
		_joystick_center = pos
		_joystick_base.position = pos - Vector2(_joystick_radius, _joystick_radius)
		_update_joystick(pos)
		_joystick_base.modulate.a = 1.0
		return

	# Check action buttons.
	for action: StringName in _button_nodes:
		var btn: Control = _button_nodes[action]
		var btn_rect := Rect2(btn.global_position, btn.size)
		if btn_rect.has_point(pos):
			_button_touches[idx] = action
			btn.modulate.a = 1.0
			_inject_action_press(action)
			return


func _on_touch_move(idx: int, pos: Vector2) -> void:
	if idx == _joystick_touch_idx:
		_update_joystick(pos)


func _on_touch_end(idx: int) -> void:
	if idx == _joystick_touch_idx:
		_joystick_touch_idx = -1
		_reset_joystick()
		return

	if idx in _button_touches:
		var action: StringName = _button_touches[idx]
		_button_touches.erase(idx)
		if action in _button_nodes:
			(_button_nodes[action] as Control).modulate.a = Constants.TOUCH_OPACITY_IDLE
		_inject_action_release(action)


func _update_joystick(touch_pos: Vector2) -> void:
	var offset := touch_pos - _joystick_center
	var distance := offset.length()
	var clamped := offset
	if distance > _joystick_radius:
		clamped = offset.normalized() * _joystick_radius

	# Update knob visual.
	var knob_size: float = _joystick_knob.size.x
	_joystick_knob.position = Vector2(
		_joystick_radius + clamped.x - knob_size * 0.5,
		_joystick_radius + clamped.y - knob_size * 0.5
	)

	# Calculate normalized axis values.
	var normalized := clamped / _joystick_radius if _joystick_radius > 0 else Vector2.ZERO
	var h: float = normalized.x
	var v: float = normalized.y

	# Apply deadzone.
	var deadzone: float = Constants.TOUCH_JOYSTICK_DEADZONE
	if absf(h) < deadzone:
		h = 0.0
	if absf(v) < deadzone:
		v = 0.0

	# Inject axis changes as action presses/releases.
	_update_axis_injection(h, v)


func _reset_joystick() -> void:
	var joy_size: float = Constants.TOUCH_JOYSTICK_SIZE
	var screen_size_y: float = ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	_joystick_base.position = Vector2(80, screen_size_y - joy_size - 80)
	_joystick_center = _joystick_base.position + Vector2(_joystick_radius, _joystick_radius)
	var knob_size: float = _joystick_knob.size.x
	_joystick_knob.position = Vector2(
		(_joystick_base.size.x - knob_size) * 0.5,
		(_joystick_base.size.y - knob_size) * 0.5
	)
	_joystick_base.modulate.a = Constants.TOUCH_OPACITY_IDLE
	_update_axis_injection(0.0, 0.0)


func _update_axis_injection(h: float, v: float) -> void:
	# Horizontal: move_left / move_right.
	if signf(h) != signf(_current_h_axis) or (h == 0.0) != (_current_h_axis == 0.0):
		# Release old direction.
		if _current_h_axis < 0.0:
			_inject_action_release(&"move_left")
		elif _current_h_axis > 0.0:
			_inject_action_release(&"move_right")
	if h < 0.0:
		_inject_action_strength(&"move_left", absf(h))
	elif h > 0.0:
		_inject_action_strength(&"move_right", absf(h))
	elif _current_h_axis != 0.0:
		_inject_action_release(&"move_left")
		_inject_action_release(&"move_right")
	_current_h_axis = h

	# Vertical: move_up / move_down (screen Y+ = down = move_down).
	if signf(v) != signf(_current_v_axis) or (v == 0.0) != (_current_v_axis == 0.0):
		if _current_v_axis < 0.0:
			_inject_action_release(&"move_up")
		elif _current_v_axis > 0.0:
			_inject_action_release(&"move_down")
	if v < 0.0:
		_inject_action_strength(&"move_up", absf(v))
	elif v > 0.0:
		_inject_action_strength(&"move_down", absf(v))
	elif _current_v_axis != 0.0:
		_inject_action_release(&"move_up")
		_inject_action_release(&"move_down")
	_current_v_axis = v


## Inject a synthetic action press into the global Input system.
func _inject_action_press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)


## Inject a synthetic action release into the global Input system.
func _inject_action_release(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	ev.strength = 0.0
	Input.parse_input_event(ev)


## Inject a synthetic action press with variable strength (for analog joystick).
func _inject_action_strength(action: StringName, strength: float) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = strength > 0.0
	ev.strength = strength
	Input.parse_input_event(ev)


## Create a circular control (used for joystick base and knob).
func _create_circle(diameter: float, color: Color) -> Control:
	var ctrl := Control.new()
	ctrl.custom_minimum_size = Vector2(diameter, diameter)
	ctrl.size = Vector2(diameter, diameter)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(bg)
	return ctrl


## Add an action button to the right-side cluster.
func _add_action_button(action: StringName, label_text: String, btn_size: float, pos: Vector2, color: Color) -> void:
	var btn := Control.new()
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.size = Vector2(btn_size, btn_size)
	btn.position = pos
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bg)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", int(btn_size * 0.28))
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	add_child(btn)
	_button_nodes[action] = btn
