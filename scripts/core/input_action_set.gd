## Data-driven input action set definitions per InputContext.
## Instead of hardcoding action mappings, actions are defined in data
## and loaded per context.
class_name InputActionSet
extends RefCounted


## Action definition: name → array of input events.
var _actions: Dictionary = {}

## Context this action set belongs to.
var _context_name: StringName = &""


## Create an action set for a named context.
func _init(context_name: StringName = &"") -> void:
	_context_name = context_name


## Get the context name.
func get_context_name() -> StringName:
	return _context_name


## Define an action with a name.
func define_action(action_name: StringName, display_name: String = "") -> void:
	_actions[action_name] = {
		"display_name": display_name if display_name != "" else str(action_name),
		"events": [],
	}


## Add an input event binding to an action.
func bind_key(action_name: StringName, keycode: int) -> void:
	if action_name not in _actions:
		push_warning("InputActionSet: Action not defined: " + str(action_name))
		return
	var event := InputEventKey.new()
	event.keycode = keycode
	_actions[action_name]["events"].append(event)


## Add a joypad button binding.
func bind_joy_button(action_name: StringName, button: int) -> void:
	if action_name not in _actions:
		push_warning("InputActionSet: Action not defined: " + str(action_name))
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_actions[action_name]["events"].append(event)


## Get all defined action names.
func get_action_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for key: StringName in _actions:
		names.append(key)
	return names


## Get the display name for an action.
func get_display_name(action_name: StringName) -> String:
	if action_name in _actions:
		return _actions[action_name]["display_name"]
	return ""


## Get all input events for an action.
func get_events(action_name: StringName) -> Array:
	if action_name in _actions:
		return _actions[action_name]["events"]
	return []


## Check if an action is defined.
func has_action(action_name: StringName) -> bool:
	return action_name in _actions


## Apply this action set to Godot's InputMap.
func apply_to_input_map() -> void:
	for action_name: StringName in _actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		else:
			InputMap.action_erase_events(action_name)
		for event in _actions[action_name]["events"]:
			InputMap.action_add_event(action_name, event)


## Remove this action set's actions from InputMap.
func remove_from_input_map() -> void:
	for action_name: StringName in _actions:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)


## Create the default combat action set.
static func create_combat_set() -> InputActionSet:
	var s := InputActionSet.new(&"combat")
	s.define_action(&"move_left", "Move Left")
	s.bind_key(&"move_left", KEY_A)
	s.bind_key(&"move_left", KEY_LEFT)
	s.define_action(&"move_right", "Move Right")
	s.bind_key(&"move_right", KEY_D)
	s.bind_key(&"move_right", KEY_RIGHT)
	s.define_action(&"move_up", "Move Up (Belt Depth)")
	s.bind_key(&"move_up", KEY_W)
	s.bind_key(&"move_up", KEY_UP)
	s.define_action(&"move_down", "Move Down (Belt Depth)")
	s.bind_key(&"move_down", KEY_S)
	s.bind_key(&"move_down", KEY_DOWN)
	s.define_action(&"jump", "Jump")
	s.bind_key(&"jump", KEY_SPACE)
	s.define_action(&"attack_light", "Light Attack")
	s.bind_key(&"attack_light", KEY_J)
	s.define_action(&"attack_heavy", "Heavy Attack")
	s.bind_key(&"attack_heavy", KEY_K)
	s.define_action(&"dodge", "Dodge")
	s.bind_key(&"dodge", KEY_L)
	s.define_action(&"technique", "Technique")
	s.bind_key(&"technique", KEY_I)
	return s


## Create the default menu action set.
static func create_menu_set() -> InputActionSet:
	var s := InputActionSet.new(&"menu")
	s.define_action(&"ui_up", "Navigate Up")
	s.bind_key(&"ui_up", KEY_W)
	s.bind_key(&"ui_up", KEY_UP)
	s.define_action(&"ui_down", "Navigate Down")
	s.bind_key(&"ui_down", KEY_S)
	s.bind_key(&"ui_down", KEY_DOWN)
	s.define_action(&"ui_accept", "Confirm")
	s.bind_key(&"ui_accept", KEY_ENTER)
	s.bind_key(&"ui_accept", KEY_SPACE)
	s.define_action(&"ui_cancel", "Cancel/Back")
	s.bind_key(&"ui_cancel", KEY_ESCAPE)
	return s
