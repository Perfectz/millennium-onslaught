## Shared spawn placement helper.
## Clamps requested positions to bounds and nudges them away from environment walls.
class_name SpawnPositionResolver
extends RefCounted


const _QUERY_HEIGHT := 1.2
const _QUERY_Y_OFFSET := 1.45
const _SAMPLE_STEP := 0.75
const _SAMPLE_OFFSETS := [
	Vector2.ZERO,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(1.0, 1.0),
	Vector2(1.0, -1.0),
	Vector2(-1.0, 1.0),
	Vector2(-1.0, -1.0),
	Vector2(2.0, 0.0),
	Vector2(-2.0, 0.0),
	Vector2(0.0, 2.0),
	Vector2(0.0, -2.0),
	Vector2(2.0, 1.0),
	Vector2(2.0, -1.0),
	Vector2(-2.0, 1.0),
	Vector2(-2.0, -1.0),
	Vector2(1.0, 2.0),
	Vector2(1.0, -2.0),
	Vector2(-1.0, 2.0),
	Vector2(-1.0, -2.0),
	Vector2(3.0, 0.0),
	Vector2(-3.0, 0.0),
	Vector2(0.0, 3.0),
	Vector2(0.0, -3.0),
	Vector2(3.0, 1.0),
	Vector2(3.0, -1.0),
	Vector2(-3.0, 1.0),
	Vector2(-3.0, -1.0),
]


static func resolve_position(
		world_3d: World3D,
		desired: Vector3,
		min_x: float,
		max_x: float,
		min_z: float,
		max_z: float,
		radius: float
	) -> Vector3:
	var resolved := desired
	var clamped_x := _clamp_axis(desired.x, min_x, max_x, radius)
	var clamped_z := _clamp_axis(desired.z, min_z, max_z, radius)
	resolved.x = clamped_x
	resolved.z = clamped_z

	if world_3d == null:
		return resolved
	if _is_clear(world_3d, resolved, radius):
		return resolved

	for offset: Vector2 in _SAMPLE_OFFSETS:
		if offset == Vector2.ZERO:
			continue
		var candidate := resolved
		candidate.x = _clamp_axis(resolved.x + offset.x * _SAMPLE_STEP, min_x, max_x, radius)
		candidate.z = _clamp_axis(resolved.z + offset.y * _SAMPLE_STEP, min_z, max_z, radius)
		if _is_clear(world_3d, candidate, radius):
			return candidate

	return resolved


static func _clamp_axis(value: float, min_value: float, max_value: float, radius: float) -> float:
	var inner_min := minf(min_value, max_value) + radius
	var inner_max := maxf(min_value, max_value) - radius
	if inner_min > inner_max:
		return (min_value + max_value) * 0.5
	return clampf(value, inner_min, inner_max)


static func _is_clear(world_3d: World3D, position: Vector3, radius: float) -> bool:
	var space_state := world_3d.direct_space_state
	if space_state == null:
		return true

	var shape := BoxShape3D.new()
	shape.size = Vector3(radius * 2.0, _QUERY_HEIGHT, radius * 2.0)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, Vector3(
		position.x,
		position.y + _QUERY_Y_OFFSET,
		position.z
	))
	query.collision_mask = Constants.LAYER_ENVIRONMENT
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.margin = 0.01

	return space_state.intersect_shape(query, 1).is_empty()
