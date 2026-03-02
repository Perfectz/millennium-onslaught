## Smooth-follow camera that tracks a target node while maintaining its height offset.
## Supports arena-lock mode: clamps follow X to encounter bounds with smooth easing.
class_name CameraFollow
extends Camera3D


@export var target_path: NodePath
var _target: Node3D = null
var _offset: Vector3 = Vector3.ZERO

## Arena lock state.
var _arena_locked: bool = false
var _arena_min_x: float = -100.0
var _arena_max_x: float = 100.0
## Easing progress (0 = unlocked, 1 = fully locked).
var _lock_blend: float = 0.0


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node3D
	if _target:
		_offset = position - _target.position
	EventBus.encounter_arena_locked.connect(_on_arena_locked)
	EventBus.encounter_arena_unlocked.connect(_on_arena_unlocked)


func _physics_process(delta: float) -> void:
	if _target == null:
		return

	# Ease arena lock blend toward target.
	var ease_speed := 1.0 / maxf(Constants.DUNGEON_ARENA_LOCK_EASE_TIME, 0.01)
	if _arena_locked:
		_lock_blend = minf(_lock_blend + ease_speed * delta, 1.0)
	else:
		_lock_blend = maxf(_lock_blend - ease_speed * delta, 0.0)

	var smooth := Constants.CAMERA_FOLLOW_SMOOTHING * delta
	var target_pos := _target.position + _offset

	# Apply arena bounds clamping with smooth blend.
	var free_x := target_pos.x
	var clamped_x := clampf(target_pos.x, _arena_min_x + _offset.x, _arena_max_x + _offset.x)
	target_pos.x = lerpf(free_x, clamped_x, _lock_blend)

	position.x = lerpf(position.x, target_pos.x, smooth)

	# Track Y with deadzone to avoid jittery vertical following.
	var y_diff := target_pos.y - position.y
	if absf(y_diff) > Constants.CAMERA_DEADZONE_Y:
		var cam_target_y := position.y + signf(y_diff) * (absf(y_diff) - Constants.CAMERA_DEADZONE_Y)
		position.y = lerpf(position.y, cam_target_y, smooth)


func _on_arena_locked(min_x: float, max_x: float) -> void:
	_arena_locked = true
	_arena_min_x = min_x
	_arena_max_x = max_x


func _on_arena_unlocked() -> void:
	_arena_locked = false
