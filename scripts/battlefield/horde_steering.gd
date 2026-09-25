## Pure XZ steering math for horde grunts (Vector2 = world X/Z).
class_name HordeSteering
extends RefCounted


## Evenly spaced point on a ring around `center` for slot `index` of `count`.
static func ring_slot(center: Vector2, index: int, count: int, radius: float) -> Vector2:
	var n := maxi(count, 1)
	var angle := TAU * float(index % n) / float(n)
	return center + Vector2(cos(angle), sin(angle)) * radius


## Push `self_pos` away from `other_pos`, growing linearly as they overlap. Zero outside `radius`.
static func separation(self_pos: Vector2, other_pos: Vector2, radius: float) -> Vector2:
	var offset := self_pos - other_pos
	var dist := offset.length()
	if dist >= radius:
		return Vector2.ZERO
	if dist < 0.0001:
		# Coincident: pick a deterministic direction from position so pairs split apart.
		var angle := fposmod(self_pos.x * 12.9898 + self_pos.y * 78.233, TAU)
		return Vector2(cos(angle), sin(angle))
	return offset / dist * (1.0 - dist / radius)


## Velocity toward `target` at `speed`; zero once within `stop_distance`.
static func seek(from: Vector2, target: Vector2, speed: float, stop_distance: float) -> Vector2:
	var offset := target - from
	var dist := offset.length()
	if dist <= stop_distance:
		return Vector2.ZERO
	return offset / dist * speed


## True if `target` is within `reach` and inside the frontal arc (`min_dot` of facing).
static func in_strike_arc(origin: Vector2, facing: Vector2, target: Vector2, reach: float, min_dot: float) -> bool:
	var offset := target - origin
	var dist := offset.length()
	if dist > reach:
		return false
	if dist < 0.0001:
		return true
	return facing.normalized().dot(offset / dist) >= min_dot
