## Tests for StateMachine — state transitions, enter/exit, and edge cases.
extends GdUnitTestSuite


var _sm: StateMachine
var _state_a: State
var _state_b: State


func before_test() -> void:
	_sm = StateMachine.new()
	_state_a = State.new()
	_state_a.name = &"StateA"
	_state_b = State.new()
	_state_b.name = &"StateB"
	_sm.add_child(_state_a)
	_sm.add_child(_state_b)
	add_child(_sm)


func after_test() -> void:
	_sm.queue_free()


func test_initial_state_is_first_child() -> void:
	# After _ready, first child state should be active.
	assert_str(_sm.get_current_state_name()).is_equal("StateA")


func test_transition_to_changes_state() -> void:
	_sm.transition_to(&"StateB")
	assert_str(_sm.get_current_state_name()).is_equal("StateB")


func test_transition_to_same_state_does_nothing() -> void:
	_sm.transition_to(&"StateA")
	assert_str(_sm.get_current_state_name()).is_equal("StateA")


func test_transition_to_invalid_state_logs_error() -> void:
	_sm.transition_to(&"NonExistent")
	# Should remain in current state.
	assert_str(_sm.get_current_state_name()).is_equal("StateA")


func test_is_in_state_returns_true_for_current() -> void:
	assert_bool(_sm.is_in_state(&"StateA")).is_true()
	assert_bool(_sm.is_in_state(&"StateB")).is_false()


func test_is_in_state_after_transition() -> void:
	_sm.transition_to(&"StateB")
	assert_bool(_sm.is_in_state(&"StateB")).is_true()
	assert_bool(_sm.is_in_state(&"StateA")).is_false()


func test_state_changed_signal_emitted() -> void:
	# Monitor the signal.
	var monitor := monitor_signals(_sm)
	_sm.transition_to(&"StateB")
	await assert_signal(monitor).is_emitted("state_changed")
