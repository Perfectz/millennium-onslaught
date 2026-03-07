## Unit tests for spawn clearance against environment walls.
class_name TestSpawnPositionResolver
extends GdUnitTestSuite


const SpawnPositionResolverScript := preload("res://scripts/systems/spawn_position_resolver.gd")
var _spawned_nodes: Array[Node] = []


func after_test() -> void:
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_resolve_position_keeps_clear_points_stable() -> void:
	var room := _instantiate_room("res://scenes/dungeon/rooms/academy_b2_storage.tscn")
	await get_tree().physics_frame

	var resolved: Vector3 = SpawnPositionResolverScript.resolve_position(
		room.get_world_3d(),
		Vector3(15.0, 0.0, 0.0),
		0.0,
		_get_room_width(room),
		-_get_room_depth(room) * 0.5,
		_get_room_depth(room) * 0.5,
		0.45
	)

	assert_float(resolved.x).is_equal_approx(15.0, 0.001)
	assert_float(resolved.z).is_equal_approx(0.0, 0.001)


func test_resolve_position_moves_blocked_points_off_room_walls() -> void:
	var room := _instantiate_room("res://scenes/dungeon/rooms/academy_b2_storage.tscn")
	await get_tree().physics_frame

	var room_width := _get_room_width(room)
	var room_depth := _get_room_depth(room)
	var resolved: Vector3 = SpawnPositionResolverScript.resolve_position(
		room.get_world_3d(),
		Vector3(0.0, 0.0, 0.0),
		0.0,
		room_width,
		-room_depth * 0.5,
		room_depth * 0.5,
		0.45
	)

	assert_float(resolved.x) \
		.override_failure_message("resolved spawn stayed inside the west wall: %s" % resolved) \
		.is_greater(0.45)
	assert_float(resolved.x).is_less(room_width - 0.45)


func _instantiate_room(path: String) -> Node3D:
	var scene := load(path) as PackedScene
	assert_object(scene).is_not_null()
	var room := scene.instantiate() as Node3D
	add_child(room)
	_spawned_nodes.append(room)
	return room


func _get_room_width(room: Node3D) -> float:
	var floor_shape := room.get_node("Floor/CollisionShape3D").shape as BoxShape3D
	assert_object(floor_shape).is_not_null()
	return floor_shape.size.x


func _get_room_depth(room: Node3D) -> float:
	var floor_shape := room.get_node("Floor/CollisionShape3D").shape as BoxShape3D
	assert_object(floor_shape).is_not_null()
	return floor_shape.size.z
