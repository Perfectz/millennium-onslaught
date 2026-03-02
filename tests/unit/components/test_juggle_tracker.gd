## TDD tests for JuggleTracker — juggle counter with limit and airborne state.
class_name TestJuggleTracker
extends GdUnitTestSuite


var _tracker: JuggleTracker


func before_test() -> void:
	_tracker = JuggleTracker.new(Constants.MAX_JUGGLE_COUNT)


# --- Initialization ---

func test_initial_state_is_grounded() -> void:
	assert_bool(_tracker.is_airborne()).is_false()
	assert_int(_tracker.get_hit_count()).is_equal(0)
	assert_bool(_tracker.is_limit_reached()).is_false()


# --- Launch ---

func test_launch_makes_target_airborne() -> void:
	_tracker.launch()
	assert_bool(_tracker.is_airborne()).is_true()
	assert_int(_tracker.get_hit_count()).is_equal(0)


func test_launch_emits_launched_signal() -> void:
	var signal_collector := monitor_signals(_tracker)
	_tracker.launch()
	await assert_signal(signal_collector).is_emitted("launched")


func test_double_launch_stays_airborne() -> void:
	_tracker.launch()
	_tracker.launch()
	assert_bool(_tracker.is_airborne()).is_true()
	assert_int(_tracker.get_hit_count()).is_equal(0)


# --- Air Hit ---

func test_register_air_hit_increments_count() -> void:
	_tracker.launch()
	_tracker.register_air_hit()
	assert_int(_tracker.get_hit_count()).is_equal(1)


func test_register_air_hit_emits_air_hit_signal() -> void:
	_tracker.launch()
	var signal_collector := monitor_signals(_tracker)
	_tracker.register_air_hit()
	await assert_signal(signal_collector).is_emitted("air_hit", [1])


func test_multiple_air_hits_increment() -> void:
	_tracker.launch()
	_tracker.register_air_hit()
	_tracker.register_air_hit()
	_tracker.register_air_hit()
	assert_int(_tracker.get_hit_count()).is_equal(3)


func test_air_hit_while_grounded_does_nothing() -> void:
	_tracker.register_air_hit()
	assert_int(_tracker.get_hit_count()).is_equal(0)


# --- Juggle Limit ---

func test_limit_reached_at_max_count() -> void:
	_tracker.launch()
	for i in Constants.MAX_JUGGLE_COUNT:
		_tracker.register_air_hit()
	assert_bool(_tracker.is_limit_reached()).is_true()


func test_limit_reached_emits_signal() -> void:
	_tracker.launch()
	var signal_collector := monitor_signals(_tracker)
	for i in Constants.MAX_JUGGLE_COUNT:
		_tracker.register_air_hit()
	await assert_signal(signal_collector).is_emitted("limit_reached")


func test_hits_beyond_limit_are_rejected() -> void:
	_tracker.launch()
	for i in Constants.MAX_JUGGLE_COUNT + 3:
		_tracker.register_air_hit()
	assert_int(_tracker.get_hit_count()).is_equal(Constants.MAX_JUGGLE_COUNT)


# --- Land / Reset ---

func test_land_resets_to_grounded() -> void:
	_tracker.launch()
	_tracker.register_air_hit()
	_tracker.register_air_hit()
	_tracker.land()
	assert_bool(_tracker.is_airborne()).is_false()
	assert_int(_tracker.get_hit_count()).is_equal(0)
	assert_bool(_tracker.is_limit_reached()).is_false()


func test_land_emits_landed_signal() -> void:
	_tracker.launch()
	var signal_collector := monitor_signals(_tracker)
	_tracker.land()
	await assert_signal(signal_collector).is_emitted("landed")


func test_land_while_grounded_does_nothing() -> void:
	var signal_collector := monitor_signals(_tracker)
	_tracker.land()
	await assert_signal(signal_collector).is_not_emitted("landed")


# --- Custom Limit ---

func test_custom_juggle_limit() -> void:
	var custom := JuggleTracker.new(3)
	custom.launch()
	custom.register_air_hit()
	custom.register_air_hit()
	custom.register_air_hit()
	assert_bool(custom.is_limit_reached()).is_true()
	custom.register_air_hit()
	assert_int(custom.get_hit_count()).is_equal(3)
