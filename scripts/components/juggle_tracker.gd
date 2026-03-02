## Pure logic juggle tracking. No scene tree dependency — fully testable.
## Tracks airborne state, hit count, and enforces juggle limit.
## When limit is reached, the entity should be forced down (hard knockdown).
class_name JuggleTracker
extends RefCounted


signal launched()
signal air_hit(hit_count: int)
signal limit_reached()
signal landed()

var _max_hits: int
var _hit_count: int = 0
var _is_airborne: bool = false
var _limit_reached: bool = false


func _init(max_hits: int = -1) -> void:
	_max_hits = max_hits if max_hits > 0 else Constants.MAX_JUGGLE_COUNT


## Launch the entity into the air. Starts juggle tracking.
func launch() -> void:
	if _is_airborne:
		return
	_is_airborne = true
	_hit_count = 0
	_limit_reached = false
	launched.emit()


## Register an air hit. Increments counter, enforces limit.
func register_air_hit() -> void:
	if not _is_airborne:
		return
	if _limit_reached:
		return
	_hit_count += 1
	air_hit.emit(_hit_count)
	if _hit_count >= _max_hits:
		_limit_reached = true
		limit_reached.emit()


## Land on the ground. Resets juggle state.
func land() -> void:
	if not _is_airborne:
		return
	_is_airborne = false
	_hit_count = 0
	_limit_reached = false
	landed.emit()


## Check if the entity is currently airborne.
func is_airborne() -> bool:
	return _is_airborne


## Get the current air hit count.
func get_hit_count() -> int:
	return _hit_count


## Check if juggle limit has been reached.
func is_limit_reached() -> bool:
	return _limit_reached
