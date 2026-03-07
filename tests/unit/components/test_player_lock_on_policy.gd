## Pure regression coverage for player lock-on candidate filtering and cycling.
class_name TestPlayerLockOnPolicy
extends GdUnitTestSuite


const PlayerLockOnPolicyScript := preload("res://scripts/components/player_lock_on_policy.gd")


var _policy
var _root: Node3D
var _spawned: Array[Node] = []


func before_test() -> void:
	_policy = PlayerLockOnPolicyScript.new()
	_root = Node3D.new()
	add_child(_root)
	_spawned.append(_root)


func after_test() -> void:
	for idx in range(_spawned.size() - 1, -1, -1):
		var node := _spawned[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()


func test_select_nearest_returns_closest_alive_enemy_in_range() -> void:
	var near_enemy := _spawn_enemy(Vector3(3.0, 0.0, 0.0))
	var far_enemy := _spawn_enemy(Vector3(8.0, 0.0, 0.0))

	var target: Node3D = _policy.select_nearest(Vector3.ZERO, [near_enemy, far_enemy], 100.0)

	assert_object(target).is_equal(near_enemy)


func test_select_nearest_ignores_non_character_nodes_and_out_of_range_candidates() -> void:
	var prop := Node3D.new()
	_root.add_child(prop)
	_spawned.append(prop)
	prop.position = Vector3(1.0, 0.0, 0.0)

	var far_enemy := _spawn_enemy(Vector3(8.0, 0.0, 0.0))

	var target: Node3D = _policy.select_nearest(Vector3.ZERO, [prop, far_enemy], 16.0)

	assert_object(target).is_null()


func test_select_next_skips_current_target() -> void:
	var near_enemy := _spawn_enemy(Vector3(3.0, 0.0, 0.0))
	var far_enemy := _spawn_enemy(Vector3(6.0, 0.0, 0.0))

	var next_target: Node3D = _policy.select_next(Vector3.ZERO, near_enemy, [near_enemy, far_enemy], 100.0)

	assert_object(next_target).is_equal(far_enemy)


func test_select_next_returns_null_when_no_other_target_is_available() -> void:
	var only_enemy := _spawn_enemy(Vector3(3.0, 0.0, 0.0))

	var next_target: Node3D = _policy.select_next(Vector3.ZERO, only_enemy, [only_enemy], 100.0)

	assert_object(next_target).is_null()


func _spawn_enemy(pos: Vector3) -> CharacterBody3D:
	var enemy := CharacterBody3D.new()
	_root.add_child(enemy)
	_spawned.append(enemy)
	enemy.position = pos
	return enemy
