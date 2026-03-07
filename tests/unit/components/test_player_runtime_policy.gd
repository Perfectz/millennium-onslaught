## Pure regression coverage for player runtime timer, gravity, and recovery helpers.
class_name TestPlayerRuntimePolicy
extends GdUnitTestSuite


const PlayerRuntimePolicyScript := preload("res://scripts/components/player_runtime_policy.gd")


func test_tick_physics_state_refreshes_jump_buffer_and_decays_timers() -> void:
	var runtime := PlayerRuntimePolicyScript.tick_physics_state(
		0.2,
		0.1,
		true,
		0.03,
		0.25,
		0.6,
		0.05
	)

	assert_float(runtime.get("delta", 0.0) as float).is_equal(0.1)
	assert_float(runtime.get("jump_buffer_timer", 0.0) as float).is_equal(0.25)
	assert_float(runtime.get("dodge_cooldown_timer", 0.0) as float).is_equal(0.5)
	assert_float(runtime.get("parry_timer", 0.0) as float).is_equal(0.0)


func test_tick_physics_state_never_drives_timers_negative() -> void:
	var runtime := PlayerRuntimePolicyScript.tick_physics_state(
		0.05,
		0.1,
		false,
		0.01,
		0.25,
		0.02,
		0.03
	)

	assert_float(runtime.get("jump_buffer_timer", -1.0) as float).is_equal(0.0)
	assert_float(runtime.get("dodge_cooldown_timer", -1.0) as float).is_equal(0.0)
	assert_float(runtime.get("parry_timer", -1.0) as float).is_equal(0.0)


func test_resolve_guard_state_opens_parry_window_on_press() -> void:
	var state := PlayerRuntimePolicyScript.resolve_guard_state(true, true, 0.18, 0.02)

	assert_bool(state.get("block_held", false) as bool).is_true()
	assert_float(state.get("parry_timer", 0.0) as float).is_equal(0.18)


func test_resolve_guard_state_clears_parry_when_block_is_released() -> void:
	var state := PlayerRuntimePolicyScript.resolve_guard_state(false, false, 0.18, 0.12)

	assert_bool(state.get("block_held", true) as bool).is_false()
	assert_float(state.get("parry_timer", -1.0) as float).is_equal(0.0)


func test_compute_gravity_velocity_uses_fall_multiplier_and_terminal_clamp() -> void:
	var next_velocity := PlayerRuntimePolicyScript.compute_gravity_velocity(
		-10.0,
		false,
		0.5,
		20.0,
		2.0,
		24.0
	)

	assert_float(next_velocity).is_equal(-24.0)


func test_resolve_fall_recovery_resets_position_and_vertical_speed() -> void:
	var recovery := PlayerRuntimePolicyScript.resolve_fall_recovery(
		Vector3(2.0, -3.0, 1.0),
		Vector3(4.0, -7.0, -2.0),
		-2.0,
		0.1
	)
	var next_position := recovery.get("position", Vector3.ZERO) as Vector3
	var next_velocity := recovery.get("velocity", Vector3.ZERO) as Vector3

	assert_bool(recovery.get("recovered", false) as bool).is_true()
	assert_vector(next_position).is_equal(Vector3(2.0, 0.1, 1.0))
	assert_vector(next_velocity).is_equal(Vector3(4.0, 0.0, -2.0))
