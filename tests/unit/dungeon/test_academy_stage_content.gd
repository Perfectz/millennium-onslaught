## Regression tests for the KayKit-backed Piata academy stage flow.
class_name TestAcademyStageContent
extends GdUnitTestSuite


const StageRunnerScript := preload("res://scripts/dungeon/stage_runner.gd")
const ACADEMY_B1_PATH := "res://resources/stages/academy_b1.tres"
const ACADEMY_B2_PATH := "res://resources/stages/academy_b2.tres"
const ACADEMY_B3_PATH := "res://resources/stages/academy_b3.tres"
const DUNGEON_1_PATH := "res://resources/dungeons/dungeon_1.tres"
const ACADEMY_ROOM_PATHS := [
	"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
	"res://scenes/dungeon/rooms/academy_b1_corridors.tscn",
	"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
	"res://scenes/dungeon/rooms/academy_b2_library.tscn",
	"res://scenes/dungeon/rooms/academy_b3_gauntlet.tscn",
	"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
]

var _spawned_nodes: Array[Node] = []


func after_test() -> void:
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_academy_stage_defs_validate() -> void:
	for path in [ACADEMY_B1_PATH, ACADEMY_B2_PATH, ACADEMY_B3_PATH]:
		var stage := load(path) as StageDef
		assert_object(stage).is_not_null()
		assert_array(stage.validate()).is_empty()


func test_dungeon_1_uses_academy_multi_stage_flow() -> void:
	var dungeon := load(DUNGEON_1_PATH) as DungeonDef
	assert_object(dungeon).is_not_null()
	assert_object(dungeon.stage_def).is_null()
	assert_array(dungeon.stage_defs).has_size(3)
	assert_array(dungeon.stage_defs).contains_exactly([
		load(ACADEMY_B1_PATH),
		load(ACADEMY_B2_PATH),
		load(ACADEMY_B3_PATH),
	])


func test_floor_two_and_three_use_extended_chunk_sequences() -> void:
	var floor_two := load(ACADEMY_B2_PATH) as StageDef
	var floor_three := load(ACADEMY_B3_PATH) as StageDef
	assert_int(floor_two.chunk_scenes.size()).is_equal(2)
	assert_int(floor_three.chunk_scenes.size()).is_equal(3)
	assert_array(floor_two.chunk_scenes).contains_exactly([
		"res://scenes/dungeon/rooms/academy_b1_corridors.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
	])
	assert_array(floor_three.chunk_scenes).contains_exactly([
		"res://scenes/dungeon/rooms/academy_b2_library.tscn",
		"res://scenes/dungeon/rooms/academy_b3_gauntlet.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	])


func test_only_final_chunk_exposes_stage_exit_area() -> void:
	var floor_two := load(ACADEMY_B2_PATH) as StageDef
	var floor_three := load(ACADEMY_B3_PATH) as StageDef
	assert_object(_instantiate_scene(floor_two.chunk_scenes[0]).get_node_or_null("StageExitArea")).is_null()
	assert_object(_instantiate_scene(floor_two.chunk_scenes[1]).get_node_or_null("StageExitArea")).is_not_null()
	assert_object(_instantiate_scene(floor_three.chunk_scenes[0]).get_node_or_null("StageExitArea")).is_null()
	assert_object(_instantiate_scene(floor_three.chunk_scenes[1]).get_node_or_null("StageExitArea")).is_null()
	assert_object(_instantiate_scene(floor_three.chunk_scenes[2]).get_node_or_null("StageExitArea")).is_not_null()


func test_stage_exit_area_targets_player_collision_layer() -> void:
	for path in [
		"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	]:
		var room := _instantiate_scene(path)
		var exit_area := room.get_node_or_null("StageExitArea") as Area3D
		assert_object(exit_area).is_not_null()
		assert_int(exit_area.collision_mask).is_equal(Constants.LAYER_PLAYER)
		assert_bool(exit_area.monitoring).is_true()
		assert_bool(exit_area.monitorable).is_true()


func test_stage_exit_area_aligns_with_doorway_lane() -> void:
	for path in [
		"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	]:
		var room := _instantiate_scene(path)
		var exit_area := room.get_node_or_null("StageExitArea") as Area3D
		assert_object(exit_area).is_not_null()
		assert_float(exit_area.transform.origin.z) \
			.override_failure_message("%s exit is not aligned with the doorway lane" % path) \
			.is_equal(2.0)


func test_stage_exit_lane_is_not_blocked_by_boundary_collision() -> void:
	for path in [
		"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	]:
		var room := _instantiate_scene(path)
		var exit_area := room.get_node_or_null("StageExitArea") as Area3D
		assert_object(exit_area).is_not_null()
		var blocked_by: Array[String] = []
		var exit_z := exit_area.transform.origin.z
		for child in room.get_children():
			if child is StaticBody3D and String(child.name).begins_with("EastBoundary"):
				var boundary := child as StaticBody3D
				var shape := boundary.get_node("CollisionShape3D").shape as BoxShape3D
				assert_object(shape).is_not_null()
				var half_z := shape.size.z * 0.5
				var min_z := boundary.transform.origin.z - half_z
				var max_z := boundary.transform.origin.z + half_z
				if exit_z >= min_z and exit_z <= max_z:
					blocked_by.append(String(boundary.name))
		assert_array(blocked_by) \
			.override_failure_message("%s exit lane is blocked by %s" % [path, blocked_by]) \
			.is_empty()


func test_stage_exit_approach_stays_clear_of_major_props() -> void:
	for path in [
		"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	]:
		var room := _instantiate_scene(path)
		var room_width := _get_room_width(room)
		var exit_area := room.get_node_or_null("StageExitArea") as Area3D
		assert_object(exit_area).is_not_null()
		var exit_z := exit_area.transform.origin.z
		var visuals := room.get_node("Visuals") as Node3D
		assert_object(visuals).is_not_null()
		var blockers: Array[String] = []
		for child in visuals.get_children():
			if child is Node3D and _is_major_prop(child.name):
				var prop := child as Node3D
				var origin := prop.transform.origin
				var in_exit_lane := origin.x >= room_width - 8.0 and absf(origin.z - exit_z) <= 2.5
				if in_exit_lane:
					blockers.append("%s@%s" % [child.name, origin])
		assert_array(blockers) \
			.override_failure_message("%s exit approach is blocked by %s" % [path, blockers]) \
			.is_empty()


func test_open_chunk_connections_keep_seam_approaches_clear_of_major_props() -> void:
	for case in [
		{"path": "res://scenes/dungeon/rooms/academy_b1_corridors.tscn", "sides": ["east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b2_storage.tscn", "sides": ["west"]},
		{"path": "res://scenes/dungeon/rooms/academy_b2_library.tscn", "sides": ["east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b3_gauntlet.tscn", "sides": ["west", "east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b3_boss.tscn", "sides": ["west"]},
	]:
		var room := _instantiate_scene(case["path"])
		var room_width := _get_room_width(room)
		for side in case["sides"]:
			var blockers := _collect_major_props_in_seam_zone(room, room_width, side)
			assert_array(blockers) \
				.override_failure_message("%s %s seam approach is blocked by %s" % [case["path"], side, blockers]) \
				.is_empty()


func test_stage_exit_area_starts_after_final_arena_bounds() -> void:
	for path in [ACADEMY_B1_PATH, ACADEMY_B2_PATH, ACADEMY_B3_PATH]:
		_assert_stage_exit_starts_after_final_arena(path)


func test_major_props_stay_out_of_central_combat_lane() -> void:
	for path in ACADEMY_ROOM_PATHS:
		var room := _instantiate_scene(path)
		var room_width := _get_room_width(room)
		var visuals := room.get_node("Visuals") as Node3D
		assert_object(visuals).is_not_null()
		for child in visuals.get_children():
			if child is Node3D and _is_major_prop(child.name):
				var prop := child as Node3D
				var origin := prop.transform.origin
				var outside_lane := absf(origin.z) >= 5.0 or origin.x <= 4.0 or origin.x >= room_width - 4.0
				assert_bool(outside_lane) \
					.override_failure_message("%s places %s in the combat lane at %s" % [path, child.name, origin]) \
					.is_true()


func test_route_markers_highlight_open_connections() -> void:
	for case in [
		{"path": "res://scenes/dungeon/rooms/academy_b1_corridors.tscn", "sides": ["east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b2_storage.tscn", "sides": ["west"]},
		{"path": "res://scenes/dungeon/rooms/academy_b2_library.tscn", "sides": ["east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b3_gauntlet.tscn", "sides": ["west", "east"]},
		{"path": "res://scenes/dungeon/rooms/academy_b3_boss.tscn", "sides": ["west"]},
	]:
		var room := _instantiate_scene(case["path"])
		var room_width := _get_room_width(room)
		for side in case["sides"]:
			var marker_count := _count_route_markers_in_seam_zone(room, room_width, side)
			assert_int(marker_count) \
				.override_failure_message("%s %s seam is missing route markers" % [case["path"], side]) \
				.is_greater_equal(2)


func test_stage_exit_rooms_highlight_the_exit_lane() -> void:
	for path in [
		"res://scenes/dungeon/rooms/academy_b1_entry.tscn",
		"res://scenes/dungeon/rooms/academy_b2_storage.tscn",
		"res://scenes/dungeon/rooms/academy_b3_boss.tscn",
	]:
		var room := _instantiate_scene(path)
		var room_width := _get_room_width(room)
		var exit_area := room.get_node_or_null("StageExitArea") as Area3D
		assert_object(exit_area).is_not_null()
		var exit_z := exit_area.transform.origin.z
		var marker_count := _count_route_markers(room, room_width - 10.0, room_width, exit_z - 2.5, exit_z + 2.5)
		assert_int(marker_count) \
			.override_failure_message("%s exit lane is missing grate markers" % path) \
			.is_greater_equal(2)
		var exit_torches := _find_named_visual_nodes(room, "ExitTorch")
		assert_int(exit_torches.size()) \
			.override_failure_message("%s exit is missing guide torches" % path) \
			.is_equal(2)


func test_stage_runner_opens_internal_chunk_connections_for_multi_chunk_stages() -> void:
	var runner := StageRunnerScript.new()
	add_child(runner)
	_spawned_nodes.append(runner)

	var corridors := _instantiate_scene("res://scenes/dungeon/rooms/academy_b1_corridors.tscn") as Node3D
	var storage := _instantiate_scene("res://scenes/dungeon/rooms/academy_b2_storage.tscn") as Node3D
	var gauntlet := _instantiate_scene("res://scenes/dungeon/rooms/academy_b3_gauntlet.tscn") as Node3D

	runner._configure_chunk_connections(corridors, 0, 2)
	runner._configure_chunk_connections(storage, 1, 2)
	runner._configure_chunk_connections(gauntlet, 1, 3)

	assert_object(corridors.get_node_or_null("EastBoundary")).is_null()
	assert_int(_count_visual_side_nodes(corridors, "eastwall")).is_equal(0)

	assert_object(storage.get_node_or_null("WestBoundary")).is_null()
	assert_int(_count_visual_side_nodes(storage, "westwall")).is_equal(0)

	assert_object(gauntlet.get_node_or_null("WestBoundary")).is_null()
	assert_object(gauntlet.get_node_or_null("EastBoundary")).is_null()
	assert_int(_count_visual_side_nodes(gauntlet, "westwall")).is_equal(0)
	assert_int(_count_visual_side_nodes(gauntlet, "eastwall")).is_equal(0)


func _instantiate_scene(path: String) -> Node:
	var scene := load(path) as PackedScene
	assert_object(scene).is_not_null()
	var node := scene.instantiate()
	add_child(node)
	_spawned_nodes.append(node)
	return node


func _assert_stage_exit_starts_after_final_arena(path: String) -> void:
	var stage := load(path) as StageDef
	assert_object(stage).is_not_null()
	var final_chunk_index := stage.chunk_scenes.size() - 1
	var room := _instantiate_scene(stage.chunk_scenes[final_chunk_index])
	var exit_area := room.get_node_or_null("StageExitArea") as Area3D
	assert_object(exit_area).is_not_null()
	var exit_shape := exit_area.get_node("CollisionShape3D").shape as BoxShape3D
	assert_object(exit_shape).is_not_null()
	var final_encounter := stage.encounters[stage.encounters.size() - 1] as StageEncounterEntry
	assert_object(final_encounter).is_not_null()
	var exit_start_x := stage.chunk_width * final_chunk_index + exit_area.transform.origin.x - (exit_shape.size.x * 0.5)
	var arena_max_x := final_encounter.trigger_x + final_encounter.arena_half_width
	assert_float(exit_start_x) \
		.override_failure_message("%s exit starts inside final arena: %.2f <= %.2f" % [path, exit_start_x, arena_max_x]) \
		.is_greater(arena_max_x)


func _get_room_width(room: Node) -> float:
	var floor_shape := room.get_node("Floor/CollisionShape3D").shape as BoxShape3D
	assert_object(floor_shape).is_not_null()
	return floor_shape.size.x


func _is_major_prop(node_name: StringName) -> bool:
	var name_str := String(node_name)
	var lower_name := name_str.to_lower()
	return not (
		lower_name.begins_with("floortile")
		or lower_name.contains("wall")
		or lower_name.begins_with("torch")
		or lower_name.contains("banner")
		or lower_name.ends_with("light")
		or lower_name.ends_with("stairs")
	)


func _count_visual_side_nodes(room: Node, side_prefix: String) -> int:
	var visuals := room.get_node("Visuals") as Node3D
	assert_object(visuals).is_not_null()
	var count := 0
	for child in visuals.get_children():
		var child_name := String(child.name).to_lower()
		if child_name.begins_with(side_prefix):
			count += 1
	return count


func _collect_major_props_in_seam_zone(room: Node, room_width: float, side: String) -> Array[String]:
	var visuals := room.get_node("Visuals") as Node3D
	assert_object(visuals).is_not_null()
	var blockers: Array[String] = []
	for child in visuals.get_children():
		if child is Node3D and _is_major_prop(child.name):
			var origin := (child as Node3D).transform.origin
			var in_side_band := false
			if side == "west":
				in_side_band = origin.x <= 6.0
			elif side == "east":
				in_side_band = origin.x >= room_width - 6.0
			if in_side_band and absf(origin.z) <= 4.5:
				blockers.append("%s@%s" % [child.name, origin])
	return blockers


func _count_route_markers_in_seam_zone(room: Node, room_width: float, side: String) -> int:
	if side == "west":
		return _count_route_markers(room, 0.0, 8.0, -4.5, 4.5)
	if side == "east":
		return _count_route_markers(room, room_width - 8.0, room_width, -4.5, 4.5)
	return 0


func _count_route_markers(room: Node, min_x: float, max_x: float, min_z: float, max_z: float) -> int:
	var visuals := room.get_node("Visuals") as Node3D
	assert_object(visuals).is_not_null()
	var count := 0
	for child in visuals.get_children():
		if not (child is Node3D):
			continue
		if not String(child.name).begins_with("FloorTile"):
			continue
		var scene_path := child.scene_file_path
		if not scene_path.contains("floor_tile_big_grate"):
			continue
		var origin := (child as Node3D).transform.origin
		if origin.x >= min_x and origin.x <= max_x and origin.z >= min_z and origin.z <= max_z:
			count += 1
	return count


func _find_named_visual_nodes(room: Node, name_prefix: String) -> Array[Node3D]:
	var visuals := room.get_node("Visuals") as Node3D
	assert_object(visuals).is_not_null()
	var matches: Array[Node3D] = []
	for child in visuals.get_children():
		var child_name := String(child.name)
		if child is Node3D and child_name.begins_with(name_prefix) and not child_name.ends_with("Light"):
			matches.append(child as Node3D)
	return matches
