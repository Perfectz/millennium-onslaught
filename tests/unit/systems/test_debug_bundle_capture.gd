## Regression coverage for runtime debug bundle capture.
class_name TestDebugBundleCapture
extends GdUnitTestSuite


const PlayerScene := preload("res://scenes/characters/player.tscn")
const DebugBundleCaptureScript := preload("res://scripts/tools/debug_bundle_capture.gd")

var _spawned_nodes: Array[Node] = []
var _bundle_paths: Array[String] = []


func after_test() -> void:
	for path in _bundle_paths:
		if path != "" and FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_bundle_paths.clear()
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_capture_bundle_includes_runtime_sections() -> void:
	GameState.start_new_game()
	RuntimeState.current_phase = &"dungeon"
	EventBus.log_event(&"bundle_test", {"position": Vector3(1.0, 2.0, 3.0)})
	var root: Node3D = await _spawn_root_with_player()
	var bundle_capture := DebugBundleCaptureScript.new()

	var bundle: Dictionary = bundle_capture.capture_bundle(root, &"test_capture")
	assert_str(String(bundle.get("reason", ""))).is_equal("test_capture")
	assert_bool(bundle.has("game_state")).is_true()
	assert_bool(bundle.has("input")).is_true()
	assert_bool(bundle.has("recent_events")).is_true()

	var player_snapshot := bundle.get("player", {}) as Dictionary
	assert_bool(player_snapshot.has("hp")).is_true()
	assert_bool(player_snapshot.has("position")).is_true()
	assert_str(String(player_snapshot.get("character_id", ""))).is_equal("alys")


func test_write_bundle_persists_json_file() -> void:
	GameState.start_new_game()
	var root: Node3D = await _spawn_root_with_player()
	var bundle_capture := DebugBundleCaptureScript.new()

	var path: String = bundle_capture.write_bundle(root, &"unit_test")
	_bundle_paths.append(path)

	assert_bool(path != "").is_true()
	assert_bool(FileAccess.file_exists(path)).is_true()
	var contents := FileAccess.get_file_as_string(path)
	assert_bool("\"reason\": \"unit_test\"" in contents).is_true()


func _spawn_root_with_player() -> Node3D:
	var root := Node3D.new()
	add_child(root)
	_spawned_nodes.append(root)

	var player := PlayerScene.instantiate() as PlayerController
	root.add_child(player)
	_spawned_nodes.append(player)
	await get_tree().physics_frame
	return root
