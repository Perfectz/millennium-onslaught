## Tests for HealthComponent — damage, healing, death, and edge cases.
extends GdUnitTestSuite


var _health: HealthComponent


func before_test() -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health.setup(100.0)


func after_test() -> void:
	_health.queue_free()


func test_setup_initializes_hp() -> void:
	assert_float(_health.get_current_hp()).is_equal(100.0)
	assert_float(_health.get_max_hp()).is_equal(100.0)
	assert_bool(_health.is_dead()).is_false()


func test_take_damage_reduces_hp() -> void:
	var actual: float = _health.take_damage(30.0)
	assert_float(actual).is_equal(30.0)
	assert_float(_health.get_current_hp()).is_equal(70.0)


func test_take_damage_at_zero_triggers_death() -> void:
	_health.take_damage(100.0)
	assert_bool(_health.is_dead()).is_true()
	assert_float(_health.get_current_hp()).is_equal(0.0)


func test_take_damage_clamps_at_zero() -> void:
	var actual: float = _health.take_damage(150.0)
	assert_float(actual).is_equal(100.0)
	assert_float(_health.get_current_hp()).is_equal(0.0)


func test_take_damage_while_dead_returns_zero() -> void:
	_health.take_damage(100.0)
	var actual: float = _health.take_damage(50.0)
	assert_float(actual).is_equal(0.0)


func test_take_zero_damage_returns_zero() -> void:
	var actual: float = _health.take_damage(0.0)
	assert_float(actual).is_equal(0.0)
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_take_negative_damage_returns_zero() -> void:
	var actual: float = _health.take_damage(-10.0)
	assert_float(actual).is_equal(0.0)


func test_heal_restores_hp() -> void:
	_health.take_damage(50.0)
	var actual: float = _health.heal(30.0)
	assert_float(actual).is_equal(30.0)
	assert_float(_health.get_current_hp()).is_equal(80.0)


func test_heal_does_not_exceed_max() -> void:
	_health.take_damage(20.0)
	var actual: float = _health.heal(50.0)
	assert_float(actual).is_equal(20.0)
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_heal_while_dead_returns_zero() -> void:
	_health.take_damage(100.0)
	var actual: float = _health.heal(50.0)
	assert_float(actual).is_equal(0.0)


func test_heal_zero_returns_zero() -> void:
	_health.take_damage(50.0)
	var actual: float = _health.heal(0.0)
	assert_float(actual).is_equal(0.0)


func test_hp_ratio_at_full() -> void:
	assert_float(_health.get_hp_ratio()).is_equal(1.0)


func test_hp_ratio_at_half() -> void:
	_health.take_damage(50.0)
	assert_float(_health.get_hp_ratio()).is_equal(0.5)


func test_hp_ratio_at_zero() -> void:
	_health.take_damage(100.0)
	assert_float(_health.get_hp_ratio()).is_equal(0.0)


func test_revive_restores_full_hp() -> void:
	_health.take_damage(100.0)
	assert_bool(_health.is_dead()).is_true()
	_health.revive()
	assert_bool(_health.is_dead()).is_false()
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_multiple_damage_events() -> void:
	_health.take_damage(30.0)
	_health.take_damage(30.0)
	_health.take_damage(30.0)
	assert_float(_health.get_current_hp()).is_equal(10.0)
	assert_bool(_health.is_dead()).is_false()
	_health.take_damage(10.0)
	assert_bool(_health.is_dead()).is_true()
