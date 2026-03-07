## Unit tests for camera wall-occlusion safety helpers.
class_name TestCameraFollow
extends GdUnitTestSuite


const CameraLockOnPresentationScript := preload("res://scripts/components/camera_lock_on_presentation.gd")


class MockLockOwner extends CharacterBody3D:
	var lock_target: Node3D = null
	var facing_direction: Vector3 = Vector3.RIGHT


var _camera: CameraFollow
var _presentation
var _spawned: Array[Node] = []


func before_test() -> void:
	_camera = CameraFollow.new()
	_presentation = CameraLockOnPresentationScript.new()
	add_child(_camera)
	_spawned.append(_camera)


func after_test() -> void:
	for idx in range(_spawned.size() - 1, -1, -1):
		var node := _spawned[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()
	_camera = null
	_presentation = null


func test_compute_occlusion_safe_position_stops_before_hit_point() -> void:
	var focus := Vector3.ZERO
	var desired := Vector3(10.0, 0.0, 0.0)
	var hit := Vector3(8.0, 0.0, 0.0)
	var safe := _camera._compute_occlusion_safe_position(focus, desired, hit)
	assert_float(safe.x).is_equal_approx(8.0 - Constants.CAMERA_OCCLUSION_PADDING, 0.001)
	assert_float(safe.y).is_equal(0.0)
	assert_float(safe.z).is_equal(0.0)


func test_compute_occlusion_safe_position_respects_min_distance() -> void:
	var focus := Vector3.ZERO
	var desired := Vector3(10.0, 0.0, 0.0)
	var hit := Vector3(1.0, 0.0, 0.0)
	var safe := _camera._compute_occlusion_safe_position(focus, desired, hit)
	assert_float(safe.x).is_equal_approx(Constants.CAMERA_OCCLUSION_MIN_DISTANCE, 0.001)


func test_compute_occlusion_safe_position_preserves_direction() -> void:
	var focus := Vector3(1.0, 1.0, 1.0)
	var desired := Vector3(7.0, 4.0, 1.0)
	var hit := Vector3(5.0, 3.0, 1.0)
	var safe := _camera._compute_occlusion_safe_position(focus, desired, hit)
	var safe_direction := (safe - focus).normalized()
	var desired_direction := (desired - focus).normalized()
	assert_float(safe_direction.x).is_equal_approx(desired_direction.x, 0.001)
	assert_float(safe_direction.y).is_equal_approx(desired_direction.y, 0.001)
	assert_float(safe_direction.z).is_equal_approx(desired_direction.z, 0.001)


func test_lock_on_profile_tightens_close_pair_framing() -> void:
	var close_profile: Dictionary = _presentation.build_profile(Vector3.ZERO, Vector3(2.2, 0.0, 0.0), Vector3.RIGHT)
	var far_profile: Dictionary = _presentation.build_profile(Vector3.ZERO, Vector3(8.0, 0.0, 0.0), Vector3.RIGHT)

	assert_float(float(close_profile.get("distance", 0.0))).is_less(float(far_profile.get("distance", 0.0)))
	assert_float(float(close_profile.get("shoulder", 0.0))).is_less(float(far_profile.get("shoulder", 0.0)))
	assert_float(float(close_profile.get("look_ahead_scale", 0.0))).is_less(float(far_profile.get("look_ahead_scale", 0.0)))
	assert_float(float(close_profile.get("deadzone_scale", 0.0))).is_less(float(far_profile.get("deadzone_scale", 0.0)))


func test_lock_on_profile_focuses_between_player_and_target() -> void:
	var profile: Dictionary = _presentation.build_profile(Vector3.ZERO, Vector3(4.0, 0.0, 0.0), Vector3.RIGHT)
	var focus := profile.get("focus", Vector3.ZERO) as Vector3

	assert_float(focus.x).is_greater(1.0)
	assert_float(focus.x).is_less(3.0)
	assert_float(focus.y).is_greater(1.0)


func test_occlusion_samples_expand_when_lock_target_is_present() -> void:
	var owner := MockLockOwner.new()
	var enemy := Node3D.new()
	add_child(owner)
	add_child(enemy)
	_spawned.append(owner)
	_spawned.append(enemy)
	owner.position = Vector3.ZERO
	enemy.position = Vector3(4.0, 0.0, 0.0)
	owner.lock_target = enemy

	_camera._target = owner
	_camera._follow_forward = Vector3.RIGHT
	var focus := _camera._get_focus_point()
	var samples := _camera._get_occlusion_focus_samples(focus)
	var target_focus := enemy.global_position + Vector3.UP * 1.2
	var has_target_focus := false

	for sample in samples:
		if (sample as Vector3).distance_to(target_focus) <= 0.001:
			has_target_focus = true
			break

	assert_array(samples).has_size(10)
	assert_bool(has_target_focus).is_true()


func test_reset_manual_camera_restores_exported_defaults() -> void:
	_camera.default_manual_zoom = 0.9
	_camera.default_orbit_yaw = 0.18
	_camera.default_orbit_pitch = 0.12
	_camera._manual_zoom = 1.4
	_camera._orbit_yaw = -0.4
	_camera._orbit_pitch = -0.2

	_camera._reset_manual_camera()

	assert_float(_camera._manual_zoom).is_equal_approx(0.9, 0.001)
	assert_float(_camera._orbit_yaw).is_equal_approx(0.18, 0.001)
	assert_float(_camera._orbit_pitch).is_equal_approx(0.12, 0.001)
