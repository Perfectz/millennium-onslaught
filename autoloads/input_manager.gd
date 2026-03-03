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

## Path for saved controller bindings.
const CONTROLLER_BINDINGS_PATH: String = "user://controller_bindings.cfg"

## Actions that can be remapped (button-based, not axis-movement).
const REMAPPABLE_ACTIONS: Array[StringName] = [
	&"jump", &"attack_light", &"attack_heavy", &"dodge",
	&"block", &"technique", &"technique_cycle", &"pause",
]

## Human-readable labels for remappable actions.
const ACTION_DISPLAY_NAMES: Dictionary = {
	&"jump": "Jump",
	&"attack_light": "Light Attack",
	&"attack_heavy": "Heavy Attack",
	&"dodge": "Dodge",
	&"block": "Block",
	&"technique": "Technique",
	&"technique_cycle": "Cycle Technique",
	&"pause": "Pause",
}

## Default joypad button index for each remappable action (SDL standard).
const DEFAULT_JOYPAD_BUTTONS: Dictionary = {
	&"jump": 0,
	&"attack_light": 2,
	&"attack_heavy": 3,
	&"dodge": 1,
	&"block": 4,
	&"technique": 5,
	&"technique_cycle": 6,
	&"pause": 7,
}

## Default keyboard key for each remappable action.
const DEFAULT_KEYBOARD_KEYS: Dictionary = {
	&"jump": KEY_SPACE,
	&"attack_light": KEY_J,
	&"attack_heavy": KEY_K,
	&"dodge": KEY_L,
	&"block": KEY_I,
	&"technique": KEY_U,
	&"technique_cycle": KEY_TAB,
	&"pause": KEY_ESCAPE,
}

## Joypad button index names for display.
const JOYPAD_BUTTON_NAMES: Dictionary = {
	0: "A / Cross",
	1: "B / Circle",
	2: "X / Square",
	3: "Y / Triangle",
	4: "LB / L1",
	5: "RB / R1",
	6: "Back / Select",
	7: "Start / Options",
	8: "L3",
	9: "R3",
	10: "Guide / PS",
	11: "D-Pad Up",
	12: "D-Pad Down",
	13: "D-Pad Left",
	14: "D-Pad Right",
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
	_ensure_ui_joypad_mappings()
	_populate_tracked_actions()
	# Map any joypads already connected at startup.
	_scan_connected_joypads()
	# Apply saved bindings (if any).
	load_controller_bindings()
	load_keyboard_bindings()


## Ensure Godot's built-in ui_accept and ui_cancel have joypad button mappings.
## Without this, controller users can't confirm/cancel in native Godot UI elements.
func _ensure_ui_joypad_mappings() -> void:
	_ensure_joypad_button(&"ui_accept", JOY_BUTTON_A)
	_ensure_joypad_button(&"ui_cancel", JOY_BUTTON_B)


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


## Cache all action names from the InputMap.
func _populate_tracked_actions() -> void:
	_tracked_actions.clear()
	for action: StringName in InputMap.get_actions():
		# Skip built-in Godot UI actions (ui_*).
		if not action.begins_with("ui_"):
			_tracked_actions.append(action)


## Route each InputEvent to the correct player's tracker state.
func _input(event: InputEvent) -> void:
	var device_id: int = event.device
	# Keyboard events come through as device 0 but InputMap treats them as -1.
	if event is InputEventKey or event is InputEventMouseButton:
		device_id = -1

	var player_idx: int = _device_to_player.get(device_id, -1)
	if player_idx < 0:
		return

	for action: StringName in _tracked_actions:
		if event.is_action_pressed(action):
			_tracker.register_action_pressed(player_idx, action)
		elif event.is_action_released(action):
			_tracker.register_action_released(player_idx, action)

	# Axis values for analog sticks.
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		for action: StringName in _tracked_actions:
			if InputMap.action_has_event(action, motion):
				var strength: float = motion.axis_value
				_tracker.register_axis_value(player_idx, action, absf(strength))


## Clear just_pressed flags at end of each frame.
## Runs in _process (not _physics_process) with process_priority=1000
## so it executes AFTER all scene nodes have consumed their flags.
## Godot main loop order: _input → _physics_process → _process.
## If we cleared in _physics_process, autoloads run first and would
## wipe flags before PlayerController can read them.
func _process(_delta: float) -> void:
	_tracker.end_frame()


# --- Per-Player Query API (replaces global Input.xxx() calls) ---


## Check if an action is currently held for a specific player.
func is_action_pressed_for_player(player_idx: int, action: StringName) -> bool:
	return _tracker.is_pressed(player_idx, action)


## Consume a just_pressed event for a specific player (one-shot).
func is_action_just_pressed_for_player(player_idx: int, action: StringName) -> bool:
	return _tracker.consume_just_pressed(player_idx, action)


## Get axis value for a specific player (negative_action vs positive_action).
func get_axis_for_player(player_idx: int, negative_action: StringName, positive_action: StringName) -> float:
	return _tracker.get_axis(player_idx, negative_action, positive_action)


# --- Touch Injection (for mobile virtual controls) ---


## Inject a touch press as if it came from a virtual device for the given player.
func inject_touch_action_pressed(player_idx: int, action: StringName) -> void:
	_tracker.register_action_pressed(player_idx, action)


## Inject a touch release for the given player.
func inject_touch_action_released(player_idx: int, action: StringName) -> void:
	_tracker.register_action_released(player_idx, action)


## Inject a touch axis value for the given player.
func inject_touch_axis(player_idx: int, action: StringName, value: float) -> void:
	_tracker.register_axis_value(player_idx, action, value)


# --- Context Switching ---


## Switch the active input context.
func set_context(context: InputContext) -> void:
	_current_context = context
	var context_names: Dictionary = {
		InputContext.COMBAT: &"combat",
		InputContext.MENU: &"menu",
		InputContext.OVERWORLD: &"overworld",
		InputContext.DIALOGUE: &"dialogue",
	}
	EventBus.input_context_changed.emit(context_names[context])
	EventBus.log_event(&"input_context_changed", {"context": context_names[context]})


## Get the current input context.
func get_context() -> InputContext:
	return _current_context


# --- Device Management ---


## Get the player index for a given device.
func get_player_for_device(device_id: int) -> int:
	return _device_to_player.get(device_id, -1)


## Assign a device to a player index.
func assign_device_to_player(device_id: int, player_index: int) -> void:
	_device_to_player[device_id] = player_index


## Get number of connected players.
func get_connected_player_count() -> int:
	return _device_to_player.size()


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
			EventBus.input_device_connected.emit(device_id)
			EventBus.log_event(&"input_device_connected", {
				"device": device_id,
				"player": target_slot,
			})
	else:
		if device_id in _device_to_player:
			_device_to_player.erase(device_id)
			EventBus.input_device_disconnected.emit(device_id)
			EventBus.log_event(&"input_device_disconnected", {"device": device_id})
	# Notify touch controls layer about visibility changes on mobile.
	if is_mobile():
		EventBus.input_touch_visibility_changed.emit(should_show_touch_controls())


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
	# Remove existing joypad button events from this action.
	var events_to_remove: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			events_to_remove.append(event)
	for event: InputEvent in events_to_remove:
		InputMap.action_erase_event(action, event)

	# Add the new joypad button event.
	var new_event := InputEventJoypadButton.new()
	new_event.button_index = new_button_index as JoyButton
	new_event.device = -1
	InputMap.action_add_event(action, new_event)


## Save current controller bindings to user:// config file.
func save_controller_bindings() -> void:
	var cfg := ConfigFile.new()
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
	for action: StringName in REMAPPABLE_ACTIONS:
		var key := str(action)
		if cfg.has_section_key("bindings", key):
			var btn: int = cfg.get_value("bindings", key, -1)
			if btn >= 0:
				remap_action_joypad(action, btn)


## Reset all remappable actions to default joypad buttons.
func reset_controller_defaults() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if action in DEFAULT_JOYPAD_BUTTONS:
			remap_action_joypad(action, DEFAULT_JOYPAD_BUTTONS[action])
	save_controller_bindings()


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
	# Remove existing keyboard key events from this action.
	var events_to_remove: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			events_to_remove.append(event)
	for event: InputEvent in events_to_remove:
		InputMap.action_erase_event(action, event)
	# Add the new keyboard key event.
	var new_event := InputEventKey.new()
	new_event.keycode = new_keycode as Key
	new_event.device = -1
	InputMap.action_add_event(action, new_event)


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
