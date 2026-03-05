## Generic finite state machine. Registers State objects by name,
## handles transitions, delegates process/physics/input to current state.
## Reusable by player, enemies, and any other stateful entity.
class_name StateMachine
extends Node


## The entity this state machine controls.
@export var entity_path: NodePath
var entity: CharacterBody3D = null

## Registered states: StringName -> State instance.
var _states: Dictionary = {}
## The currently active state.
var _current_state: State = null
## Name of the current state (for debugging and transition logic).
var current_state_name: StringName = &""
## Previous state name for transition context.
var previous_state_name: StringName = &""


func _ready() -> void:
	if entity_path:
		entity = get_node(entity_path) as CharacterBody3D


## Register a state with a name.
func add_state(state_name: StringName, state: State) -> void:
	state.machine = self
	state.entity = entity
	_states[state_name] = state


## Set the initial state (call after all states are registered).
func set_initial_state(state_name: StringName) -> void:
	if state_name not in _states:
		push_error("StateMachine: Initial state not found: " + str(state_name))
		return
	_current_state = _states[state_name]
	current_state_name = state_name
	_current_state.enter(&"")


## Transition to a new state by name. Self-transitions are allowed (re-enters the state).
func transition_to(new_state_name: StringName) -> void:
	if new_state_name not in _states:
		push_error("StateMachine: State not found: " + str(new_state_name))
		return
	if _current_state == null:
		push_error("StateMachine: No current state set. Call set_initial_state() first.")
		return
	_current_state.exit()
	previous_state_name = current_state_name
	current_state_name = new_state_name
	_current_state = _states[new_state_name]
	_current_state.enter(previous_state_name)


## Get the current State object.
func get_current_state() -> State:
	return _current_state


func _process(delta: float) -> void:
	if _current_state == null or not is_instance_valid(entity):
		return
	if get_tree().paused:
		return
	var next := _current_state.process(delta)
	if next != &"":
		transition_to(next)


func _physics_process(delta: float) -> void:
	if _current_state == null or not is_instance_valid(entity):
		return
	if get_tree().paused:
		return
	var capped := minf(delta, Constants.DELTA_CAP)
	var next := _current_state.physics_process(capped)
	if next != &"":
		transition_to(next)


func _unhandled_input(event: InputEvent) -> void:
	if _current_state == null or not is_instance_valid(entity):
		return
	var next := _current_state.handle_input(event)
	if next != &"":
		transition_to(next)
