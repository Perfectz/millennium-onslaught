class_name TestTPTracker
extends GdUnitTestSuite


var _tp: TPTracker


func before_test() -> void:
	_tp = TPTracker.new()


func test_initial_tp_is_zero() -> void:
	assert_float(_tp.get_current_tp()).is_equal(0.0)


func test_max_tp_equals_constant() -> void:
	assert_float(_tp.get_max_tp()).is_equal(Constants.TP_MAX)


func test_add_tp_increases_current() -> void:
	_tp.add_tp(25.0)
	assert_float(_tp.get_current_tp()).is_equal(25.0)


func test_add_tp_clamps_to_max() -> void:
	_tp.add_tp(200.0)
	assert_float(_tp.get_current_tp()).is_equal(Constants.TP_MAX)


func test_add_tp_zero_does_nothing() -> void:
	_tp.add_tp(0.0)
	assert_float(_tp.get_current_tp()).is_equal(0.0)


func test_add_tp_negative_is_ignored() -> void:
	_tp.add_tp(-10.0)
	assert_float(_tp.get_current_tp()).is_equal(0.0)


func test_spend_tp_reduces_current() -> void:
	_tp.add_tp(50.0)
	var success: bool = _tp.spend_tp(20.0)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal(30.0)


func test_spend_tp_fails_when_insufficient() -> void:
	_tp.add_tp(10.0)
	var success: bool = _tp.spend_tp(20.0)
	assert_bool(success).is_false()
	assert_float(_tp.get_current_tp()).is_equal(10.0)


func test_spend_tp_exact_amount_succeeds() -> void:
	_tp.add_tp(30.0)
	var success: bool = _tp.spend_tp(30.0)
	assert_bool(success).is_true()
	assert_float(_tp.get_current_tp()).is_equal(0.0)


func test_tick_regen_increases_tp() -> void:
	_tp.tick_regen(1.0)
	assert_float(_tp.get_current_tp()).is_equal(Constants.TP_REGEN_RATE)


func test_tick_regen_clamps_to_max() -> void:
	_tp.add_tp(Constants.TP_MAX - 0.5)
	_tp.tick_regen(1.0)
	assert_float(_tp.get_current_tp()).is_equal(Constants.TP_MAX)


func test_reset_clears_tp() -> void:
	_tp.add_tp(50.0)
	_tp.reset()
	assert_float(_tp.get_current_tp()).is_equal(0.0)


func test_tp_changed_signal_on_add() -> void:
	var monitor := monitor_signals(_tp)
	_tp.add_tp(25.0)
	await assert_signal(monitor).is_emitted("tp_changed", [25.0, Constants.TP_MAX])


func test_tp_spent_signal_on_spend() -> void:
	_tp.add_tp(50.0)
	var monitor := monitor_signals(_tp)
	_tp.spend_tp(20.0)
	await assert_signal(monitor).is_emitted("tp_spent", [20.0])
