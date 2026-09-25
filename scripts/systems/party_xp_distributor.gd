## Shared end-of-run XP distribution for the active party (dungeon and battlefield).
## The active character levelled in real time, so only its tracker state is synced;
## everyone else gets bulk XP, level-ups, stat growth and stat points here.
class_name PartyXPDistributor
extends RefCounted


## Process XP through level-up checks for all active party members.
## Active character already received real-time XP - just sync state.
## Non-active characters get bulk XP + base stat growth + stat points.
static func apply(player: PlayerController, xp_earned: int) -> void:
	if xp_earned <= 0:
		return
	var active_char := GameState.active_party[0] if GameState.active_party.size() > 0 else &""
	for char_id in GameState.active_party:
		if char_id not in GameState.character_data:
			continue
		var data: Dictionary = GameState.character_data[char_id]
		if char_id == active_char:
			# Active character already leveled in real-time - sync tracker state.
			data["xp"] = player.xp_tracker.get_xp()
			data["level"] = player.xp_tracker.get_level()
		else:
			# Non-active: DungeonManager already added raw XP to data["xp"].
			# Process pending level-ups from the accumulated total.
			var tracker := XPTracker.new()
			tracker.set_state(data.get("xp", 0), data.get("level", 1))
			var old_level: int = tracker.get_level()
			var points := tracker.check_level_ups()
			var new_level: int = tracker.get_level()
			var levels_gained: int = new_level - old_level
			data["xp"] = tracker.get_xp()
			data["level"] = new_level
			data["stat_points_available"] = data.get("stat_points_available", 0) + points
			# Apply base stat growth for each level gained.
			if levels_gained > 0:
				var growth: Dictionary = Constants.CHARACTER_STAT_GROWTH.get(char_id, Constants.DEFAULT_STAT_GROWTH)
				var stats: Dictionary = data.get("stats", {})
				for stat_key: StringName in growth:
					stats[stat_key] = stats.get(stat_key, 0) + growth[stat_key] * levels_gained
				data["stats"] = stats
				# Restore HP on level-up for non-active members.
				data["hp"] = data.get("max_hp", Constants.PLAYER_MAX_HP)
