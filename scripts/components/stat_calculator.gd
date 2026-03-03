## Pure stat calculation logic. No scene tree dependency — fully testable.
## Computes derived stats from base + equipment bonuses + skill bonuses.
class_name StatCalculator
extends RefCounted


## Calculate derived stats by summing base, equipment, and skill bonuses.
static func calculate_derived(base_stats: Dictionary, equipment_bonuses: Dictionary, skill_bonuses: Dictionary) -> Dictionary:
	var result: Dictionary = base_stats.duplicate()
	for key: String in equipment_bonuses:
		result[key] = result.get(key, 0) + equipment_bonuses[key]
	for key: String in skill_bonuses:
		result[key] = result.get(key, 0) + skill_bonuses[key]
	return result


## Get a single stat value from derived stats dict. Returns 0 if missing.
static func get_stat(stats: Dictionary, stat_name: StringName) -> int:
	return int(stats.get(String(stat_name), 0))


## Calculate attack power: base_damage + strength * scale factor.
static func attack_power(base_damage: float, strength: int) -> float:
	return base_damage + strength * Constants.STRENGTH_DAMAGE_SCALE


## Calculate defense reduction value from defense stat.
static func defense_value(defense_stat: int) -> float:
	return defense_stat * Constants.DEFENSE_REDUCTION_SCALE


## Calculate movement speed multiplier from agility stat.
static func speed_modifier(agility: int) -> float:
	return 1.0 + agility * Constants.AGILITY_SPEED_SCALE
