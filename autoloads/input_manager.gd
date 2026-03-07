## Device-to-player mapping, per-player input routing, context switching, controller remapping.
## Uses DeviceInputTracker for per-player state so multiple controllers work.
class_name InputManagerSingleton
extends Node


## Input contexts determine what buttons do in each game phase.
enum InputContext {
	COMBAT,
	MENU,
	OVERWORLD,
	DIALOGUE,
}

## Device-to-player mapping. Key: device_id, Value: player_index.
var _device_to_player: Dictionary = {}

## Current input context.
var _current_context: InputContext = InputContext.MENU

## Maximum players supported.
const MAX_PLAYERS: int = 4

## Per-player input state tracker (DeviceInputTracker — pure logic, TDD-tested).
var _tracker: DeviceInputTracker = DeviceInputTracker.new(MAX_PLAYERS)

## Actions that we route through the tracker (populated from InputMap).
var _tracked_actions: Array[StringName] = []

## Cached joypad motion bindings keyed by axis index.
var _joypad_motion_bindings: Dictionary = {}

## Single-player fallback consume state for polled just_pressed queries.
var _polled_just_pressed_consumed: Array[Dictionary] = []

## Stable source id range reserved for virtual touch controls.
const TOUCH_SOURCE_BASE: int = 10_000

## Path for saved controller bindings.
const CONTROLLER_BINDINGS_PATH: String = "user://controller_bindings.cfg"
const CONTROLLER_BINDINGS_VERSION: int = 2

## Actions that can be remapped (button-based, not axis-movement).
const REMAPPABLE_ACTIONS: Array[StringName] = [
	&"jump", &"attack_light", &"attack_heavy", &"dodge",
	&"block", &"technique", &"heal_spell", &"camera_reset",
	&"lock_on", &"pause", &"character_prev", &"character_next", &"technique_cycle",
]

## Human-readable labels for remappable actions.
const ACTION_DISPLAY_NAMES: Dictionary = {
	&"jump": "Jump",
	&"attack_light": "Light Attack",
	&"attack_heavy": "Heavy Attack",
	&"dodge": "Dodge",
	&"block": "Block / Parry",
	&"technique": "Technique",
	&"heal_spell": "Heal Spell",
	&"camera_reset": "Reset Camera",
	&"lock_on": "Lock-On",
	&"pause": "Pause",
	&"character_prev": "Prev Character",
	&"character_next": "Next Character",
	&"technique_cycle": "Cycle Technique",
}

## Default joypad button index for each remappable action (SDL standard).
const DEFAULT_JOYPAD_BUTTONS: Dictionary = {
	&"jump": JOY_BUTTON_A,
	&"attack_light": JOY_BUTTON_X,
	&"attack_heavy": JOY_BUTTON_Y,
	&"dodge": JOY_BUTTON_B,
	&"block": JOY_BUTTON_LEFT_SHOULDER,
	&"technique": JOY_BUTTON_RIGHT_SHOULDER,
	&"heal_spell": JOY_BUTTON_DPAD_UP,
	&"camera_reset": JOY_BUTTON_LEFT_STICK,
	&"lock_on": JOY_BUTTON_RIGHT_STICK,
	&"pause": JOY_BUTTON_START,
	&"character_prev": JOY_BUTTON_DPAD_LEFT,
	&"character_next": JOY_BUTTON_DPAD_RIGHT,
	&"technique_cycle": JOY_BUTTON_DPAD_DOWN,
}

## Default keyboard key for each remappable action.
const DEFAULT_KEYBOARD_KEYS: Dictionary = {
	&"jump": KEY_SPACE,
	&"attack_light": KEY_J,
	&"attack_heavy": KEY_K,
	&"dodge": KEY_L,
	&"block": KEY_I,
	&"technique": KEY_U,
	&"heal_spell": KEY_1,
	&"camera_reset": KEY_C,
	&"lock_on": KEY_TAB,
	&"pause": KEY_ESCAPE,
	&"character_prev": KEY_Q,
	&"character_next": KEY_E,
	&"technique_cycle": KEY_O,
}

## Default keyboard keys for non-remappable debug/photo actions.
const AUXILIARY_KEYBOARD_KEYS: Dictionary = {
	&"debug_toggle_ai": KEY_F3,
	&"debug_toggle_perf": KEY_F4,
	&"debug_toggle_input": KEY_F5,
	&"debug_toggle_events": KEY_F6,
	&"debug_restart_dungeon": KEY_F7,
	&"photo_toggle": KEY_F8,
	&"debug_capture_bundle": KEY_F9,
	&"debug_validate_stage": KEY_F10,
	&"photo_move_forward": KEY_W,
	&"photo_move_backward": KEY_S,
	&"photo_move_left": KEY_A,
	&"photo_move_right": KEY_D,
	&"photo_move_up": KEY_E,
	&"photo_move_down": KEY_Q,
	&"photo_speed_modifier": KEY_SHIFT,
	&"photo_roll_left": KEY_Z,
	&"photo_roll_right": KEY_X,
	&"photo_roll_reset": KEY_R,
}

## Per-action deadzones for auxiliary actions created at runtime.
const AUXILIARY_ACTION_DEADZONES: Dictionary = {
	&"debug_toggle_ai": 0.2,
	&"debug_toggle_perf": 0.2,
	&"debug_toggle_input": 0.2,
	&"debug_toggle_events": 0.2,
	&"debug_restart_dungeon": 0.2,
	&"photo_toggle": 0.2,
	&"debug_capture_bundle": 0.2,
	&"debug_validate_stage": 0.2,
	&"photo_move_forward": 0.2,
	&"photo_move_backward": 0.2,
	&"photo_move_left": 0.2,
	&"photo_move_right": 0.2,
	&"photo_move_up": 0.2,
	&"photo_move_down": 0.2,
	&"photo_speed_modifier": 0.2,
	&"photo_roll_left": 0.2,
	&"photo_roll_right": 0.2,
	&"photo_roll_reset": 0.2,
}

## Default joypad axes for actions that are analog-only by design.
const DEFAULT_JOYPAD_AXES: Dictionary = {
	&"move_left": {"axis": JOY_AXIS_LEFT_X, "axis_value": -1.0},
	&"move_right": {"axis": JOY_AXIS_LEFT_X, "axis_value": 1.0},
	&"move_up": {"axis": JOY_AXIS_LEFT_Y, "axis_value": -1.0},
	&"move_down": {"axis": JOY_AXIS_LEFT_Y, "axis_value": 1.0},
	&"projectile_attack": {"axis": JOY_AXIS_TRIGGER_RIGHT, "axis_value": 1.0},
	&"aoe_spell": {"axis": JOY_AXIS_TRIGGER_LEFT, "axis_value": 1.0},
	&"camera_look_left": {"axis": JOY_AXIS_RIGHT_X, "axis_value": -1.0},
	&"camera_look_right": {"axis": JOY_AXIS_RIGHT_X, "axis_value": 1.0},
	&"camera_look_up": {"axis": JOY_AXIS_RIGHT_Y, "axis_value": -1.0},
	&"camera_look_down": {"axis": JOY_AXIS_RIGHT_Y, "axis_value": 1.0},
}

## Joypad button index names for display.
const JOYPAD_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A / Cross",
	JOY_BUTTON_B: "B / Circle",
	JOY_BUTTON_X: "X / Square",
	JOY_BUTTON_Y: "Y / Triangle",
	JOY_BUTTON_BACK: "Back / Select",
	JOY_BUTTON_GUIDE: "Guide / PS",
	JOY_BUTTON_START: "Start / Options",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB / L1",
	JOY_BUTTON_RIGHT_SHOULDER: "RB / R1",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

## Last routed input event, used by debug overlays and capture tools.
var _last_input_state: Dictionary = {
	"device": -1,
	"player": -1,
	"name": "Keyboard / Mouse",
	"action": "",
	"state": "idle",
	"value": 0.0,
	"blocked": false,
	"context": "menu",
	"timestamp_msec": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Run _process LAST so end_frame() clears flags after all consumers.
	# Godot main loop: _input → _physics_process → _process.
	# Without high priority, autoload _process would run BEFORE scene nodes,
	# clearing just_pressed flags before PlayerController can consume them.
	process_priority = 1000
	# Player 0 defaults to keyboard (device -1 in Godot represents keyboard).
	_device_to_player[-1] = 0
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_ensure_auxiliary_actions()
	_ensure_ui_joypad_mappings()
	_ensure_default_button_bindings()
	_ensure_default_axis_bindings()
	_rebuild_input_cache()
	# Map any joypads already connected at startup.
	_scan_connected_joypads()
	# Apply saved bindings (if any).
	load_controller_bindings()
	load_keyboard_bindings()
	_rebuild_input_cache()
	_init_polled_fallback_cache()


## Ensure Godot's built-in ui_accept and ui_cancel have joypad button mappings.
## Without this, controller users can't confirm/cancel in native Godot UI elements.
func _ensure_ui_joypad_mappings() -> void:
	_ensure_joypad_button(&"ui_accept", JOY_BUTTON_A)
	_ensure_joypad_button(&"ui_cancel", JOY_BUTTON_B)
	_ensure_joypad_button(&"ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_joypad_button(&"ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_joypad_button(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_joypad_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT)


## Ensure non-remappable debug/photo actions exist and keep their default keyboard bindings.
func _ensure_auxiliary_actions() -> void:
	for action: StringName in AUXILIARY_KEYBOARD_KEYS:
		_ensure_action_exists(action, AUXILIARY_ACTION_DEADZONES.get(action, 0.2))
		_ensure_keyboard_key(action, AUXILIARY_KEYBOARD_KEYS[action])


## Ensure all gameplay button actions have a usable keyboard + controller default.
func _ensure_default_button_bindings() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if DEFAULT_KEYBOARD_KEYS.has(action):
			_ensure_keyboard_key(action, DEFAULT_KEYBOARD_KEYS[action])
		if DEFAULT_JOYPAD_BUTTONS.has(action):
			_ensure_joypad_button(action, DEFAULT_JOYPAD_BUTTONS[action])


## Ensure analog-only actions keep their expected default axis mapping.
func _ensure_default_axis_bindings() -> void:
	for action: StringName in DEFAULT_JOYPAD_AXES:
		var axis_info: Dictionary = DEFAULT_JOYPAD_AXES[action]
		_ensure_joypad_motion(action, axis_info.get("axis", 0), axis_info.get("axis_value", 1.0))


## Add a joypad button to an action if no joypad button event exists yet.
func _ensure_joypad_button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return  # Already has a joypad button mapping.
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = button
	joy_event.device = -1
	InputMap.action_add_event(action, joy_event)


## Create an action when it is missing so runtime-only helpers can still use InputMap.
func _ensure_action_exists(action: StringName, deadzone: float = 0.2) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, deadzone)


## Add a keyboard key to an action if no keyboard event exists yet.
func _ensure_keyboard_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.device = -1
	InputMap.action_add_event(action, key_event)


## Add a joypad motion binding if the action has no equivalent axis mapping yet.
func _ensure_joypad_motion(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(signf(motion.axis_value), signf(axis_value)):
				return
	var motion_event := InputEventJoypadMotion.new()
	motion_event.axis = axis
	motion_event.axis_value = axis_value
	motion_event.device = -1
	InputMap.action_add_event(action, motion_event)


## Cache all action names from the InputMap.
func _populate_tracked_actions() -> void:
	_tracked_actions.clear()
	for action: StringName in InputMap.get_actions():
		# Skip built-in Godot UI actions (ui_*).
		if not action.begins_with("ui_"):
			_tracked_actions.append(action)


func _rebuild_joypad_motion_bindings() -> void:
	_joypad_motion_bindings.clear()
	for action: StringName in _tracked_actions:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				var motion := event as InputEventJoypadMotion
				if motion.axis not in _joypad_motion_bindings:
					_joypad_motion_bindings[motion.axis] = []
				(_joypad_motion_bindings[motion.axis] as Array).append({
					"action": action,
					"direction": signf(motion.axis_value),
				})


func _rebuild_input_cache() -> void:
	_populate_tracked_actions()
	_rebuild_joypad_motion_bindings()


func _init_polled_fallback_cache() -> void:
	_polled_just_pressed_consumed.clear()
	for i in MAX_PLAYERS:
		_polled_just_pressed_consumed.append({})


func _clear_polled_fallback_cache() -> void:
	var cache_count := mini(MAX_PLAYERS, _polled_just_pressed_consumed.size())
	for i in cache_count:
		_polled_just_pressed_consumed[i].clear()


func _supports_live_player_queries() -> bool:
	return _current_context == InputContext.COMBAT or _current_context == InputContext.OVERWORLD


func _is_action_tracked(action: StringName) -> bool:
	return _tracked_actions.has(action)


func _should_use_polled_fallback_for_action(player_idx: int, action: StringName) -> bool:
	return player_idx == 0 and _supports_live_player_queries() and InputMap.has_action(action)


func _should_use_polled_fallback_for_axis(player_idx: int, negative_action: StringName, positive_action: StringName) -> bool:
	return player_idx == 0 \
		and _supports_live_player_queries() \
		and InputMap.has_action(negative_action) \
		and InputMap.has_action(positive_action)


func _get_touch_source_id(player_idx: int) -> int:
	return TOUCH_SOURCE_BASE + player_idx


func _get_device_display_name(device_id: int) -> String:
	if device_id == -1:
		return "Keyboard / Mouse"
	var joy_name := Input.get_joy_name(device_id)
	return joy_name if joy_name != "" else "Controller %d" % device_id


func _record_input_debug(
	device_id: int,
	player_idx: int,
	action: StringName,
	state: StringName,
	value: float = 0.0,
	blocked: bool = false
) -> void:
	_last_input_state = {
		"device": device_id,
		"player": player_idx,
		"name": _get_device_display_name(device_id),
		"action": String(action),
		"state": String(state),
		"value": snappedf(value, 0.01),
		"blocked": blocked,
		"context": String(get_context_name()),
		"timestamp_msec": Time.get_ticks_msec(),
	}


func _record_context_debug() -> void:
	_last_input_state = {
		"device": -1,
		"player": -1,
		"name": "Context",
		"action": "",
		"state": "context_changed",
		"value": 0.0,
		"blocked": false,
		"context": String(get_context_name()),
		"timestamp_msec": Time.get_ticks_msec(),
	}


func _clear_context_input_state() -> void:
	_tracker.clear_all_state()
	_clear_polled_fallback_cache()


func _normalize_axis_strength(raw_value: float, deadzone: float) -> float:
	if raw_value <= deadzone:
		return 0.0
	if deadzone >= 0.999:
		return 1.0
	return clampf((raw_value - deadzone) / (1.0 - deadzone), 0.0, 1.0)


func _resolve_player_for_input_event(event: InputEvent, device_id: int) -> int:
	var player_idx: int = _device_to_player.get(device_id, -1)
	if player_idx >= 0:
		return player_idx
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_on_joy_connection_changed(device_id, true)
		return _device_to_player.get(device_id, -1)
	return -1


## Route each InputEvent to the correct player's tracker state.
func _input(event: InputEvent) -> void:
	var device_id: int = event.device
	# Keyboard events come through as device 0 but InputMap treats them as -1.
	if event is InputEventKey or event is InputEventMouseButton:
		device_id = -1

	var player_idx := _resolve_player_for_input_event(event, device_id)
	if player_idx < 0:
		return

	if not _supports_live_player_queries():
		return

	if event is InputEventJoypadMotion:
		_route_joypad_motion(player_idx, event as InputEventJoypadMotion, device_id)
		return

	for action: StringName in _tracked_actions:
		if event.is_action_pressed(action):
			_tracker.register_action_pressed(player_idx, action, device_id)
			_record_input_debug(device_id, player_idx, action, &"pressed")
		elif event.is_action_released(action):
			_tracker.register_action_released(player_idx, action, device_id)
			_record_input_debug(device_id, player_idx, action, &"released")


## Route a joypad axis update to every action bound on that axis.
## This keeps opposing directions in sync and clears stale values when the stick recenters.
func _route_joypad_motion(player_idx: int, motion: InputEventJoypadMotion, device_id: int) -> void:
	var bindings: Array = _joypad_motion_bindings.get(motion.axis, [])
	if bindings.is_empty():
		return
	var strongest_action: StringName = &""
	var strongest_value := 0.0
	for binding: Dictionary in bindings:
		var action: StringName = binding.get("action", &"")
		if action == &"":
			continue
		var expected_direction: float = binding.get("direction", 0.0)
		var strength := 0.0
		var deadzone := InputMap.action_get_deadzone(action)
		if expected_direction != 0.0 and signf(motion.axis_value) == expected_direction:
			strength = _normalize_axis_strength(absf(motion.axis_value), deadzone)
		_tracker.register_axis_value(player_idx, action, strength, device_id)
		if strength > 0.0:
			_tracker.register_action_pressed(player_idx, action, device_id)
			if strength >= strongest_value:
				strongest_action = action
				strongest_value = strength
		else:
			_tracker.register_action_released(player_idx, action, device_id)
	if strongest_action != &"":
		_record_input_debug(device_id, player_idx, strongest_action, &"axis", strongest_value)
	elif not bindings.is_empty():
		var idle_action: StringName = (bindings[0] as Dictionary).get("action", &"")
		if idle_action != &"":
			_record_input_debug(device_id, player_idx, idle_action, &"axis_idle")


## Clear just_pressed flags at end of each frame.
## Runs in _process (not _physics_process) with process_priority=1000
## so it executes AFTER all scene nodes have consumed their flags.
## Godot main loop order: _input → _physics_process → _process.
## If we cleared in _physics_process, autoloads run first and would
## wipe flags before PlayerController can read them.
func _process(_delta: float) -> void:
	_tracker.end_frame()
	_clear_polled_fallback_cache()


# --- Per-Player Query API (replaces global Input.xxx() calls) ---


## Check if an action is currently held for a specific player.
func is_action_pressed_for_player(player_idx: int, action: StringName) -> bool:
	if not _supports_live_player_queries():
		return false
	if _tracker.is_pressed(player_idx, action):
		return true
	if _should_use_polled_fallback_for_action(player_idx, action):
		return Input.is_action_pressed(action)
	return false


## Consume a just_pressed event for a specific player (one-shot).
func is_action_just_pressed_for_player(player_idx: int, action: StringName) -> bool:
	if not _supports_live_player_queries():
		return false
	if _tracker.consume_just_pressed(player_idx, action):
		if player_idx >= 0 and player_idx < _polled_just_pressed_consumed.size():
			_polled_just_pressed_consumed[player_idx][action] = true
		return true
	if not _should_use_polled_fallback_for_action(player_idx, action):
		return false
	if not Input.is_action_just_pressed(action):
		return false
	var consumed := _polled_just_pressed_consumed[player_idx]
	if consumed.get(action, false):
		return false
	consumed[action] = true
	return true


## Get axis value for a specific player (negative_action vs positive_action).
func get_axis_for_player(player_idx: int, negative_action: StringName, positive_action: StringName) -> float:
	if not _supports_live_player_queries():
		return 0.0
	var tracker_axis := _tracker.get_axis(player_idx, negative_action, positive_action)
	if not is_zero_approx(tracker_axis):
		return tracker_axis
	if _should_use_polled_fallback_for_axis(player_idx, negative_action, positive_action):
		return Input.get_axis(negative_action, positive_action)
	return tracker_axis


# --- Touch Injection (for mobile virtual controls) ---


## Inject a touch press as if it came from a virtual device for the given player.
func inject_touch_action_pressed(player_idx: int, action: StringName) -> void:
	if not _supports_live_player_queries():
		return
	_tracker.register_action_pressed(player_idx, action, _get_touch_source_id(player_idx))


## Inject a touch release for the given player.
func inject_touch_action_released(player_idx: int, action: StringName) -> void:
	if not _supports_live_player_queries():
		return
	_tracker.register_action_released(player_idx, action, _get_touch_source_id(player_idx))


## Inject a touch axis value for the given player.
func inject_touch_axis(player_idx: int, action: StringName, value: float) -> void:
	if not _supports_live_player_queries():
		return
	_tracker.register_axis_value(player_idx, action, value, _get_touch_source_id(player_idx))


# --- Context Switching ---


## Switch the active input context.
func set_context(context: InputContext) -> void:
	if _current_context == context:
		return
	_current_context = context
	if context == InputContext.COMBAT or context == InputContext.OVERWORLD:
		_scan_connected_joypads()
	_clear_context_input_state()
	_record_context_debug()
	var context_names: Dictionary = {
		InputContext.COMBAT: &"combat",
		InputContext.MENU: &"menu",
		InputContext.OVERWORLD: &"overworld",
		InputContext.DIALOGUE: &"dialogue",
	}
	EventBus.emit_checked(&"input_context_changed", [context_names[context]], {
		"new_context": context_names[context],
	}, true)


## Get the current input context.
func get_context() -> InputContext:
	return _current_context


## Get the active input context as a stable debug-friendly label.
func get_context_name() -> StringName:
	match _current_context:
		InputContext.COMBAT:
			return &"combat"
		InputContext.MENU:
			return &"menu"
		InputContext.OVERWORLD:
			return &"overworld"
		InputContext.DIALOGUE:
			return &"dialogue"
	return &"unknown"


# --- Device Management ---


## Get the player index for a given device.
func get_player_for_device(device_id: int) -> int:
	return _device_to_player.get(device_id, -1)


## Assign a device to a player index.
func assign_device_to_player(device_id: int, player_index: int) -> void:
	var previous_player: int = _device_to_player.get(device_id, -1)
	if previous_player == player_index:
		return
	if previous_player >= 0:
		_tracker.clear_device_state(previous_player, device_id)
	if player_index < 0 or player_index >= MAX_PLAYERS:
		_device_to_player.erase(device_id)
		return
	_device_to_player[device_id] = player_index


## Get number of connected players.
func get_connected_player_count() -> int:
	var unique_players: Array = []
	for player_idx: int in _device_to_player.values():
		if player_idx not in unique_players:
			unique_players.append(player_idx)
	return unique_players.size()


## Snapshot live device mappings, pressed actions, and analog values for debug overlays.
func get_debug_snapshot(max_players_to_report: int = MAX_PLAYERS) -> Dictionary:
	var devices: Array[Dictionary] = []
	var device_ids: Array = _device_to_player.keys()
	device_ids.sort()
	for device_id in device_ids:
		devices.append({
			"device": int(device_id),
			"player": int(_device_to_player[device_id]),
			"name": _get_device_display_name(int(device_id)),
		})

	var players: Array[Dictionary] = []
	var player_count := mini(max_players_to_report, MAX_PLAYERS)
	for player_idx in player_count:
		var raw_axes: Dictionary = _tracker.get_axis_snapshot(player_idx)
		var filtered_axes: Dictionary = {}
		for action in raw_axes:
			var value := float(raw_axes[action])
			if absf(value) > 0.01:
				filtered_axes[String(action)] = snappedf(value, 0.01)
		var player_devices: Array[int] = []
		for device_id in device_ids:
			if int(_device_to_player[device_id]) == player_idx:
				player_devices.append(int(device_id))
		players.append({
			"player": player_idx,
			"devices": player_devices,
			"pressed": _tracker.get_pressed_actions(player_idx),
			"axes": filtered_axes,
			"active": int(_last_input_state.get("player", -1)) == player_idx,
			"last_action": String(_last_input_state.get("action", "")) if int(_last_input_state.get("player", -1)) == player_idx else "",
			"last_state": String(_last_input_state.get("state", "")) if int(_last_input_state.get("player", -1)) == player_idx else "",
		})

	return {
		"context": String(get_context_name()),
		"active": _last_input_state.duplicate(true),
		"devices": devices,
		"players": players,
	}


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		# In single-player, the first joypad shares player 0 with keyboard
		# so both devices control the same character.
		var joypad_count := 0
		for dev_id: int in _device_to_player:
			if dev_id >= 0:
				joypad_count += 1
		var target_slot: int
		if joypad_count == 0:
			# First joypad — assign to player 0 alongside keyboard.
			target_slot = 0
		else:
			# Additional joypads get their own player slots.
			target_slot = _find_next_available_slot()
		if target_slot >= 0:
			_device_to_player[device_id] = target_slot
			_record_input_debug(device_id, target_slot, &"", &"connected")
			EventBus.emit_checked(&"input_device_connected", [device_id], {
				"device_id": device_id,
				"player": target_slot,
			})
	else:
		if device_id in _device_to_player:
			var player_idx: int = _device_to_player[device_id]
			_tracker.clear_device_state(player_idx, device_id)
			_device_to_player.erase(device_id)
			_record_input_debug(device_id, player_idx, &"", &"disconnected")
			EventBus.emit_checked(&"input_device_disconnected", [device_id], {"device_id": device_id})
	# Notify touch controls layer about visibility changes on mobile.
	if is_mobile():
		var should_show := should_show_touch_controls()
		EventBus.emit_checked(&"input_touch_visibility_changed", [should_show], {
			"should_show": should_show,
		})


func _find_next_available_slot() -> int:
	for i in MAX_PLAYERS:
		if i not in _device_to_player.values():
			return i
	return -1


## Check for joypads already connected at startup and map them.
func _scan_connected_joypads() -> void:
	var connected_pads := Input.get_connected_joypads()
	for device_id: int in connected_pads:
		if device_id not in _device_to_player:
			_on_joy_connection_changed(device_id, true)


# --- Controller Remapping ---


## Get the current joypad button index assigned to an action, or -1 if none.
func get_joypad_button_for_action(action: StringName) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return (event as InputEventJoypadButton).button_index
	return -1


## Get human-readable name for a joypad button index.
func get_button_display_name(button_index: int) -> String:
	return JOYPAD_BUTTON_NAMES.get(button_index, "Button %d" % button_index)


## Remap a single action's joypad button. Removes old joypad button event and adds new one.
func remap_action_joypad(action: StringName, new_button_index: int) -> void:
	if not InputMap.has_action(action):
		return
	var previous_button := get_joypad_button_for_action(action)
	if previous_button == new_button_index:
		return
	var conflicting_action := _find_action_for_joypad_button(new_button_index, action)
	if conflicting_action != &"":
		_apply_joypad_button_binding(conflicting_action, previous_button)
	_apply_joypad_button_binding(action, new_button_index)
	_rebuild_input_cache()


## Save current controller bindings to user:// config file.
func save_controller_bindings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", CONTROLLER_BINDINGS_VERSION)
	for action: StringName in REMAPPABLE_ACTIONS:
		var btn := get_joypad_button_for_action(action)
		if btn >= 0:
			cfg.set_value("bindings", str(action), btn)
	cfg.save(CONTROLLER_BINDINGS_PATH)


## Load and apply controller bindings from user:// config file.
func load_controller_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONTROLLER_BINDINGS_PATH) != OK:
		return
	var loaded_version: int = int(cfg.get_value("meta", "version", 1))
	var needs_resave := loaded_version < CONTROLLER_BINDINGS_VERSION
	for action: StringName in REMAPPABLE_ACTIONS:
		var key := str(action)
		if cfg.has_section_key("bindings", key):
			var btn: int = cfg.get_value("bindings", key, -1)
			if btn >= 0:
				if loaded_version < CONTROLLER_BINDINGS_VERSION:
					btn = _migrate_legacy_joypad_button(btn)
				remap_action_joypad(action, btn)
	if needs_resave:
		save_controller_bindings()


## Reset all remappable actions to default joypad buttons.
func reset_controller_defaults() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if action in DEFAULT_JOYPAD_BUTTONS:
			remap_action_joypad(action, DEFAULT_JOYPAD_BUTTONS[action])
	save_controller_bindings()


func _migrate_legacy_joypad_button(button_index: int) -> int:
	match button_index:
		4:
			return JOY_BUTTON_LEFT_SHOULDER
		5:
			return JOY_BUTTON_RIGHT_SHOULDER
		6:
			return JOY_BUTTON_BACK
		7:
			return JOY_BUTTON_START
		8:
			return JOY_BUTTON_LEFT_STICK
		9:
			return JOY_BUTTON_RIGHT_STICK
		10:
			return JOY_BUTTON_GUIDE
		_:
			return button_index


# --- Keyboard Remapping ---


## Get the current keyboard key assigned to an action, or -1 if none.
func get_keyboard_key_for_action(action: StringName) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).keycode
	return -1


## Get human-readable name for a keyboard key.
func get_key_display_name(keycode: int) -> String:
	if keycode <= 0:
		return "Not Bound"
	return OS.get_keycode_string(keycode)


## Remap a single action's keyboard key. Removes old key event and adds new one.
func remap_action_keyboard(action: StringName, new_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	var previous_keycode := get_keyboard_key_for_action(action)
	if previous_keycode == new_keycode:
		return
	var conflicting_action := _find_action_for_keyboard_key(new_keycode, action)
	if conflicting_action != &"":
		_apply_keyboard_binding(conflicting_action, previous_keycode)
	_apply_keyboard_binding(action, new_keycode)
	_rebuild_input_cache()


## Save current keyboard bindings to user:// config file.
func save_keyboard_bindings() -> void:
	var cfg := ConfigFile.new()
	for action: StringName in REMAPPABLE_ACTIONS:
		var key: int = get_keyboard_key_for_action(action)
		if key > 0:
			cfg.set_value("bindings", str(action), key)
	cfg.save(Constants.KEYBOARD_BINDINGS_PATH)


## Load and apply keyboard bindings from user:// config file.
func load_keyboard_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Constants.KEYBOARD_BINDINGS_PATH) != OK:
		return
	for action: StringName in REMAPPABLE_ACTIONS:
		var key_str := str(action)
		if cfg.has_section_key("bindings", key_str):
			var keycode: int = cfg.get_value("bindings", key_str, -1)
			if keycode > 0:
				remap_action_keyboard(action, keycode)


## Reset all remappable actions to default keyboard keys.
func reset_keyboard_defaults() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if action in DEFAULT_KEYBOARD_KEYS:
			remap_action_keyboard(action, DEFAULT_KEYBOARD_KEYS[action])
	save_keyboard_bindings()


func _find_action_for_keyboard_key(keycode: int, excluded_action: StringName = &"") -> StringName:
	if keycode <= 0:
		return &""
	for action: StringName in REMAPPABLE_ACTIONS:
		if action == excluded_action:
			continue
		if get_keyboard_key_for_action(action) == keycode:
			return action
	return &""


func _find_action_for_joypad_button(button_index: int, excluded_action: StringName = &"") -> StringName:
	if button_index < 0:
		return &""
	for action: StringName in REMAPPABLE_ACTIONS:
		if action == excluded_action:
			continue
		if get_joypad_button_for_action(action) == button_index:
			return action
	return &""


func _apply_keyboard_binding(action: StringName, keycode: int) -> void:
	var events_to_remove: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			events_to_remove.append(event)
	for event: InputEvent in events_to_remove:
		InputMap.action_erase_event(action, event)
	if keycode <= 0:
		return
	var new_event := InputEventKey.new()
	new_event.keycode = keycode as Key
	new_event.device = -1
	InputMap.action_add_event(action, new_event)


func _apply_joypad_button_binding(action: StringName, button_index: int) -> void:
	var events_to_remove: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			events_to_remove.append(event)
	for event: InputEvent in events_to_remove:
		InputMap.action_erase_event(action, event)
	if button_index < 0:
		return
	var new_event := InputEventJoypadButton.new()
	new_event.button_index = button_index as JoyButton
	new_event.device = -1
	InputMap.action_add_event(action, new_event)


# --- Mobile / Touch ---


## Check if running on a mobile platform.
func is_mobile() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"


## Check if any controller is currently connected.
func has_controller_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


## Whether touch controls should be visible (mobile with no controller).
func should_show_touch_controls() -> bool:
	return is_mobile() and not has_controller_connected()
