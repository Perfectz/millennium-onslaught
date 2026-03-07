## Captures JSON-safe runtime snapshots for bug repro and AI debugging.
class_name DebugBundleCapture
extends RefCounted


const OUTPUT_DIR := "user://debug_bundles"
const MAX_RECENT_EVENTS := 20
const MAX_ENEMIES_CAPTURED := 24


## Build a runtime snapshot without writing it to disk.
func capture_bundle(scene_root: Node, reason: StringName = &"manual") -> Dictionary:
	var tree := scene_root.get_tree() if scene_root != null else null
	var current_scene := tree.current_scene if tree != null and tree.current_scene != null else scene_root
	var search_root := scene_root if scene_root != null else current_scene
	var raw_bundle := {
		"captured_at_unix": Time.get_unix_time_from_system(),
		"captured_at_local": Time.get_datetime_string_from_system(),
		"reason": String(reason),
		"scene": _collect_scene_snapshot(current_scene),
		"game_state": _collect_game_state_snapshot(),
		"input": InputManager.get_debug_snapshot(),
		"recent_events": EventBus.get_recent_events(MAX_RECENT_EVENTS),
		"player": _collect_player_snapshot(search_root),
		"stage_runner": _collect_named_snapshot(search_root, "StageRunner"),
		"wave_system": _collect_named_snapshot(search_root, "WaveSystem"),
		"enemies": _collect_enemy_snapshots(tree),
	}
	return _normalize_variant(raw_bundle) as Dictionary


## Write a runtime snapshot to user://debug_bundles and return the absolute path.
func write_bundle(scene_root: Node, reason: StringName = &"manual") -> String:
	if scene_root == null:
		return ""
	var bundle := capture_bundle(scene_root, reason)
	_ensure_output_dir()
	var filename := "%s_%s.json" % [_timestamp_slug(), String(reason)]
	var bundle_path := "%s/%s" % [OUTPUT_DIR, filename]
	var file := FileAccess.open(bundle_path, FileAccess.WRITE)
	if file == null:
		push_error("DebugBundleCapture: failed to open '%s' for writing." % bundle_path)
		return ""
	file.store_string(JSON.stringify(bundle, "\t"))
	file.close()
	return ProjectSettings.globalize_path(bundle_path)


func _collect_scene_snapshot(scene_root: Node) -> Dictionary:
	if scene_root == null:
		return {}
	return {
		"name": scene_root.name,
		"scene_file_path": scene_root.scene_file_path,
	}


func _collect_game_state_snapshot() -> Dictionary:
	return RuntimeState.get_debug_snapshot()


func _collect_player_snapshot(scene_root: Node) -> Dictionary:
	if scene_root == null:
		return {}
	var player := scene_root as PlayerController
	if player == null:
		player = scene_root.find_child("Player", true, false) as PlayerController
	if player == null:
		for candidate in scene_root.find_children("*", "", true, false):
			if candidate is PlayerController:
				player = candidate as PlayerController
				break
	if player == null:
		return {}
	var character_id := &""
	if player.player_index < GameState.active_party.size():
		character_id = GameState.active_party[player.player_index]
	var technique_id := &""
	var active_technique := player.get_active_technique()
	if active_technique != null:
		technique_id = active_technique.technique_id
	return {
		"character_id": String(character_id),
		"player_index": player.player_index,
		"position": player.global_position,
		"velocity": player.velocity,
		"state": String(player.state_machine.current_state_name) if player.state_machine != null else "",
		"hp": player.health.get_current_hp() if player.health != null else 0.0,
		"max_hp": player.health.get_max_hp() if player.health != null else 0.0,
		"tp": player.tp_tracker.get_current_tp() if player.tp_tracker != null else 0.0,
		"max_tp": player.tp_tracker.get_max_tp() if player.tp_tracker != null else 0.0,
		"active_technique_id": String(technique_id),
		"lock_target": player.lock_target.name if is_instance_valid(player.lock_target) else "",
	}


func _collect_named_snapshot(scene_root: Node, node_name: String) -> Dictionary:
	if scene_root == null:
		return {}
	var node := scene_root.find_child(node_name, true, false)
	if node == null:
		return {}
	if node.has_method("get_debug_snapshot"):
		return node.get_debug_snapshot()
	return {
		"name": node.name,
		"type": node.get_class(),
	}


func _collect_enemy_snapshots(tree: SceneTree) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	if tree == null:
		return snapshots
	var enemies := tree.get_nodes_in_group(&"enemies")
	for index in range(mini(enemies.size(), MAX_ENEMIES_CAPTURED)):
		var enemy := enemies[index] as EnemyController
		if enemy == null or not is_instance_valid(enemy):
			continue
		snapshots.append({
			"name": enemy.name,
			"enemy_type": enemy.enemy_type,
			"position": enemy.global_position,
			"velocity": enemy.velocity,
			"state": enemy.state_machine.current_state_name if enemy.state_machine != null else &"",
			"hp": enemy.health.get_current_hp() if enemy.health != null else 0.0,
			"max_hp": enemy.health.get_max_hp() if enemy.health != null else 0.0,
		})
	return snapshots


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _timestamp_slug() -> String:
	var timestamp := Time.get_datetime_string_from_system()
	return timestamp.replace(":", "-").replace(" ", "_")


func _normalize_variant(value: Variant) -> Variant:
	if value is String or value is int or value is float or value is bool:
		return value
	if value == null:
		return null
	if value is StringName:
		return String(value)
	if value is Vector2:
		var v2 := value as Vector2
		return {"x": v2.x, "y": v2.y}
	if value is Vector3:
		var v3 := value as Vector3
		return {"x": v3.x, "y": v3.y, "z": v3.z}
	if value is Array:
		var normalized_array: Array = []
		for entry in value:
			normalized_array.append(_normalize_variant(entry))
		return normalized_array
	if value is Dictionary:
		var normalized_dict := {}
		for key in value:
			normalized_dict[String(key)] = _normalize_variant(value[key])
		return normalized_dict
	if value is Node:
		var node := value as Node
		return {
			"name": node.name,
			"type": node.get_class(),
		}
	return str(value)
