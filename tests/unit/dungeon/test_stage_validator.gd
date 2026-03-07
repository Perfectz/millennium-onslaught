## Regression coverage for StageValidator runtime layout checks.
class_name TestStageValidator
extends GdUnitTestSuite


const CORRIDORS_PATH := "res://scenes/dungeon/rooms/academy_b1_corridors.tscn"
const STORAGE_PATH := "res://scenes/dungeon/rooms/academy_b2_storage.tscn"
const BOSS_PATH := "res://scenes/dungeon/rooms/academy_b3_boss.tscn"

var _spawned_nodes: Array[Node] = []


func after_test() -> void:
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_audit_stage_accepts_current_academy_layout() -> void:
	var stage := load("res://resources/stages/academy_b3.tres") as StageDef
	assert_object(stage).is_not_null()

	var audit: Dictionary = StageValidator.audit_stage(stage)
	assert_array(audit.get("errors", [])).is_empty()


func test_audit_stage_flags_non_stage_chunk_layouts() -> void:
	var stage := StageDef.new()
	stage.stage_id = &"invalid_layout"
	stage.stage_name = "Invalid Layout"
	stage.chunk_scenes = ["res://scenes/ui/title_screen.tscn"]
	stage.chunk_width = 30.0

	var audit: Dictionary = StageValidator.audit_stage(stage)
	var joined := " ".join(audit.get("errors", []))
	assert_bool("missing Floor/CollisionShape3D" in joined).is_true()


func test_audit_chunk_layout_flags_blocked_exit_lanes() -> void:
	var room := _instantiate_scene(BOSS_PATH) as Node3D
	var boundary := room.get_node("EastBoundaryNorth") as StaticBody3D
	assert_object(boundary).is_not_null()
	var boundary_transform := boundary.transform
	boundary_transform.origin.z = 2.0
	boundary.transform = boundary_transform

	var audit: Dictionary = StageValidator.audit_chunk_layout(room, {
		"path": BOSS_PATH,
		"expected_width": 36.0,
		"chunk_index": 2,
		"total_chunks": 3,
	})
	var joined := " ".join(audit.get("errors", []))
	assert_bool("exit lane is blocked" in joined).is_true()


func test_audit_chunk_layout_flags_open_side_blockers() -> void:
	var room := _instantiate_scene(CORRIDORS_PATH) as Node3D
	var visuals := room.get_node("Visuals") as Node3D
	assert_object(visuals).is_not_null()

	var blocker := Node3D.new()
	blocker.name = "InjectedCrate"
	var blocker_transform := blocker.transform
	blocker_transform.origin = Vector3(26.5, 0.0, 0.0)
	blocker.transform = blocker_transform
	visuals.add_child(blocker)

	var audit: Dictionary = StageValidator.audit_chunk_layout(room, {
		"path": CORRIDORS_PATH,
		"expected_width": 30.0,
		"chunk_index": 0,
		"total_chunks": 2,
	})
	var joined := " ".join(audit.get("errors", []))
	assert_bool("east seam approach is blocked" in joined).is_true()


func test_audit_chunk_seam_flags_floor_offset_regressions() -> void:
	var left_room := _instantiate_scene(CORRIDORS_PATH)
	var right_room := _instantiate_scene(STORAGE_PATH)
	var floor := right_room.get_node("Floor") as Node3D
	assert_object(floor).is_not_null()

	var floor_transform := floor.transform
	floor_transform.origin.z = 1.5
	floor.transform = floor_transform

	var audit: Dictionary = StageValidator.audit_chunk_seam(left_room, right_room, {
		"left_path": CORRIDORS_PATH,
		"right_path": STORAGE_PATH,
	})
	var joined := " ".join(audit.get("errors", []))
	assert_bool("center.z mismatch" in joined).is_true()


func _instantiate_scene(path: String) -> Node:
	var scene := load(path) as PackedScene
	assert_object(scene).is_not_null()
	var node := scene.instantiate()
	add_child(node)
	_spawned_nodes.append(node)
	return node
