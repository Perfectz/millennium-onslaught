class_name TestXPTracker
extends GdUnitTestSuite


var _xp: XPTracker


func before_test() -> void:
	_xp = XPTracker.new()


func test_initial_state_is_level_1_zero_xp() -> void:
	assert_int(_xp.get_level()).is_equal(1)
	assert_int(_xp.get_xp()).is_equal(0)


func test_add_xp_accumulates() -> void:
	_xp.add_xp(50)
	assert_int(_xp.get_xp()).is_equal(50)
	_xp.add_xp(30)
	assert_int(_xp.get_xp()).is_equal(80)


func test_add_zero_xp_does_nothing() -> void:
	_xp.add_xp(0)
	assert_int(_xp.get_xp()).is_equal(0)


func test_add_negative_xp_is_ignored() -> void:
	_xp.add_xp(-10)
	assert_int(_xp.get_xp()).is_equal(0)


func test_xp_threshold_level_1_is_base() -> void:
	# Level 1 → 2 requires LEVEL_XP_BASE (100)
	assert_int(_xp.get_xp_for_next_level()).is_equal(Constants.LEVEL_XP_BASE)


func test_xp_threshold_scales_with_growth_rate() -> void:
	# Level 2 → 3 requires floor(100 * 1.5^1) = 150
	_xp.add_xp(100)  # level up to 2
	var expected := int(floorf(Constants.LEVEL_XP_BASE * pow(Constants.LEVEL_XP_GROWTH_RATE, 1)))
	assert_int(_xp.get_xp_for_next_level()).is_equal(expected)


func test_reaching_threshold_triggers_level_up() -> void:
	_xp.add_xp(100)
	assert_int(_xp.get_level()).is_equal(2)


func test_level_up_awards_stat_points() -> void:
	var points := _xp.add_xp(100)
	assert_int(points).is_equal(Constants.STAT_POINTS_PER_LEVEL)


func test_excess_xp_carries_over() -> void:
	_xp.add_xp(120)  # 100 to level up, 20 carries over
	assert_int(_xp.get_level()).is_equal(2)
	assert_int(_xp.get_xp()).is_equal(20)


func test_multiple_level_ups_in_one_add() -> void:
	# Level 1→2 = 100, level 2→3 = 150, total = 250
	var points := _xp.add_xp(250)
	assert_int(_xp.get_level()).is_equal(3)
	assert_int(points).is_equal(Constants.STAT_POINTS_PER_LEVEL * 2)


func test_xp_gained_signal_emitted() -> void:
	var signal_collector := monitor_signals(_xp)
	_xp.add_xp(50)
	await assert_signal(signal_collector).is_emitted("xp_gained", [50, 50])


func test_level_up_signal_emitted() -> void:
	var signal_collector := monitor_signals(_xp)
	_xp.add_xp(100)
	await assert_signal(signal_collector).is_emitted("level_up", [2, Constants.STAT_POINTS_PER_LEVEL])


func test_get_xp_progress_returns_ratio() -> void:
	_xp.add_xp(50)
	assert_float(_xp.get_xp_progress()).is_equal_approx(0.5, 0.01)


func test_set_state_restores_correctly() -> void:
	_xp.set_state(80, 3)
	assert_int(_xp.get_xp()).is_equal(80)
	assert_int(_xp.get_level()).is_equal(3)
