class_name TestHordeSteering
extends GdUnitTestSuite


func test_ring_slot_is_at_radius() -> void:
	var p := HordeSteering.ring_slot(Vector2(3, 4), 5, 12, 2.0)
	assert_float(p.distance_to(Vector2(3, 4))).is_equal_approx(2.0, 0.0001)


func test_ring_slots_are_distinct() -> void:
	var a := HordeSteering.ring_slot(Vector2.ZERO, 0, 8, 3.0)
	var b := HordeSteering.ring_slot(Vector2.ZERO, 1, 8, 3.0)
	assert_float(a.distance_to(b)).is_greater(1.0)


func test_ring_slot_handles_zero_count() -> void:
	var p := HordeSteering.ring_slot(Vector2.ZERO, 0, 0, 3.0)
	assert_float(p.length()).is_equal_approx(3.0, 0.0001)


func test_separation_pushes_away_from_neighbour() -> void:
	var push := HordeSteering.separation(Vector2(0, 0), Vector2(0.5, 0), 1.0)
	assert_float(push.x).is_less(0.0)
	assert_float(push.y).is_equal_approx(0.0, 0.0001)


func test_separation_zero_outside_radius() -> void:
	var push := HordeSteering.separation(Vector2(0, 0), Vector2(2, 0), 1.0)
	assert_vector(push).is_equal(Vector2.ZERO)


func test_separation_stronger_when_closer() -> void:
	var near := HordeSteering.separation(Vector2(0, 0), Vector2(0.2, 0), 1.0)
	var far := HordeSteering.separation(Vector2(0, 0), Vector2(0.8, 0), 1.0)
	assert_float(near.length()).is_greater(far.length())


func test_separation_coincident_points_still_push() -> void:
	var push := HordeSteering.separation(Vector2(1, 1), Vector2(1, 1), 1.0)
	assert_float(push.length()).is_greater(0.0)


func test_seek_clamps_to_speed() -> void:
	var v := HordeSteering.seek(Vector2.ZERO, Vector2(100, 0), 4.0, 0.5)
	assert_float(v.length()).is_equal_approx(4.0, 0.0001)


func test_seek_arrives_inside_stop_distance() -> void:
	var v := HordeSteering.seek(Vector2.ZERO, Vector2(0.3, 0), 4.0, 0.5)
	assert_vector(v).is_equal(Vector2.ZERO)


func test_in_strike_arc() -> void:
	# Facing +X, target slightly ahead.
	assert_bool(HordeSteering.in_strike_arc(Vector2.ZERO, Vector2(1, 0), Vector2(1.2, 0.2), 1.6, 0.5)).is_true()
	# Behind.
	assert_bool(HordeSteering.in_strike_arc(Vector2.ZERO, Vector2(1, 0), Vector2(-1.0, 0.0), 1.6, 0.5)).is_false()
	# Too far.
	assert_bool(HordeSteering.in_strike_arc(Vector2.ZERO, Vector2(1, 0), Vector2(3.0, 0.0), 1.6, 0.5)).is_false()
