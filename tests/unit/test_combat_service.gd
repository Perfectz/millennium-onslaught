## Tests for CombatService — damage calculation, crit, elements, XP.
extends GdUnitTestSuite


func test_base_damage_with_no_modifiers() -> void:
	var result: float = CombatService.calculate_damage(10.0, 0, 0)
	assert_float(result).is_equal(10.0)


func test_strength_increases_damage() -> void:
	var base: float = CombatService.calculate_damage(10.0, 0, 0)
	var with_str: float = CombatService.calculate_damage(10.0, 10, 0)
	assert_float(with_str).is_greater(base)


func test_defense_reduces_damage() -> void:
	var base: float = CombatService.calculate_damage(10.0, 0, 0)
	var with_def: float = CombatService.calculate_damage(10.0, 0, 10)
	assert_float(with_def).is_less(base)


func test_damage_never_below_minimum() -> void:
	var result: float = CombatService.calculate_damage(1.0, 0, 100)
	assert_float(result).is_equal_approx(CombatService.MIN_DAMAGE, 0.01)


func test_critical_hit_increases_damage() -> void:
	var normal: float = CombatService.calculate_damage(10.0, 5, 5)
	var crit: float = CombatService.calculate_damage(10.0, 5, 5, &"physical", &"", true)
	assert_float(crit).is_greater(normal)
	assert_float(crit).is_equal_approx(normal * CombatService.CRIT_MULTIPLIER, 0.01)


func test_fire_vs_ice_bonus() -> void:
	var normal: float = CombatService.calculate_damage(10.0, 5, 5, &"physical", &"ice")
	var fire_vs_ice: float = CombatService.calculate_damage(10.0, 5, 5, &"fire", &"ice")
	assert_float(fire_vs_ice).is_greater(normal)


func test_fire_vs_fire_penalty() -> void:
	var normal: float = CombatService.calculate_damage(10.0, 5, 5, &"physical")
	var fire_vs_fire: float = CombatService.calculate_damage(10.0, 5, 5, &"fire", &"fire")
	assert_float(fire_vs_fire).is_less(normal)


func test_crit_chance_increases_with_agility() -> void:
	var low_agi: float = CombatService.calculate_crit_chance(5)
	var high_agi: float = CombatService.calculate_crit_chance(50)
	assert_float(high_agi).is_greater(low_agi)


func test_crit_chance_capped() -> void:
	var max_crit: float = CombatService.calculate_crit_chance(1000)
	assert_float(max_crit).is_less_equal(Constants.PASSIVE_EFFECT_CAP)


func test_knockback_scales_with_damage() -> void:
	var low_dmg: float = CombatService.calculate_knockback(5.0, 10.0)
	var high_dmg: float = CombatService.calculate_knockback(5.0, 50.0)
	assert_float(high_dmg).is_greater(low_dmg)


func test_xp_reward_same_level() -> void:
	var xp: int = CombatService.calculate_xp_reward(5, 5)
	assert_int(xp).is_equal(Constants.XP_BASE_PER_KILL)


func test_xp_reward_higher_enemy_gives_more() -> void:
	var same: int = CombatService.calculate_xp_reward(5, 5)
	var higher: int = CombatService.calculate_xp_reward(10, 5)
	assert_int(higher).is_greater(same)


func test_xp_reward_lower_enemy_gives_less() -> void:
	var same: int = CombatService.calculate_xp_reward(5, 5)
	var lower: int = CombatService.calculate_xp_reward(1, 5)
	assert_int(lower).is_less(same)


func test_xp_reward_never_below_one() -> void:
	var xp: int = CombatService.calculate_xp_reward(1, 100)
	assert_int(xp).is_greater_equal(1)


func test_xp_for_level_increases() -> void:
	var level_1: int = CombatService.calculate_xp_for_level(1)
	var level_5: int = CombatService.calculate_xp_for_level(5)
	assert_int(level_5).is_greater(level_1)


func test_check_level_up_true_when_enough_xp() -> void:
	var needed: int = CombatService.calculate_xp_for_level(1)
	assert_bool(CombatService.check_level_up(needed, 1)).is_true()


func test_check_level_up_false_when_insufficient() -> void:
	assert_bool(CombatService.check_level_up(0, 1)).is_false()


func test_blocked_damage_reduction() -> void:
	var blocked: float = CombatService.calculate_blocked_damage(100.0)
	var expected: float = 100.0 * (1.0 - Constants.BLOCK_DAMAGE_REDUCTION)
	assert_float(blocked).is_equal_approx(expected, 0.01)
