class_name TestWorldLabelPlacement
extends GdUnitTestSuite


const FWD := Vector3(0, 0, -1)


func test_point_in_front_is_placeable() -> void:
	assert_bool(WorldLabelPlacement.is_placeable(Vector3.ZERO, FWD, Vector3(0, 0, -10), 2.5)).is_true()


func test_point_behind_camera_is_rejected() -> void:
	assert_bool(WorldLabelPlacement.is_placeable(Vector3.ZERO, FWD, Vector3(0, 0, 3), 2.5)).is_false()


func test_point_too_close_is_rejected() -> void:
	assert_bool(WorldLabelPlacement.is_placeable(Vector3.ZERO, FWD, Vector3(1, 0, -1), 2.5)).is_false()


func test_depth_is_measured_along_view_axis() -> void:
	# Far to the side but only 1 m deep: still too close to the view plane.
	assert_bool(WorldLabelPlacement.is_placeable(Vector3.ZERO, FWD, Vector3(20, 0, -1), 2.5)).is_false()
