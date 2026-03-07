## Spring-damped camera with anticipatory tracking, threat awareness, and director cues.
## Features: dead zones (X+Y), velocity look-ahead, enemy centroid bias, dynamic FOV zoom,
## arena lock (X+Z), trauma shake (real-time), breathing, director cue system, action-driven photo mode.
## Priority stack: arena bounds > threat visibility > look-ahead > dead zone > breathing.
class_name CameraFollow
extends Camera3D


const CameraLockOnPresentationScript := preload("res://scripts/components/camera_lock_on_presentation.gd")


## Camera operating modes.
enum Mode { FOLLOW, DIRECTOR }

@export var target_path: NodePath
var _target: Node3D = null
var _offset: Vector3 = Vector3.ZERO
var _mode: Mode = Mode.FOLLOW

## Spring state (critically damped).
var _velocity: Vector3 = Vector3.ZERO

## Velocity look-ahead state.
var _look_ahead_offset: Vector3 = Vector3.ZERO

## Enemy centroid threat bias state.
var _threat_offset: Vector3 = Vector3.ZERO
var _enemy_group: String = "enemies"

## Trauma-based shake (real-time for hitstop immunity).
var _trauma: float = 0.0
var _shake_time: float = 0.0
var _prev_shake_ticks: int = 0
var _prev_shake_offset_x: float = 0.0
var _prev_shake_offset_y: float = 0.0
var _prev_shake_roll: float = 0.0

## Subtle breathing (micro-motion when idle).
var _breath_time: float = 0.0
var _prev_breath_offset_x: float = 0.0
var _prev_breath_offset_y: float = 0.0

## Arena lock state.
var _arena_locked: bool = false
var _arena_min_x: float = -100.0
var _arena_max_x: float = 100.0
var _arena_min_z: float = -100.0
var _arena_max_z: float = 100.0
## Easing progress (0 = unlocked, 1 = fully locked).
var _lock_blend: float = 0.0

## Stage-mode forward bounds (always hard-clamp when active).
var _stage_bounds_active: bool = false
var _stage_min_x: float = -100.0
var _stage_max_x: float = 100.0
var _stage_min_z: float = -100.0
var _stage_max_z: float = 100.0

## Dynamic FOV zoom.
var _base_fov: float = 40.0

## Manual zoom (keyboard) and orbit offsets (right stick).
@export var default_manual_zoom: float = 0.92
@export var default_orbit_yaw: float = 0.0
@export var default_orbit_pitch: float = 0.08
var _manual_zoom: float = Constants.CAMERA_ZOOM_DEFAULT
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.0

## Director cue state.
var _director_target: Vector3 = Vector3.ZERO
var _director_hold_timer: float = 0.0
var _director_return_pos: Vector3 = Vector3.ZERO

## Photo mode state.
var _photo_mode: bool = false
var _photo_yaw: float = 0.0
var _photo_pitch: float = 0.0
var _saved_position: Vector3 = Vector3.ZERO
var _saved_rotation: Vector3 = Vector3.ZERO
var _follow_forward: Vector3 = Vector3.RIGHT
var _lock_on_presentation = CameraLockOnPresentationScript.new()
const PHOTO_MOVE_SPEED: float = 8.0
const PHOTO_FAST_MULTIPLIER: float = 3.0
const PHOTO_MOUSE_SENSITIVITY: float = 0.002
const PHOTO_ROLL_SPEED: float = 1.5
const FOLLOW_DISTANCE: float = 7.0
const FOLLOW_HEIGHT: float = 4.75
const FOLLOW_SHOULDER_OFFSET: float = 1.35
const FOLLOW_DIRECTION_BLEND_SPEED: float = 8.0
const FOLLOW_FOCUS_HEIGHT: float = 1.6
const FOLLOW_FOCUS_FORWARD: float = 2.0
const FOLLOW_BASE_FOV: float = 40.0
const LOCK_ON_DISTANCE: float = 7.8
const LOCK_ON_HEIGHT: float = 5.0
const LOCK_ON_SHOULDER_OFFSET: float = 0.7
const LOCK_TARGET_FOCUS_HEIGHT: float = 1.2
const OCCLUSION_SIDE_SAMPLE_OFFSET: float = 0.35
const OCCLUSION_VELOCITY_DAMPING: float = 0.25


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	make_current()
	_resolve_target()
	_offset = Vector3(-FOLLOW_DISTANCE, FOLLOW_HEIGHT, FOLLOW_SHOULDER_OFFSET)
	_base_fov = FOLLOW_BASE_FOV
	fov = FOLLOW_BASE_FOV
	_apply_default_manual_camera_state()
	_prev_shake_ticks = Time.get_ticks_usec()
	_follow_forward = _get_desired_follow_direction()

	# Snap camera to correct position on first frame (no spring lag).
	snap_to_target()

	EventBus.encounter_arena_locked.connect(_on_arena_locked)
	EventBus.encounter_arena_unlocked.connect(_on_arena_unlocked)
	EventBus.stage_bounds_updated.connect(_on_stage_bounds_updated)
	EventBus.camera_director_cue.connect(_on_director_cue)
	EventBus.camera_director_return.connect(_on_director_return)


func _resolve_target() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D


func _get_node_position(node: Node3D) -> Vector3:
	if node == null or not is_instance_valid(node):
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	return node.position


func _get_lock_target() -> Node3D:
	if _target == null or not is_instance_valid(_target):
		return null
	if not ("lock_target" in _target):
		return null
	var candidate = _target.lock_target
	if candidate is Node3D and is_instance_valid(candidate):
		return candidate as Node3D
	return null


func _get_lock_on_profile(orbit_forward: Vector3) -> Dictionary:
	var lock_target := _get_lock_target()
	if lock_target == null:
		return {}
	return _lock_on_presentation.build_profile(
		_get_node_position(_target),
		_get_node_position(lock_target),
		orbit_forward
	)


func snap_to_target() -> void:
	_resolve_target()
	if _target == null or not is_instance_valid(_target):
		return

	make_current()
	_velocity = Vector3.ZERO
	_look_ahead_offset = Vector3.ZERO
	_threat_offset = Vector3.ZERO
	_director_hold_timer = 0.0
	_mode = Mode.FOLLOW

	_follow_forward = _get_desired_follow_direction()
	var orbit_forward := _get_orbit_forward()
	var lock_profile := _get_lock_on_profile(orbit_forward)
	position = _get_node_position(_target) + _get_dynamic_follow_offset_with_context(orbit_forward, lock_profile)
	_orient_to_target()

	_prev_shake_offset_x = 0.0
	_prev_shake_offset_y = 0.0
	_prev_shake_roll = 0.0
	_prev_breath_offset_x = 0.0
	_prev_breath_offset_y = 0.0
	_breath_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"photo_toggle", false, true):
		_toggle_photo_mode()
		get_viewport().set_input_as_handled()
		return

	# Mouse look in photo mode.
	if _photo_mode and event is InputEventMouseMotion:
		_photo_yaw -= event.relative.x * PHOTO_MOUSE_SENSITIVITY
		_photo_pitch -= event.relative.y * PHOTO_MOUSE_SENSITIVITY
		_photo_pitch = clampf(_photo_pitch, -PI * 0.45, PI * 0.45)
		rotation = Vector3(_photo_pitch, _photo_yaw, rotation.z)
		get_viewport().set_input_as_handled()

	# Mouse wheel zoom (move forward/back) in photo mode.
	if _photo_mode and event is InputEventMouseButton:
		if event.pressed:
			var zoom_step := 1.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				position += -global_transform.basis.z * zoom_step
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				position += global_transform.basis.z * zoom_step
				get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _photo_mode:
		_process_photo_mode(delta)
		return

	if _target == null or not is_instance_valid(_target):
		return

	var capped_delta := minf(delta, Constants.DELTA_CAP)

	match _mode:
		Mode.FOLLOW:
			_process_follow(capped_delta)
		Mode.DIRECTOR:
			_process_director(capped_delta)

	# --- Manual orbit (right stick) + keyboard zoom/reset ---
	_update_manual_camera_controls(capped_delta)

	# --- Trauma shake (real-time, works during hitstop) ---
	_update_trauma_shake()

	# --- Breathing (subtract previous offset before applying new) ---
	position.x -= _prev_breath_offset_x
	position.y -= _prev_breath_offset_y
	_breath_time += capped_delta * Constants.CAMERA_BREATH_SPEED
	_prev_breath_offset_y = sin(_breath_time) * Constants.CAMERA_BREATH_AMPLITUDE
	_prev_breath_offset_x = sin(_breath_time * 0.7) * Constants.CAMERA_BREATH_AMPLITUDE * 0.3
	position.y += _prev_breath_offset_y
	position.x += _prev_breath_offset_x

	# --- Pull the camera in if a wall sits between it and the player focus point. ---
	_apply_camera_occlusion()

	# --- Dynamic FOV zoom ---
	_update_dynamic_fov(capped_delta)

	if _mode == Mode.FOLLOW:
		_orient_to_target()


## Main follow mode - dead zones, look-ahead, threat bias, arena lock, spring.
func _process_follow(delta: float) -> void:
	_update_follow_direction(delta)
	var orbit_forward := _get_orbit_forward()
	var lock_profile := _get_lock_on_profile(orbit_forward)
	var dynamic_offset := _get_dynamic_follow_offset_with_context(orbit_forward, lock_profile)
	var desired := _get_node_position(_target) + dynamic_offset

	# --- Velocity look-ahead (anticipation beats reaction) ---
	_update_look_ahead(delta, lock_profile)
	desired += _look_ahead_offset

	# --- Enemy centroid threat bias ---
	_update_threat_bias(delta, lock_profile)
	desired += _threat_offset

	# --- Arena bounds clamping (X + Z) with smooth blend ---
	var ease_speed := 1.0 / maxf(Constants.DUNGEON_ARENA_LOCK_EASE_TIME, 0.01)
	if _arena_locked:
		_lock_blend = minf(_lock_blend + ease_speed * delta, 1.0)
	else:
		_lock_blend = maxf(_lock_blend - ease_speed * delta, 0.0)

	# X clamping.
	var free_x := desired.x
	var clamped_x := clampf(desired.x, _arena_min_x + dynamic_offset.x, _arena_max_x + dynamic_offset.x)
	desired.x = lerpf(free_x, clamped_x, _lock_blend)

	# Z clamping (belt-depth bounds).
	var free_z := desired.z
	var clamped_z := clampf(desired.z, _arena_min_z + dynamic_offset.z, _arena_max_z + dynamic_offset.z)
	desired.z = lerpf(free_z, clamped_z, _lock_blend)

	# --- Stage-mode forward bounds (hard clamp, always active) ---
	if _stage_bounds_active:
		desired.x = clampf(desired.x, _stage_min_x + dynamic_offset.x, _stage_max_x + dynamic_offset.x)
		desired.z = clampf(desired.z, _stage_min_z + dynamic_offset.z, _stage_max_z + dynamic_offset.z)

	# --- X dead zone - ignore minor horizontal corrections ---
	var deadzone_scale := float(lock_profile.get("deadzone_scale", 1.0))
	var x_diff := desired.x - position.x
	if absf(x_diff) <= Constants.CAMERA_DEADZONE_X * deadzone_scale:
		desired.x = position.x

	# --- Y dead zone - only follow when outside deadzone ---
	var y_diff := desired.y - position.y
	if absf(y_diff) <= Constants.CAMERA_DEADZONE_Y * deadzone_scale:
		desired.y = position.y

	# --- Pull in toward a safe point before the spring resolves back out. ---
	var focus := _get_focus_point_with_context(orbit_forward, lock_profile)
	desired = _get_occlusion_safe_position(focus, desired)

	# --- Critically-damped spring ---
	var displacement := position - desired
	var spring_force := -Constants.CAMERA_SPRING_STIFFNESS * displacement - Constants.CAMERA_SPRING_DAMPING * _velocity
	_velocity += spring_force * delta

	# --- Velocity cap (prevent camera whip on teleport/lag spike) ---
	var speed := _velocity.length()
	if speed > Constants.CAMERA_VELOCITY_CAP:
		_velocity = _velocity.normalized() * Constants.CAMERA_VELOCITY_CAP

	position += _velocity * delta


## Director mode - glide toward a target position, hold, then return.
func _process_director(delta: float) -> void:
	var ease_time := maxf(Constants.CAMERA_DIRECTOR_EASE_TIME, 0.01)

	if _director_hold_timer > 0.0:
		# Holding on target.
		_director_hold_timer -= delta
		# Glide toward director target.
		position = position.lerp(_director_target, delta / ease_time)
		_velocity = Vector3.ZERO
		if _director_hold_timer <= 0.0:
			_mode = Mode.FOLLOW
	else:
		# Easing toward target before hold starts - should not normally reach here.
		_mode = Mode.FOLLOW


func _get_focus_point() -> Vector3:
	var orbit_forward := _get_orbit_forward()
	return _get_focus_point_with_context(orbit_forward, _get_lock_on_profile(orbit_forward))


func _get_focus_point_with_context(orbit_forward: Vector3, lock_profile: Dictionary = {}) -> Vector3:
	if _target == null or not is_instance_valid(_target):
		return global_position + -global_transform.basis.z
	var focus := _get_node_position(_target) + Vector3(0.0, FOLLOW_FOCUS_HEIGHT, 0.0)
	focus += orbit_forward * FOLLOW_FOCUS_FORWARD
	if not lock_profile.is_empty():
		var profile_focus = lock_profile.get("focus", focus)
		if profile_focus is Vector3:
			return profile_focus
	return focus


func _orient_to_target() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var roll := rotation.z
	look_at(_get_focus_point(), Vector3.UP)
	rotation.z += roll


func _apply_camera_occlusion() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var world := get_world_3d()
	if world == null:
		return
	var focus := _get_focus_point()
	var desired := global_position
	var safe_position := _get_occlusion_safe_position(focus, desired)
	if safe_position != desired:
		global_position = safe_position
		_velocity *= OCCLUSION_VELOCITY_DAMPING


func _get_occlusion_safe_position(focus: Vector3, desired_position: Vector3) -> Vector3:
	var world := get_world_3d()
	if world == null:
		return desired_position
	var safe_position := desired_position
	var best_safe_distance := focus.distance_to(desired_position)
	for sample_focus in _get_occlusion_focus_samples(focus):
		var hit := _intersect_occlusion_ray(world, sample_focus, desired_position)
		if hit.is_empty():
			continue
		var candidate := _compute_occlusion_safe_position(
			sample_focus,
			desired_position,
			hit.get("position", desired_position) as Vector3
		)
		var candidate_distance := sample_focus.distance_to(candidate)
		if candidate_distance < best_safe_distance:
			best_safe_distance = candidate_distance
			safe_position = candidate
	return safe_position


func _get_occlusion_focus_samples(focus: Vector3) -> Array[Vector3]:
	var samples: Array[Vector3] = [
		focus,
		focus + Vector3.UP * 0.55,
		focus - Vector3.UP * 0.35,
	]
	var orbit_forward := _get_orbit_forward()
	var lateral := Vector3(orbit_forward.z, 0.0, -orbit_forward.x)
	if lateral.length_squared() > 0.001:
		lateral = lateral.normalized() * OCCLUSION_SIDE_SAMPLE_OFFSET
		samples.append(focus + lateral)
		samples.append(focus - lateral)

	var lock_target := _get_lock_target()
	if lock_target != null:
		var target_focus := _get_node_position(lock_target) + Vector3(0.0, LOCK_TARGET_FOCUS_HEIGHT, 0.0)
		var midpoint := focus.lerp(target_focus, 0.5)
		samples.append(midpoint)
		samples.append(target_focus)
		samples.append(target_focus + Vector3.UP * 0.45)
		if lateral.length_squared() > 0.0:
			samples.append(midpoint + lateral * 0.6)
			samples.append(midpoint - lateral * 0.6)
	return samples


func _intersect_occlusion_ray(world: World3D, from: Vector3, to: Vector3) -> Dictionary:
	var direction := to - from
	if direction.length() <= 0.001:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = Constants.LAYER_ENVIRONMENT
	var exclude: Array[RID] = []
	if _target is CollisionObject3D:
		exclude.append((_target as CollisionObject3D).get_rid())
	query.exclude = exclude
	return world.direct_space_state.intersect_ray(query)


func _compute_occlusion_safe_position(
	focus: Vector3,
	desired_position: Vector3,
	hit_position: Vector3
) -> Vector3:
	var direction := desired_position - focus
	var desired_distance := direction.length()
	if desired_distance <= 0.001:
		return desired_position
	var normalized_direction := direction / desired_distance
	var safe_distance := focus.distance_to(hit_position) - Constants.CAMERA_OCCLUSION_PADDING
	safe_distance = clampf(
		safe_distance,
		Constants.CAMERA_OCCLUSION_MIN_DISTANCE,
		desired_distance
	)
	return focus + normalized_direction * safe_distance


func _update_follow_direction(delta: float) -> void:
	var desired_forward := _get_desired_follow_direction()
	var blend := clampf(delta * FOLLOW_DIRECTION_BLEND_SPEED, 0.0, 1.0)
	_follow_forward = _follow_forward.lerp(desired_forward, blend)
	_follow_forward.y = 0.0
	if _follow_forward.length_squared() <= 0.001:
		_follow_forward = desired_forward
	else:
		_follow_forward = _follow_forward.normalized()


func _get_desired_follow_direction() -> Vector3:
	if RuntimeState.stage_mode:
		return Vector3.RIGHT
	if _target != null and is_instance_valid(_target) and ("facing_direction" in _target):
		var facing = _target.facing_direction
		if facing is Vector3:
			var planar_facing := facing as Vector3
			planar_facing.y = 0.0
			if planar_facing.length_squared() > 0.001:
				return planar_facing.normalized()
	if _target is CharacterBody3D:
		var body := _target as CharacterBody3D
		var planar_velocity := body.velocity
		planar_velocity.y = 0.0
		if planar_velocity.length_squared() > 0.05:
			return planar_velocity.normalized()
	if _follow_forward.length_squared() > 0.001:
		return _follow_forward.normalized()
	return Vector3.RIGHT


func _get_dynamic_follow_offset() -> Vector3:
	var orbit_forward := _get_orbit_forward()
	return _get_dynamic_follow_offset_with_context(orbit_forward, _get_lock_on_profile(orbit_forward))


func _get_dynamic_follow_offset_with_context(orbit_forward: Vector3, lock_profile: Dictionary = {}) -> Vector3:
	var forward := _get_orbit_forward()
	if orbit_forward.length_squared() > 0.001:
		forward = orbit_forward
	if forward.length_squared() <= 0.001:
		forward = Vector3.RIGHT
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var distance := FOLLOW_DISTANCE
	var height := FOLLOW_HEIGHT
	var shoulder := FOLLOW_SHOULDER_OFFSET
	if not lock_profile.is_empty():
		distance = float(lock_profile.get("distance", LOCK_ON_DISTANCE))
		height = float(lock_profile.get("height", LOCK_ON_HEIGHT))
		shoulder = float(lock_profile.get("shoulder", LOCK_ON_SHOULDER_OFFSET))
	var base_offset := (-forward * distance) + (right * shoulder) + Vector3.UP * height
	if absf(_orbit_pitch) > 0.001:
		base_offset = base_offset.rotated(right, _orbit_pitch)
	var zoom_dir := base_offset.normalized()
	return base_offset + zoom_dir * (_manual_zoom - 1.0) * base_offset.length()


## Compute velocity-based look-ahead offset from target movement.
func _update_look_ahead(delta: float, lock_profile: Dictionary = {}) -> void:
	if not _target is CharacterBody3D:
		return
	var body := _target as CharacterBody3D
	var target_look := Vector3.ZERO
	# Horizontal look-ahead proportional to movement speed.
	if absf(body.velocity.x) > 0.5:
		target_look.x = signf(body.velocity.x) * Constants.CAMERA_LOOK_AHEAD_STRENGTH
	# Z look-ahead at equal strength (isometric - all directions matter equally).
	if absf(body.velocity.z) > 0.5:
		target_look.z = signf(body.velocity.z) * Constants.CAMERA_LOOK_AHEAD_STRENGTH
	target_look *= float(lock_profile.get("look_ahead_scale", 1.0))
	_look_ahead_offset = _look_ahead_offset.lerp(target_look, delta * Constants.CAMERA_LOOK_AHEAD_SMOOTHING)


## Compute threat centroid bias from active enemies.
func _update_threat_bias(delta: float, lock_profile: Dictionary = {}) -> void:
	if not _arena_locked:
		_threat_offset = _threat_offset.lerp(Vector3.ZERO, delta * Constants.CAMERA_THREAT_BIAS_SMOOTHING)
		return

	var enemies := get_tree().get_nodes_in_group(_enemy_group)
	if enemies.is_empty():
		_threat_offset = _threat_offset.lerp(Vector3.ZERO, delta * Constants.CAMERA_THREAT_BIAS_SMOOTHING)
		return

	# Compute enemy centroid.
	var centroid := Vector3.ZERO
	var count := 0
	for enemy in enemies:
		if enemy is Node3D and is_instance_valid(enemy):
			centroid += (enemy as Node3D).global_position
			count += 1

	if count == 0:
		_threat_offset = _threat_offset.lerp(Vector3.ZERO, delta * Constants.CAMERA_THREAT_BIAS_SMOOTHING)
		return

	centroid /= float(count)

	# Midpoint between player and enemy centroid, biased toward threats.
	var midpoint := _target.global_position.lerp(centroid, Constants.CAMERA_THREAT_BIAS_STRENGTH)
	var target_bias := (midpoint - _target.global_position)
	# Only apply X and Z bias (not Y - enemies should not pull camera vertically).
	target_bias.y = 0.0
	target_bias *= float(lock_profile.get("threat_bias_scale", 1.0))

	_threat_offset = _threat_offset.lerp(target_bias, delta * Constants.CAMERA_THREAT_BIAS_SMOOTHING)


## Dynamic FOV zoom - widen during arena encounters to keep threats visible.
func _update_dynamic_fov(delta: float) -> void:
	var target_fov := _base_fov
	if _arena_locked:
		var enemies := get_tree().get_nodes_in_group(_enemy_group)
		var enemy_count := enemies.size()
		# Zoom out slightly when many enemies are present.
		if enemy_count >= 4:
			target_fov = _base_fov / Constants.CAMERA_ZOOM_MIN  # Wider FOV
		elif enemy_count >= 2:
			var t := float(enemy_count - 2) / 2.0
			target_fov = lerpf(_base_fov, _base_fov / Constants.CAMERA_ZOOM_MIN, t)
	fov = lerpf(fov, target_fov, delta * Constants.CAMERA_FOV_ZOOM_SPEED)


## Update manual orbit from the right stick and zoom/reset from shared camera actions.
func _update_manual_camera_controls(delta: float) -> void:
	var orbit_x := InputManager.get_axis_for_player(0, &"camera_look_left", &"camera_look_right")
	var orbit_y := InputManager.get_axis_for_player(0, &"camera_look_down", &"camera_look_up")
	if absf(orbit_x) > 0.01:
		_orbit_yaw += orbit_x * Constants.CAMERA_ORBIT_YAW_SPEED * delta
	if absf(orbit_y) > 0.01:
		_orbit_pitch += orbit_y * Constants.CAMERA_ORBIT_PITCH_SPEED * delta
		_orbit_pitch = clampf(_orbit_pitch, Constants.CAMERA_ORBIT_PITCH_MIN, Constants.CAMERA_ORBIT_PITCH_MAX)

	var zoom_axis := InputManager.get_axis_for_player(0, &"camera_zoom_in", &"camera_zoom_out")
	if absf(zoom_axis) > 0.01:
		_manual_zoom += zoom_axis * Constants.CAMERA_ZOOM_STICK_SPEED * delta
		_manual_zoom = clampf(_manual_zoom, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	if InputManager.is_action_just_pressed_for_player(0, &"camera_reset"):
		_reset_manual_camera()


func _get_orbit_forward() -> Vector3:
	var base_forward := _follow_forward
	base_forward.y = 0.0
	if base_forward.length_squared() <= 0.001:
		base_forward = Vector3.RIGHT
	else:
		base_forward = base_forward.normalized()
	return base_forward.rotated(Vector3.UP, _orbit_yaw).normalized()


func _apply_default_manual_camera_state() -> void:
	_manual_zoom = clampf(default_manual_zoom, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	_orbit_yaw = default_orbit_yaw
	_orbit_pitch = clampf(default_orbit_pitch, Constants.CAMERA_ORBIT_PITCH_MIN, Constants.CAMERA_ORBIT_PITCH_MAX)


func _reset_manual_camera() -> void:
	_apply_default_manual_camera_state()
	snap_to_target()


## Add trauma for screen shake (0-1 range, squared for intensity curve).
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


## Trauma shake using real time (works during hitstop when time_scale = 0).
func _update_trauma_shake() -> void:
	var now := Time.get_ticks_usec()
	var real_delta := (now - _prev_shake_ticks) / 1_000_000.0
	_prev_shake_ticks = now

	# Clamp real_delta to avoid explosion after long pauses.
	real_delta = minf(real_delta, 0.1)

	# Remove previous frame's shake offset before applying new.
	position.x -= _prev_shake_offset_x
	position.y -= _prev_shake_offset_y
	rotation.z -= _prev_shake_roll

	if _trauma <= 0.0:
		_prev_shake_offset_x = 0.0
		_prev_shake_offset_y = 0.0
		_prev_shake_roll = 0.0
		return

	_shake_time += real_delta * 30.0
	var shake := _trauma * _trauma  # Squared for exponential feel

	# Perlin-like noise using sin waves at different frequencies.
	var offset_x := sin(_shake_time * 1.1 + 0.3) * cos(_shake_time * 0.7) * Constants.CAMERA_MAX_SHAKE_OFFSET * shake
	var offset_y := sin(_shake_time * 1.3 + 1.7) * cos(_shake_time * 0.9) * Constants.CAMERA_MAX_SHAKE_OFFSET * shake
	var roll := sin(_shake_time * 0.8 + 2.1) * Constants.CAMERA_MAX_SHAKE_ROLL * shake

	position.x += offset_x
	position.y += offset_y
	rotation.z += roll

	_prev_shake_offset_x = offset_x
	_prev_shake_offset_y = offset_y
	_prev_shake_roll = roll

	_trauma = maxf(_trauma - Constants.CAMERA_TRAUMA_DECAY_RATE * real_delta, 0.0)
	if _trauma <= 0.001:
		_trauma = 0.0
		_prev_shake_offset_x = 0.0
		_prev_shake_offset_y = 0.0
		_prev_shake_roll = 0.0
		rotation.z = 0.0


## Toggle photo mode on/off.
func _toggle_photo_mode() -> void:
	_photo_mode = not _photo_mode
	if _photo_mode:
		_saved_position = position
		_saved_rotation = rotation
		_photo_yaw = rotation.y
		_photo_pitch = rotation.x
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = true
		print("[Photo Mode] ON - WASD move, mouse look, Shift=fast, Q/E=down/up, Scroll=zoom, R=roll reset, F8=exit")
	else:
		position = _saved_position
		rotation = _saved_rotation
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = false
		print("[Photo Mode] OFF")


## Process free camera movement in photo mode.
func _process_photo_mode(delta: float) -> void:
	var speed := PHOTO_MOVE_SPEED
	if InputManager.is_action_pressed_for_player(0, &"photo_speed_modifier"):
		speed *= PHOTO_FAST_MULTIPLIER

	var move_dir := Vector3.ZERO
	if InputManager.is_action_pressed_for_player(0, &"photo_move_forward"):
		move_dir -= global_transform.basis.z
	if InputManager.is_action_pressed_for_player(0, &"photo_move_backward"):
		move_dir += global_transform.basis.z
	if InputManager.is_action_pressed_for_player(0, &"photo_move_left"):
		move_dir -= global_transform.basis.x
	if InputManager.is_action_pressed_for_player(0, &"photo_move_right"):
		move_dir += global_transform.basis.x
	if InputManager.is_action_pressed_for_player(0, &"photo_move_up"):
		move_dir += Vector3.UP
	if InputManager.is_action_pressed_for_player(0, &"photo_move_down"):
		move_dir += Vector3.DOWN

	# Roll controls.
	if InputManager.is_action_pressed_for_player(0, &"photo_roll_left"):
		rotation.z += PHOTO_ROLL_SPEED * delta
	if InputManager.is_action_pressed_for_player(0, &"photo_roll_right"):
		rotation.z -= PHOTO_ROLL_SPEED * delta
	if InputManager.is_action_pressed_for_player(0, &"photo_roll_reset"):
		rotation.z = 0.0

	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()
		position += move_dir * speed * delta


func _on_arena_locked(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	_arena_locked = true
	_arena_min_x = min_x
	_arena_max_x = max_x
	_arena_min_z = min_z
	_arena_max_z = max_z


func _on_arena_unlocked() -> void:
	_arena_locked = false


func _on_stage_bounds_updated(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	_stage_bounds_active = true
	_stage_min_x = min_x
	_stage_max_x = max_x
	_stage_min_z = min_z
	_stage_max_z = max_z


## Director cue: cut/glide camera to a target position, hold, then return.
func _on_director_cue(target_position: Vector3, hold_time: float) -> void:
	_mode = Mode.DIRECTOR
	_director_target = target_position + _offset
	_director_hold_timer = hold_time
	_director_return_pos = position


## Director return: immediately switch back to follow mode.
func _on_director_return() -> void:
	_mode = Mode.FOLLOW
	_director_hold_timer = 0.0
