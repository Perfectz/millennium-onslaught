class_name TestStatCalculator
extends GdUnitTestSuite


func test_derive_from_base_only() -> void:
	var base := {"strength": 10, "magic": 5, "defense": 8, "agility": 7}
	var result := StatCalculator.calculate_derived(base, {}, {})
	assert_int(result["strength"]).is_equal(10)
	assert_int(result["magic"]).is_equal(5)
	assert_int(result["defense"]).is_equal(8)
	assert_int(result["agility"]).is_equal(7)


func test_derive_with_equipment_bonuses() -> void:
	var base := {"strength": 5, "defense": 5}
	var equip := {"strength": 3, "defense": 2}
	var result := StatCalculator.calculate_derived(base, equip, {})
	assert_int(result["strength"]).is_equal(8)
	assert_int(result["defense"]).is_equal(7)


func test_derive_with_skill_bonuses() -> void:
	var base := {"strength": 5}
	var skill := {"strength": 2, "magic": 4}
	var result := StatCalculator.calculate_derived(base, {}, skill)
	assert_int(result["strength"]).is_equal(7)
	assert_int(result["magic"]).is_equal(4)


func test_derive_with_all_sources() -> void:
	var base := {"strength": 5, "magic": 5}
	var equip := {"strength": 3}
	var skill := {"strength": 1, "magic": 2}
	var result := StatCalculator.calculate_derived(base, equip, skill)
	assert_int(result["strength"]).is_equal(9)
	assert_int(result["magic"]).is_equal(7)


func test_missing_stat_defaults_to_zero() -> void:
	var base := {"strength": 5}
	var result := StatCalculator.calculate_derived(base, {}, {})
	assert_int(StatCalculator.get_stat(result, &"agility")).is_equal(0)


func test_get_stat_returns_value() -> void:
	var stats := {"strength": 12}
	assert_int(StatCalculator.get_stat(stats, &"strength")).is_equal(12)


func test_attack_power_scales_with_strength() -> void:
	var low := StatCalculator.attack_power(10.0, 5)
	var high := StatCalculator.attack_power(10.0, 15)
	assert_float(high).is_greater(low)


func test_attack_power_with_zero_strength() -> void:
	var result := StatCalculator.attack_power(10.0, 0)
	assert_float(result).is_equal(10.0)


func test_defense_value_scales_with_defense() -> void:
	var low := StatCalculator.defense_value(5)
	var high := StatCalculator.defense_value(15)
	assert_float(high).is_greater(low)


func test_speed_modifier_from_agility() -> void:
	var result := StatCalculator.speed_modifier(10)
	assert_float(result).is_greater(1.0)
