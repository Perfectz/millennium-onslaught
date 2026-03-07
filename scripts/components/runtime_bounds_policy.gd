## Pure policy helpers for resolving and applying active runtime bounds.
class_name RuntimeBoundsPolicy
extends RefCounted


const DEFAULT_MIN_X := -100.0
const DEFAULT_MAX_X := 100.0
const DEFAULT_MIN_Z := -100.0
const DEFAULT_MAX_Z := 100.0


static func default_bounds() -> Dictionary:
	return {
		"min_x": DEFAULT_MIN_X,
		"max_x": DEFAULT_MAX_X,
		"min_z": DEFAULT_MIN_Z,
		"max_z": DEFAULT_MAX_Z,
		"source": "default",
	}


static func clamp_position(position: Vector3, bounds: Dictionary) -> Vector3:
	var normalized := _normalize_bounds(bounds)
	return Vector3(
		clampf(position.x, float(normalized.get("min_x", DEFAULT_MIN_X)), float(normalized.get("max_x", DEFAULT_MAX_X))),
		position.y,
		clampf(position.z, float(normalized.get("min_z", DEFAULT_MIN_Z)), float(normalized.get("max_z", DEFAULT_MAX_Z)))
	)


static func apply_soft_pushback(
	position: Vector3,
	velocity: Vector3,
	bounds: Dictionary,
	zone: float,
	force: float
) -> Dictionary:
	var normalized := _normalize_bounds(bounds)
	var next_velocity := velocity
	var min_x := float(normalized.get("min_x", DEFAULT_MIN_X))
	var max_x := float(normalized.get("max_x", DEFAULT_MAX_X))
	var min_z := float(normalized.get("min_z", DEFAULT_MIN_Z))
	var max_z := float(normalized.get("max_z", DEFAULT_MAX_Z))

	if zone > 0.0 and force > 0.0:
		if position.x < min_x + zone:
			var left_ratio := 1.0 - clampf((position.x - min_x) / zone, 0.0, 1.0)
			next_velocity.x = maxf(next_velocity.x, left_ratio * force)
		elif position.x > max_x - zone:
			var right_ratio := 1.0 - clampf((max_x - position.x) / zone, 0.0, 1.0)
			next_velocity.x = minf(next_velocity.x, -right_ratio * force)

		if position.z < min_z + zone:
			var top_ratio := 1.0 - clampf((position.z - min_z) / zone, 0.0, 1.0)
			next_velocity.z = maxf(next_velocity.z, top_ratio * force)
		elif position.z > max_z - zone:
			var bottom_ratio := 1.0 - clampf((max_z - position.z) / zone, 0.0, 1.0)
			next_velocity.z = minf(next_velocity.z, -bottom_ratio * force)

	return {
		"position": clamp_position(position, normalized),
		"velocity": next_velocity,
	}


static func scale_edge_knockback_x(
	raw_knockback_x: float,
	position_x: float,
	bounds: Dictionary,
	safe_margin: float,
	min_scale: float
) -> float:
	if is_zero_approx(raw_knockback_x):
		return 0.0
	var normalized := _normalize_bounds(bounds)
	if str(normalized.get("source", "default")) != "room":
		return raw_knockback_x

	var min_x := float(normalized.get("min_x", DEFAULT_MIN_X))
	var max_x := float(normalized.get("max_x", DEFAULT_MAX_X))
	var distance_to_edge := position_x - min_x if raw_knockback_x < 0.0 else max_x - position_x
	var margin := maxf(safe_margin, 0.001)
	var edge_scale := clampf(distance_to_edge / margin, min_scale, 1.0)
	return raw_knockback_x * edge_scale


static func _normalize_bounds(bounds: Dictionary) -> Dictionary:
	var normalized := default_bounds()
	if bounds.is_empty():
		return normalized
	for key in ["min_x", "max_x", "min_z", "max_z"]:
		if key in bounds:
			normalized[key] = float(bounds.get(key, normalized[key]))
	normalized["source"] = str(bounds.get("source", normalized["source"]))
	return normalized
