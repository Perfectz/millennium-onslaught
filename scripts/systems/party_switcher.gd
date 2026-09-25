## Swap the controlled party member (Q/E, D-pad left/right). Shared by dungeon and battlefield.
class_name PartySwitcher
extends RefCounted


## Rotate the active party by `direction` (+1/-1) and reload the player. Returns true on switch.
static func switch_active(player: PlayerController, direction: int) -> bool:
	if GameState.active_party.size() <= 1:
		return false
	# Find current index.
	var current_id := GameState.active_party[0]
	var idx := GameState.active_party.find(current_id)
	var new_idx := (idx + direction) % GameState.active_party.size()
	if new_idx < 0:
		new_idx += GameState.active_party.size()
	var new_id: StringName = GameState.active_party[new_idx]
	if new_id == current_id:
		return false
	GameState.sync_character_runtime_state(
		current_id,
		player.health.get_current_hp(),
		player.health.get_max_hp(),
		player.tp_tracker.get_current_tp(),
		player.xp_tracker.get_xp(),
		player.xp_tracker.get_level()
	)
	# Rotate active_party so new character is at index 0.
	var old_id := current_id
	GameState.active_party.erase(new_id)
	GameState.active_party.push_front(new_id)
	# Reload player with new character data.
	player._load_character_from_game_state()
	EventBus.rpg_character_switched.emit(old_id, new_id)
	return true
