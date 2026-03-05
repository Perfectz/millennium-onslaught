## Generic finite state machine with enter/exit/process pattern.
class_name StateMachine
extends Node


signal state_changed(new_state_name: StringName, old_state_name: StringName)

## Currently active state.
var _current_state: State = null

## Previous state for transition context.
var _previous_state: State = null

## Map of state name → State node.
var _states: Dictionary = {}


func _ready() -> void:
	_register_child_states()
	if _states.size() > 0 and _current_state == null:
		var first_child: State = get_child(0) as State
		if first_child:
			transition_to(first_child.name)


func _physics_process(delta: float) -> void:
	if _current_state == null:
		return
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_current_state.physics_process_state(capped_delta)


func _process(delta: float) -> void:
	if _current_state == null:
		return
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_current_state.process_state(capped_delta)


func _unhandled_input(event: InputEvent) -> void:
	if _current_state == null:
		return
	_current_state.handle_input(event)


## Transition to a named state.
func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if state_name not in _states:
		push_error("StateMachine: state not found: " + str(state_name))
		return
	var new_state: State = _states[state_name]
	if new_state == _current_state:
		return
	var old_name: StringName = _current_state.name if _current_state else &""
	if _current_state:
		_current_state.exit_state()
	_previous_state = _current_state
	_current_state = new_state
	_current_state.enter_state(msg)
	state_changed.emit(state_name, old_name)


## Get the current state name.
func get_current_state_name() -> StringName:
	if _current_state == null:
		return &""
	return _current_state.name


## Check if currently in a specific state.
func is_in_state(state_name: StringName) -> bool:
	return _current_state != null and _current_state.name == state_name


func _register_child_states() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
