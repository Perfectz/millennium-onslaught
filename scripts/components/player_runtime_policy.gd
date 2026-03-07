## Pure helpers for player runtime timers, guard state, gravity, and fall recovery.
class_name PlayerRuntimePolicy
extends RefCounted


static func tick_physics_state(
	delta: float,
	delta_cap: float,
	jump_pressed: bool,
	jump_buffer_timer: float,
	jump_buffer_duration: float,
	dodge_cooldown_timer: float,
	parry_timer: float
) -> Dictionary:
	var capped := minf(delta, maxf(delta_cap, 0.0))
	var next_jump_buffer := maxf(jump_buffer_timer - capped, 0.0)
	if jump_pressed:
		next_jump_buffer = maxf(jump_buffer_duration, 0.0)
	return {
		"delta": capped,
		"jump_buffer_timer": next_jump_buffer,
		"dodge_cooldown_timer": maxf(dodge_cooldown_timer - capped, 0.0),
		"parry_timer": maxf(parry_timer - capped, 0.0),
	}


static func resolve_guard_state(
	block_just_pressed: bool,
	block_pressed: bool,
	parry_window: float,
	current_parry_timer: float
) -> Dictionary:
	if block_just_pressed:
		return {
			"block_held": true,
			"parry_timer": maxf(parry_window, 0.0),
		}
	return {
		"block_held": block_pressed,
		"parry_timer": current_parry_timer if block_pressed else 0.0,
	}


static func compute_gravity_velocity(
	velocity_y: float,
	on_floor: bool,
	delta: float,
	gravity: float,
	fall_gravity_multiplier: float,
	terminal_velocity: float
) -> float:
	if on_floor:
		return velocity_y
	var applied_gravity := gravity
	if velocity_y < 0.0:
		applied_gravity *= fall_gravity_multiplier
	return maxf(velocity_y - applied_gravity * delta, -absf(terminal_velocity))


static func should_enable_platform_collision(velocity_y: float) -> bool:
	return velocity_y <= 0.0


static func resolve_fall_recovery(
	position: Vector3,
	velocity: Vector3,
	recovery_threshold_y: float,
	recovery_y: float
) -> Dictionary:
	if position.y >= recovery_threshold_y:
		return {
			"position": position,
			"velocity": velocity,
			"recovered": false,
		}

	var next_position := position
	next_position.y = recovery_y
	var next_velocity := velocity
	next_velocity.y = 0.0
	return {
		"position": next_position,
		"velocity": next_velocity,
		"recovered": true,
	}
