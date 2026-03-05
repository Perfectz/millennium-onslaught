## Follows player(s) with smoothing, shake, and arena lock.
class_name CameraFollow
extends Camera3D


## Targets to follow (usually players).
var _targets: Array[Node3D] = []

## Pre-allocated position work vector.
var _target_pos: Vector3 = Vector3.ZERO

## Camera offset from target center.
@export var offset: Vector3 = Vector3(0.0, 5.0, 10.0)

## Shake state.
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _shake_offset: Vector3 = Vector3.ZERO

## Arena lock bounds (when set, camera won't leave these bounds).
var _arena_locked: bool = false
var _arena_min: Vector3 = Vector3.ZERO
var _arena_max: Vector3 = Vector3.ZERO


func _ready() -> void:
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)


func _process(delta: float) -> void:
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_update_target_position()
	_process_shake(capped_delta)
	var desired: Vector3 = _target_pos + offset + _shake_offset
	if _arena_locked:
		desired = _clamp_to_arena(desired)
	global_position = global_position.lerp(desired, Constants.CAMERA_FOLLOW_SMOOTHING * capped_delta)


## Add a target to follow.
func add_target(target: Node3D) -> void:
	if target not in _targets:
		_targets.append(target)


## Remove a target.
func remove_target(target: Node3D) -> void:
	_targets.erase(target)


## Apply camera shake.
func shake(intensity: float, duration: float = -1.0) -> void:
	_shake_intensity = intensity
	_shake_timer = duration if duration > 0.0 else Constants.CAMERA_SHAKE_DURATION


## Lock camera to arena bounds.
func lock_to_arena(min_bounds: Vector3, max_bounds: Vector3) -> void:
	_arena_locked = true
	_arena_min = min_bounds
	_arena_max = max_bounds


## Release arena lock.
func unlock_arena() -> void:
	_arena_locked = false


func _update_target_position() -> void:
	# Clean dead targets.
	var i: int = _targets.size() - 1
	while i >= 0:
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
		i -= 1
	if _targets.is_empty():
		return
	_target_pos = Vector3.ZERO
	for target in _targets:
		_target_pos += target.global_position
	_target_pos /= float(_targets.size())


func _process_shake(delta: float) -> void:
	if _shake_timer <= 0.0:
		_shake_offset = Vector3.ZERO
		return
	_shake_timer -= delta
	var t: float = _shake_timer / Constants.CAMERA_SHAKE_DURATION
	_shake_offset = Vector3(
		randf_range(-1.0, 1.0) * _shake_intensity * t,
		randf_range(-1.0, 1.0) * _shake_intensity * t,
		0.0
	)


func _clamp_to_arena(pos: Vector3) -> Vector3:
	pos.x = clampf(pos.x, _arena_min.x, _arena_max.x)
	pos.y = clampf(pos.y, _arena_min.y, _arena_max.y)
	return pos


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, _pos: Vector3) -> void:
	var intensity: float = Constants.CAMERA_SHAKE_LIGHT
	if damage >= Constants.HEAVY_ATTACK_DAMAGE:
		intensity = Constants.CAMERA_SHAKE_HEAVY
	shake(intensity)


func _on_kill(_attacker: Node, _target: Node, _pos: Vector3) -> void:
	shake(Constants.CAMERA_SHAKE_KILL)
