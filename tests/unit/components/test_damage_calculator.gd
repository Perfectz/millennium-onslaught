class_name TestDamageCalculator
extends GdUnitTestSuite


func test_basic_damage_calculation() -> void:
	assert_float(DamageCalculator.calculate(10.0, 1.0, 0.0)).is_equal(10.0)


func test_multiplier_increases_damage() -> void:
	assert_float(DamageCalculator.calculate(10.0, 2.5, 0.0)).is_equal(25.0)


func test_defense_reduces_damage() -> void:
	assert_float(DamageCalculator.calculate(10.0, 1.0, 3.0)).is_equal(7.0)


func test_defense_does_not_make_damage_below_one() -> void:
	assert_float(DamageCalculator.calculate(10.0, 1.0, 20.0)).is_equal(1.0)


func test_zero_base_damage_returns_zero() -> void:
	assert_float(DamageCalculator.calculate(0.0, 2.0, 0.0)).is_equal(0.0)


func test_light_attack_damage_from_constants() -> void:
	var result := DamageCalculator.calculate(Constants.LIGHT_ATTACK_DAMAGE, 1.0, 0.0)
	assert_float(result).is_equal(10.0)


func test_heavy_attack_damage_from_constants() -> void:
	var result := DamageCalculator.calculate(Constants.HEAVY_ATTACK_DAMAGE, 1.0, 0.0)
	assert_float(result).is_equal(25.0)
