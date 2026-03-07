## Pure helpers for player lock-on candidate filtering and target selection.
class_name PlayerLockOnPolicy
extends RefCounted


const TargetSelectorScript := preload("res://scripts/components/target_selector.gd")


var _selector: TargetSelector = TargetSelectorScript.new()


func select_nearest(origin: Vector3, nodes: Array, max_distance_sq: float) -> Node3D:
	var candidates := _build_candidates(nodes)
	var index := _selector.select_closest(origin, candidates, max_distance_sq)
	return _node_for_index(candidates, index)


func select_next(origin: Vector3, current_target: Node3D, nodes: Array, max_distance_sq: float) -> Node3D:
	var candidates := _build_candidates(nodes)
	var current_index := _candidate_index_for_node(candidates, current_target)
	var index := _selector.select_closest(origin, candidates, max_distance_sq, current_index)
	return _node_for_index(candidates, index)


func _build_candidates(nodes: Array) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for node in nodes:
		if not node is CharacterBody3D or not is_instance_valid(node):
			continue
		var body := node as CharacterBody3D
		var alive := true
		if "health" in body and body.health != null:
			alive = not body.health.is_dead()
		candidates.append({
			"node": body,
			"position": _get_node_position(body),
			"alive": alive,
		})
	return candidates


func _get_node_position(node: Node3D) -> Vector3:
	if node.is_inside_tree():
		return node.global_position
	return node.position


func _candidate_index_for_node(candidates: Array[Dictionary], node: Node3D) -> int:
	if node == null or not is_instance_valid(node):
		return -1
	for i in candidates.size():
		if candidates[i].get("node", null) == node:
			return i
	return -1


func _node_for_index(candidates: Array[Dictionary], index: int) -> Node3D:
	if index < 0 or index >= candidates.size():
		return null
	return candidates[index].get("node", null) as Node3D
