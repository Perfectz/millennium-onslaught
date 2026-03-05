## Parameterized damage formula tests — comprehensive coverage across stat ranges.
extends GdUnitTestSuite


func test_damage_increases_with_strength() -> void:
	var prev: float = 0.0
	for str_val: int in [0, 5, 10, 15, 20]:
		var dmg: float = CombatService.calculate_damage(10.0, str_val, 0)
		assert_float(dmg).is_greater_equal(prev)
		prev = dmg


func test_damage_decreases_with_defense() -> void:
	var prev: float = INF
	for def_val: int in [0, 5, 10, 15, 20]:
		var dmg: float = CombatService.calculate_damage(10.0, 5, def_val)
		assert_float(dmg).is_less_equal(prev)
		prev = dmg


func test_damage_never_below_floor_across_ranges() -> void:
	for str_val: int in [0, 1, 5, 10]:
		for def_val: int in [0, 10, 30, 50, 99]:
			for base: float in [1.0, 5.0, 10.0, 50.0]:
				var dmg: float = CombatService.calculate_damage(base, str_val, def_val)
				assert_float(dmg).is_greater_equal(CombatService.MIN_DAMAGE)


func test_critical_is_always_150_percent() -> void:
	for str_val: int in [0, 5, 10, 20]:
		for def_val: int in [0, 5, 10]:
			var normal: float = CombatService.calculate_damage(10.0, str_val, def_val)
			var crit: float = CombatService.calculate_damage(10.0, str_val, def_val, &"physical", &"", true)
			# Crit should be 1.5x normal (or both at floor).
			if normal > CombatService.MIN_DAMAGE:
				assert_float(crit).is_equal_approx(normal * CombatService.CRIT_MULTIPLIER, 0.01)


func test_element_effectiveness_fire_ice() -> void:
	var neutral: float = CombatService.calculate_damage(10.0, 5, 5, &"physical", &"ice")
	var effective: float = CombatService.calculate_damage(10.0, 5, 5, &"fire", &"ice")
	assert_float(effective).is_greater(neutral)


func test_element_effectiveness_ice_lightning() -> void:
	var neutral: float = CombatService.calculate_damage(10.0, 5, 5, &"physical", &"lightning")
	var effective: float = CombatService.calculate_damage(10.0, 5, 5, &"ice", &"lightning")
	assert_float(effective).is_greater(neutral)


func test_element_effectiveness_lightning_fire() -> void:
	var neutral: float = CombatService.calculate_damage(10.0, 5, 5, &"physical", &"fire")
	var effective: float = CombatService.calculate_damage(10.0, 5, 5, &"lightning", &"fire")
	assert_float(effective).is_greater(neutral)


func test_element_same_type_penalty() -> void:
	for elem: StringName in [&"fire", &"ice", &"lightning"]:
		var neutral: float = CombatService.calculate_damage(10.0, 5, 5, &"physical")
		var same: float = CombatService.calculate_damage(10.0, 5, 5, elem, elem)
		assert_float(same).is_less(neutral)


func test_crit_chance_scaling() -> void:
	# Base (0 agi) should be 5%.
	var base: float = CombatService.calculate_crit_chance(0)
	assert_float(base).is_equal_approx(0.05, 0.001)
	# 10 agi should be higher.
	var mid: float = CombatService.calculate_crit_chance(10)
	assert_float(mid).is_equal_approx(0.10, 0.001)
	# Very high agi should be capped.
	var max_val: float = CombatService.calculate_crit_chance(200)
	assert_float(max_val).is_less_equal(Constants.PASSIVE_EFFECT_CAP)


func test_xp_scaling_across_level_differences() -> void:
	# Higher enemy = more XP.
	var xp_arr: Array[int] = []
	for diff: int in [-5, -2, 0, 2, 5]:
		var xp: int = CombatService.calculate_xp_reward(10 + diff, 10)
		xp_arr.append(xp)
	# Should be monotonically non-decreasing.
	for i: int in range(1, xp_arr.size()):
		assert_int(xp_arr[i]).is_greater_equal(xp_arr[i - 1])


func test_xp_for_level_curve_is_exponential() -> void:
	var l1: int = CombatService.calculate_xp_for_level(1)
	var l5: int = CombatService.calculate_xp_for_level(5)
	var l10: int = CombatService.calculate_xp_for_level(10)
	assert_int(l5).is_greater(l1)
	assert_int(l10).is_greater(l5)
	# Growth should accelerate.
	var growth_1_5: int = l5 - l1
	var growth_5_10: int = l10 - l5
	assert_int(growth_5_10).is_greater(growth_1_5)


func test_blocked_damage_is_reduced() -> void:
	for dmg: float in [10.0, 50.0, 100.0, 500.0]:
		var blocked: float = CombatService.calculate_blocked_damage(dmg)
		assert_float(blocked).is_less(dmg)
		assert_float(blocked).is_greater_equal(0.0)
