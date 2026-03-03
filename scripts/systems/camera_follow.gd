## Spring-damped camera with anticipatory tracking, threat awareness, and director cues.
## Features: dead zones (X+Y), velocity look-ahead, enemy centroid bias, dynamic FOV zoom,
## arena lock (X+Z), trauma shake (real-time), breathing, director cue system, photo mode (F8).
## Priority stack: arena bounds > threat visibility > look-ahead > dead zone > breathing.
class_name CameraFollow
extends Camera3D


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

## Subtle breathing (micro-motion when idle).
var _breath_time: float = 0.0

## Arena lock state.
var _arena_locked: bool = false
var _arena_min_x: float = -100.0
var _arena_max_x: float = 100.0
var _arena_min_z: float = -100.0
var _arena_max_z: float = 100.0
## Easing progress (0 = unlocked, 1 = fully locked).
var _lock_blend: float = 0.0

## Dynamic FOV zoom.
var _base_fov: float = 40.0

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
const PHOTO_MOVE_SPEED: float = 8.0
const PHOTO_FAST_MULTIPLIER: float = 3.0
const PHOTO_MOUSE_SENSITIVITY: float = 0.002
const PHOTO_ROLL_SPEED: float = 1.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if target_path:
		_target = get_node(target_path) as Node3D
	if _target:
		_offset = position - _target.position
	_base_fov = fov
	_prev_shake_ticks = Time.get_ticks_usec()

	EventBus.encounter_arena_locked.connect(_on_arena_locked)
	EventBus.encounter_arena_unlocked.connect(_on_arena_unlocked)
	EventBus.camera_director_cue.connect(_on_director_cue)
	EventBus.camera_director_return.connect(_on_director_return)


func _unhandled_input(event: InputEvent) -> void:
	# F8 toggles photo mode.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
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

	if _target == null:
		return

	var capped_delta := minf(delta, Constants.DELTA_CAP)

	match _mode:
		Mode.FOLLOW:
			_process_follow(capped_delta)
		Mode.DIRECTOR:
			_process_director(capped_delta)

	# --- Trauma shake (real-time, works during hitstop) ---
	_update_trauma_shake()

	# --- Breathing ---
	_breath_time += capped_delta * Constants.CAMERA_BREATH_SPEED
	position.y += sin(_breath_time) * Constants.CAMERA_BREATH_AMPLITUDE
	position.x += sin(_breath_time * 0.7) * Constants.CAMERA_BREATH_AMPLITUDE * 0.3

	# --- Dynamic FOV zoom ---
	_update_dynamic_fov(capped_delta)


## Main follow mode — dead zones, look-ahead, threat bias, arena lock, spring.
func _process_follow(delta: float) -> void:
	var desired := _target.position + _offset

	# --- Velocity look-ahead (anticipation beats reaction) ---
	_update_look_ahead(delta)
	desired += _look_ahead_offset

	# --- Enemy centroid threat bias ---
	_update_threat_bias(delta)
	desired += _threat_offset

	# --- Arena bounds clamping (X + Z) with smooth blend ---
	var ease_speed := 1.0 / maxf(Constants.DUNGEON_ARENA_LOCK_EASE_TIME, 0.01)
	if _arena_locked:
		_lock_blend = minf(_lock_blend + ease_speed * delta, 1.0)
	else:
		_lock_blend = maxf(_lock_blend - ease_speed * delta, 0.0)

	# X clamping.
	var free_x := desired.x
	var clamped_x := clampf(desired.x, _arena_min_x + _offset.x, _arena_max_x + _offset.x)
	desired.x = lerpf(free_x, clamped_x, _lock_blend)

	# Z clamping (belt-depth bounds).
	var free_z := desired.z
	var clamped_z := clampf(desired.z, _arena_min_z + _offset.z, _arena_max_z + _offset.z)
	desired.z = lerpf(free_z, clamped_z, _lock_blend)

	# --- X dead zone — ignore minor horizontal corrections ---
	var x_diff := desired.x - position.x
	if absf(x_diff) <= Constants.CAMERA_DEADZONE_X:
		desired.x = position.x

	# --- Y dead zone — only follow when outside deadzone ---
	var y_diff := desired.y - position.y
	if absf(y_diff) <= Constants.CAMERA_DEADZONE_Y:
		desired.y = position.y

	# --- Critically-damped spring ---
	var displacement := position - desired
	var spring_force := -Constants.CAMERA_SPRING_STIFFNESS * displacement - Constants.CAMERA_SPRING_DAMPING * _velocity
	_velocity += spring_force * delta

	# --- Velocity cap (prevent camera whip on teleport/lag spike) ---
	var speed := _velocity.length()
	if speed > Constants.CAMERA_VELOCITY_CAP:
		_velocity = _velocity.normalized() * Constants.CAMERA_VELOCITY_CAP

	position += _velocity * delta


## Director mode — glide toward a target position, hold, then return.
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
		# Easing toward target before hold starts — shouldn't normally reach here.
		_mode = Mode.FOLLOW


## Compute velocity-based look-ahead offset from target movement.
func _update_look_ahead(delta: float) -> void:
	if not _target is CharacterBody3D:
		return
	var body := _target as CharacterBody3D
	var target_look := Vector3.ZERO
	# Horizontal look-ahead proportional to movement speed.
	if absf(body.velocity.x) > 0.5:
		target_look.x = signf(body.velocity.x) * Constants.CAMERA_LOOK_AHEAD_STRENGTH
	# Slight Z look-ahead for belt-depth.
	if absf(body.velocity.z) > 0.3:
		target_look.z = signf(body.velocity.z) * Constants.CAMERA_LOOK_AHEAD_STRENGTH * 0.4
	_look_ahead_offset = _look_ahead_offset.lerp(target_look, delta * Constants.CAMERA_LOOK_AHEAD_SMOOTHING)


## Compute threat centroid bias from active enemies.
func _update_threat_bias(delta: float) -> void:
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
	# Only apply X and Z bias (not Y — enemies shouldn't pull camera vertically).
	target_bias.y = 0.0

	_threat_offset = _threat_offset.lerp(target_bias, delta * Constants.CAMERA_THREAT_BIAS_SMOOTHING)


## Dynamic FOV zoom — widen during arena encounters to keep threats visible.
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

	if _trauma <= 0.0:
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

	_trauma = maxf(_trauma - Constants.CAMERA_TRAUMA_DECAY_RATE * real_delta, 0.0)
	if _trauma <= 0.001:
		_trauma = 0.0
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
		print("[Photo Mode] ON — WASD move, mouse look, Shift=fast, Q/E=down/up, Scroll=zoom, R=roll reset, F8=exit")
	else:
		position = _saved_position
		rotation = _saved_rotation
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = false
		print("[Photo Mode] OFF")


## Process free camera movement in photo mode.
func _process_photo_mode(delta: float) -> void:
	var speed := PHOTO_MOVE_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= PHOTO_FAST_MULTIPLIER

	var move_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move_dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_E):
		move_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		move_dir += Vector3.DOWN

	# Roll controls.
	if Input.is_key_pressed(KEY_Z):
		rotation.z += PHOTO_ROLL_SPEED * delta
	if Input.is_key_pressed(KEY_X):
		rotation.z -= PHOTO_ROLL_SPEED * delta
	if Input.is_key_pressed(KEY_R):
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
