## Selects the closest alive target from a list of candidates.
## Pure logic (RefCounted) for TDD — EnemyController wraps this.
class_name TargetSelector
extends RefCounted


## Select the closest alive candidate to the origin.
## candidates: Array of {position: Vector3, alive: bool}
## Returns index of closest alive target, or -1 if none alive.
## If all are dead, returns the closest dead one (enemies still need a fallback).
func select_closest(origin: Vector3, candidates: Array[Dictionary]) -> int:
	if candidates.is_empty():
		return -1

	var best_alive_idx: int = -1
	var best_alive_dist: float = INF
	var best_any_idx: int = 0
	var best_any_dist: float = INF

	for i in candidates.size():
		var c: Dictionary = candidates[i]
		var pos_val: Variant = c.get("position", Vector3.ZERO)
		var pos: Vector3 = pos_val as Vector3 if pos_val is Vector3 else Vector3.ZERO
		var alive_val: Variant = c.get("alive", true)
		var alive: bool = bool(alive_val)
		var dist := origin.distance_squared_to(pos)

		if dist < best_any_dist:
			best_any_dist = dist
			best_any_idx = i

		if alive and dist < best_alive_dist:
			best_alive_dist = dist
			best_alive_idx = i

	return best_alive_idx if best_alive_idx >= 0 else best_any_idx
