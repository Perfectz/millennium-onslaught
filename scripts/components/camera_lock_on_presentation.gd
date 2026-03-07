## Presentation-only framing profile for keeping a lock pair readable.
class_name CameraLockOnPresentation
extends RefCounted


const PLAYER_FOCUS_HEIGHT: float = 1.6
const TARGET_FOCUS_HEIGHT: float = 1.2
const CLOSE_PAIR_DISTANCE: float = 2.4
const FAR_PAIR_DISTANCE: float = 9.0
const CLOSE_CAMERA_DISTANCE: float = 6.1
const FAR_CAMERA_DISTANCE: float = 7.0
const CLOSE_CAMERA_HEIGHT: float = 5.15
const FAR_CAMERA_HEIGHT: float = 4.85
const CLOSE_SHOULDER_OFFSET: float = 0.12
const FAR_SHOULDER_OFFSET: float = 0.55
const CLOSE_FOCUS_BIAS: float = 0.52
const FAR_FOCUS_BIAS: float = 0.38
const CLOSE_FORWARD_BIAS: float = 0.1
const FAR_FORWARD_BIAS: float = 0.4
const CLOSE_LOOK_AHEAD_SCALE: float = 0.2
const FAR_LOOK_AHEAD_SCALE: float = 0.55
const CLOSE_DEADZONE_SCALE: float = 0.45
const FAR_DEADZONE_SCALE: float = 0.7
const CLOSE_THREAT_BIAS_SCALE: float = 0.25
const FAR_THREAT_BIAS_SCALE: float = 0.55


func build_profile(player_position: Vector3, target_position: Vector3, orbit_forward: Vector3) -> Dictionary:
	var follow_forward := orbit_forward
	follow_forward.y = 0.0
	if follow_forward.length_squared() <= 0.001:
		follow_forward = Vector3.RIGHT
	else:
		follow_forward = follow_forward.normalized()

	var planar_to_target := target_position - player_position
	planar_to_target.y = 0.0
	var pair_distance := planar_to_target.length()
	var distance_t := clampf(
		inverse_lerp(CLOSE_PAIR_DISTANCE, FAR_PAIR_DISTANCE, pair_distance),
		0.0,
		1.0
	)

	var focus := player_position + Vector3.UP * PLAYER_FOCUS_HEIGHT
	var target_focus := target_position + Vector3.UP * TARGET_FOCUS_HEIGHT
	focus = focus.lerp(target_focus, lerpf(CLOSE_FOCUS_BIAS, FAR_FOCUS_BIAS, distance_t))
	focus += follow_forward * lerpf(CLOSE_FORWARD_BIAS, FAR_FORWARD_BIAS, distance_t)

	return {
		"focus": focus,
		"distance": lerpf(CLOSE_CAMERA_DISTANCE, FAR_CAMERA_DISTANCE, distance_t),
		"height": lerpf(CLOSE_CAMERA_HEIGHT, FAR_CAMERA_HEIGHT, distance_t),
		"shoulder": lerpf(CLOSE_SHOULDER_OFFSET, FAR_SHOULDER_OFFSET, distance_t),
		"look_ahead_scale": lerpf(CLOSE_LOOK_AHEAD_SCALE, FAR_LOOK_AHEAD_SCALE, distance_t),
		"deadzone_scale": lerpf(CLOSE_DEADZONE_SCALE, FAR_DEADZONE_SCALE, distance_t),
		"threat_bias_scale": lerpf(CLOSE_THREAT_BIAS_SCALE, FAR_THREAT_BIAS_SCALE, distance_t),
		"close_quarters_blend": 1.0 - distance_t,
		"pair_distance": pair_distance,
	}
