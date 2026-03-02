class_name TestHealthComponent
extends GdUnitTestSuite


var _health: HealthComponent


func before_test() -> void:
	_health = HealthComponent.new(100.0)


func test_initial_hp_equals_max_hp() -> void:
	assert_float(_health.get_current_hp()).is_equal(100.0)
	assert_float(_health.get_max_hp()).is_equal(100.0)


func test_take_damage_reduces_hp() -> void:
	_health.take_damage(25.0)
	assert_float(_health.get_current_hp()).is_equal(75.0)


func test_take_damage_does_not_go_below_zero() -> void:
	_health.take_damage(200.0)
	assert_float(_health.get_current_hp()).is_equal(0.0)


func test_take_zero_damage_does_nothing() -> void:
	_health.take_damage(0.0)
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_take_negative_damage_is_ignored() -> void:
	_health.take_damage(-10.0)
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_is_dead_returns_false_when_alive() -> void:
	assert_bool(_health.is_dead()).is_false()


func test_is_dead_returns_true_at_zero_hp() -> void:
	_health.take_damage(100.0)
	assert_bool(_health.is_dead()).is_true()


func test_heal_increases_hp() -> void:
	_health.take_damage(50.0)
	_health.heal(20.0)
	assert_float(_health.get_current_hp()).is_equal(70.0)


func test_heal_does_not_exceed_max_hp() -> void:
	_health.take_damage(10.0)
	_health.heal(50.0)
	assert_float(_health.get_current_hp()).is_equal(100.0)


func test_multiple_damage_instances_accumulate() -> void:
	_health.take_damage(30.0)
	_health.take_damage(30.0)
	_health.take_damage(30.0)
	assert_float(_health.get_current_hp()).is_equal(10.0)


func test_take_damage_after_death_does_not_change_hp() -> void:
	_health.take_damage(100.0)
	assert_bool(_health.is_dead()).is_true()
	_health.take_damage(50.0)
	assert_float(_health.get_current_hp()).is_equal(0.0)


func test_set_max_hp_updates_ceiling() -> void:
	_health.set_max_hp(200.0)
	_health.heal(150.0)
	assert_float(_health.get_current_hp()).is_equal(200.0)


func test_reset_restores_full_health() -> void:
	_health.take_damage(100.0)
	assert_bool(_health.is_dead()).is_true()
	_health.reset()
	assert_float(_health.get_current_hp()).is_equal(100.0)
	assert_bool(_health.is_dead()).is_false()


func test_heal_after_death_is_ignored() -> void:
	_health.take_damage(100.0)
	_health.heal(50.0)
	assert_float(_health.get_current_hp()).is_equal(0.0)


func test_reset_emits_health_changed() -> void:
	_health.take_damage(50.0)
	var signal_collector := monitor_signals(_health)
	_health.reset()
	await assert_signal(signal_collector).is_emitted("health_changed", [100.0, 100.0])


func test_set_max_hp_clamps_current_hp() -> void:
	# Current HP is 100, reduce max to 50 → HP should clamp to 50.
	_health.set_max_hp(50.0)
	assert_float(_health.get_current_hp()).is_equal(50.0)
	assert_float(_health.get_max_hp()).is_equal(50.0)


func test_set_max_hp_rejects_non_positive() -> void:
	_health.set_max_hp(0.0)
	assert_float(_health.get_max_hp()).is_equal(100.0)
	_health.set_max_hp(-10.0)
	assert_float(_health.get_max_hp()).is_equal(100.0)
