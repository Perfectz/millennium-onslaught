## Global signal hub. All cross-system communication flows through here.
## No system directly references another system — they emit and listen via EventBus.
class_name EventBusSingleton
extends Node


# --- Lifecycle ---
signal game_phase_changed(new_phase: StringName, old_phase: StringName)
signal game_paused()
signal game_resumed()
signal game_restarted()

# --- Combat ---
signal combat_hit_landed(attacker: Node, target: Node, damage: float, hit_position: Vector3)
signal combat_kill(attacker: Node, target: Node, kill_position: Vector3)
signal combat_combo_step(player: Node, step: int)
signal combat_combo_dropped(player: Node)
signal combat_dodge(player: Node)
signal combat_block(player: Node)
signal combat_parry(player: Node, attacker: Node)
signal combat_technique_used(player: Node, technique_name: StringName, cost: float)

# --- Juggle ---
signal combat_juggle_launched(target: Node, launcher: Node)
signal combat_juggle_hit(target: Node, hit_count: int)
signal combat_juggle_limit_reached(target: Node)

# --- Player ---
signal player_health_changed(player_index: int, new_hp: float, max_hp: float)
signal player_tp_changed(player_index: int, new_tp: float, max_tp: float)
signal player_died(player_index: int)
signal player_revived(player_index: int)

# --- Enemy ---
signal enemy_spawned(enemy: Node, enemy_type: StringName)
signal enemy_died(enemy: Node, enemy_type: StringName, position: Vector3)
signal enemy_wave_cleared()

# --- Dungeon ---
signal dungeon_entered(dungeon_id: StringName)
signal dungeon_room_entered(room_index: int)
signal dungeon_room_cleared(room_index: int)
signal dungeon_boss_phase_changed(boss: Node, phase: int)
signal dungeon_completed(dungeon_id: StringName)
signal dungeon_failed()

# --- Overworld ---
signal overworld_node_selected(node_id: StringName)
signal overworld_node_entered(node_id: StringName)
signal overworld_node_unlocked(node_id: StringName)

# --- Town ---
signal town_entered(town_id: StringName)
signal town_shop_purchase(item_id: StringName, cost: int)
signal town_shop_sell(item_id: StringName, price: int)
signal town_inn_used(cost: int)
signal town_exited()

# --- RPG ---
signal rpg_xp_gained(player_index: int, amount: int)
signal rpg_level_up(player_index: int, new_level: int)
signal rpg_stat_allocated(player_index: int, stat_name: StringName, new_value: int)
signal rpg_equipment_changed(player_index: int, slot: StringName, item_id: StringName)
signal rpg_gold_changed(new_total: int)
signal rpg_skill_unlocked(player_index: int, skill_id: StringName)

# --- Save/Load ---
signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)

# --- Scene ---
signal scene_transition_started(target_scene: String)
signal scene_transition_completed(target_scene: String)

# --- Audio ---
signal audio_sfx_requested(sfx_name: StringName)
signal audio_music_requested(music_name: StringName, crossfade: bool)
signal audio_mute_toggled(muted: bool)

# --- UI ---
signal ui_hud_update_requested()
signal ui_menu_opened(menu_name: StringName)
signal ui_menu_closed(menu_name: StringName)

# --- Input ---
signal input_device_connected(device_id: int)
signal input_device_disconnected(device_id: int)
signal input_context_changed(new_context: StringName)


## Ring buffer for debugging — stores last 100 events for crash investigation.
var _event_ring_buffer: Array[Dictionary] = []
const _RING_BUFFER_SIZE: int = 100


## Log an event to the ring buffer for debugging purposes.
func log_event(event_name: StringName, payload: Dictionary = {}) -> void:
	var entry := {
		"time": Time.get_ticks_msec(),
		"event": event_name,
		"payload": payload
	}
	_event_ring_buffer.append(entry)
	if _event_ring_buffer.size() > _RING_BUFFER_SIZE:
		_event_ring_buffer.pop_front()


## Get the last N events from the ring buffer.
func get_recent_events(count: int = 20) -> Array[Dictionary]:
	var start := maxi(0, _event_ring_buffer.size() - count)
	return _event_ring_buffer.slice(start)


## Dump all buffered events as JSON string for debugging.
func dump_events_json() -> String:
	return JSON.stringify(_event_ring_buffer, "\t")
