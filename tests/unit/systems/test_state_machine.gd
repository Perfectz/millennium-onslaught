class_name TestStateMachine
extends GdUnitTestSuite


# Mock state that tracks calls for testing.
class MockState extends State:
	var enter_called: bool = false
	var exit_called: bool = false
	var last_previous_state: StringName = &""
	var next_state_on_process: StringName = &""
	var next_state_on_physics: StringName = &""

	func enter(previous_state: StringName) -> void:
		enter_called = true
		last_previous_state = previous_state

	func exit() -> void:
		exit_called = true

	func process(_delta: float) -> StringName:
		return next_state_on_process

	func physics_process(_delta: float) -> StringName:
		return next_state_on_physics


var _machine: StateMachine
var _idle_state: MockState
var _run_state: MockState
var _jump_state: MockState


func before_test() -> void:
	_machine = StateMachine.new()
	_idle_state = MockState.new()
	_run_state = MockState.new()
	_jump_state = MockState.new()
	_machine.add_state(&"idle", _idle_state)
	_machine.add_state(&"run", _run_state)
	_machine.add_state(&"jump", _jump_state)


func after_test() -> void:
	_machine.free()


func test_initial_state_is_set_correctly() -> void:
	_machine.set_initial_state(&"idle")
	assert_str(String(_machine.current_state_name)).is_equal("idle")


func test_initial_state_enter_is_called() -> void:
	_machine.set_initial_state(&"idle")
	assert_bool(_idle_state.enter_called).is_true()
	assert_str(String(_idle_state.last_previous_state)).is_equal("")


func test_transition_changes_current_state() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	assert_str(String(_machine.current_state_name)).is_equal("run")


func test_transition_calls_exit_on_old_state() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	assert_bool(_idle_state.exit_called).is_true()


func test_transition_calls_enter_on_new_state() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	assert_bool(_run_state.enter_called).is_true()
	assert_str(String(_run_state.last_previous_state)).is_equal("idle")


func test_transition_to_same_state_reenters_state() -> void:
	_machine.set_initial_state(&"idle")
	_idle_state.exit_called = false
	_idle_state.enter_called = false
	_machine.transition_to(&"idle")
	assert_bool(_idle_state.exit_called).is_true()
	assert_bool(_idle_state.enter_called).is_true()
	assert_str(String(_idle_state.last_previous_state)).is_equal("idle")


func test_previous_state_name_tracks_history() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	assert_str(String(_machine.previous_state_name)).is_equal("idle")


func test_multiple_states_can_be_registered() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	_machine.transition_to(&"jump")
	assert_str(String(_machine.current_state_name)).is_equal("jump")
	assert_str(String(_machine.previous_state_name)).is_equal("run")


func test_get_current_state_returns_state_object() -> void:
	_machine.set_initial_state(&"idle")
	assert_object(_machine.get_current_state()).is_same(_idle_state)


func test_state_receives_machine_reference() -> void:
	assert_object(_idle_state.machine).is_same(_machine)


func test_transition_chain() -> void:
	_machine.set_initial_state(&"idle")
	_machine.transition_to(&"run")
	_machine.transition_to(&"jump")
	_machine.transition_to(&"idle")
	assert_str(String(_machine.current_state_name)).is_equal("idle")
	assert_str(String(_machine.previous_state_name)).is_equal("jump")
