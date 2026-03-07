## Pure helpers for resolving and synchronizing player profile/runtime state.
class_name PlayerProfilePolicy
extends RefCounted


static func resolve_active_character_id(
	active_party: Array[StringName],
	player_index: int,
	fallback: StringName = &"alys"
) -> StringName:
	if active_party.is_empty():
		return fallback
	return active_party[mini(maxi(player_index, 0), active_party.size() - 1)]


static func compute_max_hp(derived_stats: Dictionary, base_hp: float, stat_hp_scale: float) -> float:
	return base_hp + StatCalculator.get_stat(derived_stats, &"defense") * stat_hp_scale


static func build_restore_snapshot(
	character_id: StringName,
	data: Dictionary,
	character_defs: Dictionary,
	derived_stats: Dictionary,
	base_hp: float,
	tp_max: float,
	stat_hp_scale: float
) -> Dictionary:
	var max_hp := maxf(compute_max_hp(derived_stats, base_hp, stat_hp_scale), 0.0)
	return {
		"character_id": String(character_id),
		"character_def_path": String(character_defs.get(character_id, "")),
		"xp": int(data.get("xp", 0)),
		"level": maxi(int(data.get("level", 1)), 1),
		"tp": clampf(float(data.get("tp", tp_max)), 0.0, tp_max),
		"saved_hp": clampf(float(data.get("hp", base_hp)), 0.0, max_hp),
		"max_hp": max_hp,
	}


static func build_runtime_sync_payload(
	character_id: StringName,
	hp: float,
	max_hp: float,
	tp: float,
	xp: int,
	level: int,
	tp_max: float,
	stat_points_available: int = -1
) -> Dictionary:
	var payload := {
		"character_id": String(character_id),
		"hp": clampf(hp, 0.0, maxf(max_hp, 0.0)),
		"max_hp": maxf(max_hp, 0.0),
		"tp": clampf(tp, 0.0, tp_max),
		"xp": maxi(xp, 0),
		"level": maxi(level, 1),
	}
	if stat_points_available >= 0:
		payload["stat_points_available"] = maxi(stat_points_available, 0)
	return payload


static func build_level_up_record(
	data: Dictionary,
	character_id: StringName,
	new_level: int,
	stat_points: int,
	growth_map: Dictionary,
	default_growth: Dictionary
) -> Dictionary:
	var updated := data.duplicate(true)
	updated["level"] = maxi(new_level, 1)
	updated["stat_points_available"] = int(updated.get("stat_points_available", 0)) + maxi(stat_points, 0)

	var growth := growth_map.get(character_id, default_growth) as Dictionary
	var stats := (updated.get("stats", {}) as Dictionary).duplicate(true)
	for stat_key: StringName in growth:
		stats[stat_key] = int(stats.get(stat_key, 0)) + int(growth[stat_key])
	updated["stats"] = stats
	return updated
