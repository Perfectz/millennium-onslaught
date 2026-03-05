## Belt-scroller movement with gravity, jumping, and belt-depth nudge.
class_name MovementComponent
extends Node


signal landed()
signal jumped()

## The CharacterBody3D this component controls.
var _body: CharacterBody3D = null

## Pre-allocated velocity work vector.
var _velocity_work: Vector3 = Vector3.ZERO

## Facing direction: 1.0 = right, -1.0 = left.
var _facing: float = 1.0

## Whether the character is on the ground.
var _is_grounded: bool = false

## Coyote time remaining.
var _coyote_timer: float = 0.0

## Jump buffer remaining.
var _jump_buffer_timer: float = 0.0

## Whether jump was consumed (prevents double jump).
var _jump_consumed: bool = false

## Whether currently in a dodge.
var _is_dodging: bool = false


## Set up the movement component with its body.
func setup(body: CharacterBody3D) -> void:
	_body = body


## Apply horizontal movement input.
func move_horizontal(direction: float) -> void:
	_velocity_work.x = direction * Constants.PLAYER_RUN_SPEED
	if direction != 0.0:
		_facing = signf(direction)


## Apply belt-depth (Z-axis) movement input.
func move_belt_depth(direction: float) -> void:
	_velocity_work.z = direction * Constants.PLAYER_BELT_DEPTH_SPEED


## Request a jump. Uses jump buffer if not grounded.
func request_jump() -> void:
	_jump_buffer_timer = Constants.PLAYER_JUMP_BUFFER_TIME


## Process movement physics.
func process_movement(delta: float) -> void:
	if _body == null:
		return
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_update_grounded()
	_process_timers(capped_delta)
	_apply_gravity(capped_delta)
	_process_jump()
	_clamp_belt_depth()
	_body.velocity = _velocity_work
	_body.move_and_slide()
	# Sync velocity back after collision.
	_velocity_work = _body.velocity


## Get the current facing direction.
func get_facing() -> float:
	return _facing


## Check if grounded.
func is_grounded() -> bool:
	return _is_grounded


## Get current velocity.
func get_velocity() -> Vector3:
	return _velocity_work


## Set velocity directly (for knockback, etc.).
func set_velocity(vel: Vector3) -> void:
	_velocity_work = vel


## Start dodge movement.
func start_dodge() -> void:
	_is_dodging = true
	_velocity_work.x = _facing * Constants.DODGE_SPEED


## End dodge movement.
func end_dodge() -> void:
	_is_dodging = false


func _update_grounded() -> void:
	var was_grounded: bool = _is_grounded
	_is_grounded = _body.is_on_floor()
	if _is_grounded and not was_grounded:
		_jump_consumed = false
		landed.emit()
	elif was_grounded and not _is_grounded:
		_coyote_timer = Constants.PLAYER_COYOTE_TIME


func _process_timers(delta: float) -> void:
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta


func _apply_gravity(delta: float) -> void:
	if _is_grounded:
		return
	var gravity_mult: float = 1.0
	if _velocity_work.y < 0.0:
		gravity_mult = Constants.PLAYER_FALL_GRAVITY_MULTIPLIER
	_velocity_work.y -= Constants.PLAYER_GRAVITY * gravity_mult * delta
	_velocity_work.y = maxf(_velocity_work.y, -Constants.TERMINAL_VELOCITY)


func _process_jump() -> void:
	if _jump_buffer_timer <= 0.0:
		return
	var can_jump: bool = (_is_grounded or _coyote_timer > 0.0) and not _jump_consumed
	if can_jump:
		_velocity_work.y = Constants.PLAYER_JUMP_VELOCITY
		_jump_consumed = true
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jumped.emit()


func _clamp_belt_depth() -> void:
	if _body == null:
		return
	var max_z: float = Constants.PLAYER_BELT_DEPTH_RANGE
	_body.position.z = clampf(_body.position.z, -max_z, max_z)
