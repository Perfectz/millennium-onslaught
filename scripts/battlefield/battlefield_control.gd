## Territory + morale rules: bases, garrisons, capture, and enemy aggression.
class_name BattlefieldControl
extends RefCounted


signal base_captured(base_id: StringName)
signal base_lost(base_id: StringName)
signal all_enemy_bases_captured()
signal morale_changed(morale: float)

enum Side { NEUTRAL, ALLY, ENEMY }

var _bases: Dictionary = {}  # id -> {owner: Side, garrison: int, kos: int}
var _morale: float = 0.0


## Register a base with its starting owner (a Side value) and garrison size.
func add_base(base_id: StringName, side: int, garrison: int) -> void:
	_bases[base_id] = {"owner": side, "garrison": maxi(garrison, 0), "kos": 0}


## Count one garrison grunt defeated at a base.
func register_garrison_ko(base_id: StringName) -> void:
	if not _bases.has(base_id):
		return
	_bases[base_id]["kos"] += 1


## Garrison grunts left before the base can fall.
func get_garrison_remaining(base_id: StringName) -> int:
	if not _bases.has(base_id):
		return 0
	var b: Dictionary = _bases[base_id]
	return maxi(int(b["garrison"]) - int(b["kos"]), 0)


## Capture an enemy base once its garrison is broken. Returns true on capture.
func try_capture(base_id: StringName) -> bool:
	if not _bases.has(base_id):
		return false
	var b: Dictionary = _bases[base_id]
	if b["owner"] != Side.ENEMY or get_garrison_remaining(base_id) > 0:
		return false
	b["owner"] = Side.ALLY
	_add_morale(Constants.MORALE_PER_BASE_CAPTURE)
	base_captured.emit(base_id)
	if get_enemy_base_count() == 0:
		all_enemy_bases_captured.emit()
	return true


## The enemy retakes a base.
func lose_base(base_id: StringName) -> void:
	if not _bases.has(base_id) or _bases[base_id]["owner"] == Side.ENEMY:
		return
	_bases[base_id]["owner"] = Side.ENEMY
	_bases[base_id]["kos"] = 0
	_add_morale(Constants.MORALE_PER_BASE_LOST)
	base_lost.emit(base_id)


## An enemy officer was defeated.
func register_officer_ko() -> void:
	_add_morale(Constants.MORALE_PER_OFFICER_KO)


## Owner of a base (NEUTRAL if unknown).
func get_owner(base_id: StringName) -> int:
	if not _bases.has(base_id):
		return Side.NEUTRAL
	return _bases[base_id]["owner"]


## Number of bases still held by the enemy.
func get_enemy_base_count() -> int:
	var n := 0
	for id: StringName in _bases:
		if _bases[id]["owner"] == Side.ENEMY:
			n += 1
	return n


## All registered base ids.
func get_base_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _bases:
		ids.append(id)
	return ids


## Morale from MORALE_MIN (enemy dominant) to MORALE_MAX (allied dominant).
func get_morale() -> float:
	return _morale


## Multiplier on enemy attack frequency: 1.0 at neutral morale, lower as allies dominate.
func get_enemy_aggression() -> float:
	var t := _morale / Constants.MORALE_MAX
	return 1.0 - t * Constants.MORALE_AGGRESSION_SCALE


func _add_morale(delta: float) -> void:
	var next := clampf(_morale + delta, Constants.MORALE_MIN, Constants.MORALE_MAX)
	if is_equal_approx(next, _morale):
		return
	_morale = next
	morale_changed.emit(_morale)
