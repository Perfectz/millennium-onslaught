class_name TestCombinationGauge
extends GdUnitTestSuite


var _gauge: CombinationGauge


func before_test() -> void:
	_gauge = CombinationGauge.new()


func test_starts_empty() -> void:
	assert_float(_gauge.get_value()).is_equal(0.0)
	assert_bool(_gauge.is_full()).is_false()


func test_add_clamps_to_max() -> void:
	_gauge.add(Constants.COMBINATION_GAUGE_MAX * 3.0)
	assert_float(_gauge.get_value()).is_equal(Constants.COMBINATION_GAUGE_MAX)
	assert_bool(_gauge.is_full()).is_true()


func test_negative_add_is_ignored() -> void:
	_gauge.add(10.0)
	_gauge.add(-5.0)
	assert_float(_gauge.get_value()).is_equal(10.0)


func test_hit_and_ko_gains_use_constants() -> void:
	_gauge.register_hit()
	_gauge.register_ko()
	assert_float(_gauge.get_value()).is_equal(
		Constants.COMBINATION_GAIN_PER_HIT + Constants.COMBINATION_GAIN_PER_KO)


func test_damage_taken_fills_gauge_proportionally() -> void:
	_gauge.register_damage_taken(20.0)
	assert_float(_gauge.get_value()).is_equal(20.0 * Constants.COMBINATION_GAIN_ON_DAMAGE_TAKEN_RATIO)


func test_consume_requires_full_gauge() -> void:
	_gauge.add(Constants.COMBINATION_GAUGE_MAX - 1.0)
	assert_bool(_gauge.try_consume()).is_false()
	assert_float(_gauge.get_value()).is_equal(Constants.COMBINATION_GAUGE_MAX - 1.0)


func test_consume_empties_full_gauge() -> void:
	_gauge.add(Constants.COMBINATION_GAUGE_MAX)
	assert_bool(_gauge.try_consume()).is_true()
	assert_float(_gauge.get_value()).is_equal(0.0)


func test_ratio() -> void:
	_gauge.add(Constants.COMBINATION_GAUGE_MAX * 0.25)
	assert_float(_gauge.get_ratio()).is_equal_approx(0.25, 0.0001)


func test_changed_signal_emits_on_change() -> void:
	var calls: Array[float] = []
	_gauge.changed.connect(func(value: float, _max: float) -> void: calls.append(value))
	_gauge.add(5.0)
	_gauge.add(0.0)
	assert_array(calls).is_equal([5.0])
