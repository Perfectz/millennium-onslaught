## Base state class. Subclass for each concrete state.
class_name State
extends Node


## Reference to the owning state machine (set by StateMachine._register_child_states).
var state_machine: StateMachine = null


## Called when entering this state. Override in subclass.
func enter_state(_msg: Dictionary = {}) -> void:
	pass


## Called when exiting this state. Override in subclass.
func exit_state() -> void:
	pass


## Called every physics frame while active. Override in subclass.
func physics_process_state(_delta: float) -> void:
	pass


## Called every frame while active. Override in subclass.
func process_state(_delta: float) -> void:
	pass


## Called on unhandled input while active. Override in subclass.
func handle_input(_event: InputEvent) -> void:
	pass
