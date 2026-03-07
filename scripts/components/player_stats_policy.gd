## Pure helpers for resolving player base stats, derived stats, and HP scaling.
class_name PlayerStatsPolicy
extends RefCounted


const DEFAULT_BASE_STATS := {
	"strength": 5,
	"magic": 5,
	"defense": 5,
	"agility": 5,
}


static func resolve_base_stats(
	character_id: StringName,
	character_data: Dictionary,
	fallback_base_stats: Dictionary = {}
) -> Dictionary:
	var data := character_data.get(character_id, {}) as Dictionary
	if not data.is_empty():
		var stored_stats := data.get("stats", {}) as Dictionary
		if not stored_stats.is_empty():
			return stored_stats.duplicate(true)
	if not fallback_base_stats.is_empty():
		return fallback_base_stats.duplicate(true)
	return DEFAULT_BASE_STATS.duplicate(true)


static func build_derived_stats(
	base_stats: Dictionary,
	equipment_bonuses: Dictionary,
	defense_bonus: float = 0.0,
	skill_bonuses: Dictionary = {}
) -> Dictionary:
	var derived := StatCalculator.calculate_derived(base_stats, equipment_bonuses, skill_bonuses)
	if defense_bonus > 0.0:
		derived["defense"] = int(derived.get("defense", 0)) + int(defense_bonus)
	return derived


static func build_health_refresh(
	current_hp: float,
	derived_stats: Dictionary,
	base_hp: float,
	stat_hp_scale: float
) -> Dictionary:
	var max_hp := maxf(base_hp + StatCalculator.get_stat(derived_stats, &"defense") * stat_hp_scale, 0.0)
	return {
		"max_hp": max_hp,
		"current_hp": clampf(current_hp, 0.0, max_hp),
	}
