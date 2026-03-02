## Base State class for the finite state machine.
## States are pure logic objects (RefCounted) — no scene tree dependency.
## Override enter/exit/process/physics_process/handle_input in subclasses.
class_name State
extends RefCounted


## Reference to the state machine that owns this state.
var machine: StateMachine = null
## Reference to the entity (CharacterBody3D) that this state controls.
var entity: CharacterBody3D = null


## Called when entering this state. Override in subclasses.
func enter(_previous_state: StringName) -> void:
	pass


## Called when exiting this state. Override in subclasses.
func exit() -> void:
	pass


## Called every frame. Return StringName of next state, or &"" to stay.
func process(_delta: float) -> StringName:
	return &""


## Called every physics frame. Return StringName of next state, or &"" to stay.
func physics_process(_delta: float) -> StringName:
	return &""


## Called on unhandled input. Return StringName of next state, or &"" to stay.
func handle_input(_event: InputEvent) -> StringName:
	return &""
