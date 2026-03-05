## Stateless combat resolution service. Pure damage calculation logic.
## No member state — all calculations use passed parameters.
class_name CombatService
extends RefCounted


## Element effectiveness multipliers.
const ELEMENT_TABLE: Dictionary = {
	# Attacker element → { target weakness → multiplier }
	&"fire": {&"ice": 1.5, &"fire": 0.5},
	&"ice": {&"lightning": 1.5, &"ice": 0.5},
	&"lightning": {&"fire": 1.5, &"lightning": 0.5},
	&"dark": {&"physical": 1.25, &"dark": 0.75},
	&"physical": {},
}

## Critical hit multiplier.
const CRIT_MULTIPLIER: float = 1.5

## Minimum damage floor.
const MIN_DAMAGE: float = 1.0


## Calculate final damage from base damage and stat modifiers.
static func calculate_damage(
	base_damage: float,
	attacker_strength: int,
	target_defense: int,
	element: StringName = &"physical",
	target_element: StringName = &"",
	is_critical: bool = false
) -> float:
	# Strength bonus: 5% per point.
	var str_bonus: float = base_damage * (attacker_strength * 0.05)
	var raw: float = base_damage + str_bonus
	# Defense reduction: 3% per point.
	var def_reduction: float = raw * (target_defense * 0.03)
	var after_def: float = maxf(MIN_DAMAGE, raw - def_reduction)
	# Element multiplier.
	var elem_mult: float = _get_element_multiplier(element, target_element)
	var after_elem: float = after_def * elem_mult
	# Critical hit.
	if is_critical:
		after_elem *= CRIT_MULTIPLIER
	return maxf(MIN_DAMAGE, after_elem)


## Calculate critical hit chance from agility stat.
static func calculate_crit_chance(agility: int) -> float:
	# Base 5% + 0.5% per agility point, capped at 50%.
	return minf(0.05 + agility * 0.005, Constants.PASSIVE_EFFECT_CAP)


## Roll for critical hit.
static func roll_critical(agility: int) -> bool:
	return randf() < calculate_crit_chance(agility)


## Calculate knockback distance from damage and knockback base.
static func calculate_knockback(base_knockback: float, damage: float) -> float:
	return base_knockback * (1.0 + damage * 0.01)


## Calculate XP reward for killing an enemy.
static func calculate_xp_reward(enemy_level: int, player_level: int) -> int:
	var base: int = Constants.XP_BASE_PER_KILL
	var level_diff: float = float(enemy_level - player_level)
	var multiplier: float = clampf(1.0 + level_diff * 0.1, 0.1, 3.0)
	return maxi(1, int(base * multiplier))


## Calculate XP needed to reach next level.
static func calculate_xp_for_level(level: int) -> int:
	return int(Constants.LEVEL_XP_BASE * pow(Constants.LEVEL_XP_GROWTH_RATE, level - 1))


## Check if a level up should occur.
static func check_level_up(current_xp: int, current_level: int) -> bool:
	return current_xp >= calculate_xp_for_level(current_level)


## Apply block damage reduction.
static func calculate_blocked_damage(damage: float) -> float:
	return damage * (1.0 - Constants.BLOCK_DAMAGE_REDUCTION)


static func _get_element_multiplier(attacker_element: StringName, target_element: StringName) -> float:
	if attacker_element not in ELEMENT_TABLE:
		return 1.0
	var weakness_table: Dictionary = ELEMENT_TABLE[attacker_element]
	if target_element in weakness_table:
		return weakness_table[target_element]
	return 1.0
