## Pure regression coverage for runtime bounds policy helpers.
class_name TestRuntimeBoundsPolicy
extends GdUnitTestSuite


const RuntimeBoundsPolicyScript := preload("res://scripts/components/runtime_bounds_policy.gd")


func test_clamp_position_limits_x_and_z_to_bounds() -> void:
	var position := Vector3(14.0, 2.0, -9.0)
	var bounds := {
		"min_x": 2.0,
		"max_x": 10.0,
		"min_z": -4.0,
		"max_z": 3.0,
		"source": "room",
	}

	var clamped: Vector3 = RuntimeBoundsPolicyScript.clamp_position(position, bounds)

	assert_vector(clamped).is_equal(Vector3(10.0, 2.0, -4.0))


func test_apply_soft_pushback_pushes_velocity_near_edge() -> void:
	var position := Vector3(9.4, 0.0, 2.8)
	var velocity := Vector3.ZERO
	var bounds := {
		"min_x": 0.0,
		"max_x": 10.0,
		"min_z": -3.0,
		"max_z": 3.0,
		"source": "room",
	}

	var resolved: Dictionary = RuntimeBoundsPolicyScript.apply_soft_pushback(position, velocity, bounds, 2.0, 12.0)
	var next_velocity := resolved.get("velocity", Vector3.ZERO) as Vector3

	assert_float(next_velocity.x).is_less(0.0)
	assert_float(next_velocity.z).is_less(0.0)
	assert_vector(resolved.get("position", Vector3.ZERO) as Vector3).is_equal(position)


func test_scale_edge_knockback_x_scales_room_knockback_near_edge() -> void:
	var bounds := {
		"min_x": 0.0,
		"max_x": 10.0,
		"min_z": -3.0,
		"max_z": 3.0,
		"source": "room",
	}

	var scaled: float = RuntimeBoundsPolicyScript.scale_edge_knockback_x(-8.0, 0.3, bounds, 1.2, 0.0)

	assert_float(scaled).is_less(-0.1)
	assert_float(absf(scaled)).is_less(8.0)


func test_scale_edge_knockback_x_ignores_non_room_bounds() -> void:
	var arena_bounds := {
		"min_x": 4.0,
		"max_x": 16.0,
		"min_z": -5.0,
		"max_z": 5.0,
		"source": "arena",
	}

	var scaled: float = RuntimeBoundsPolicyScript.scale_edge_knockback_x(6.0, 15.7, arena_bounds, 1.2, 0.0)

	assert_float(scaled).is_equal(6.0)
