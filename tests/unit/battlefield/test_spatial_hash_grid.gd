class_name TestSpatialHashGrid
extends GdUnitTestSuite


var _grid: SpatialHashGrid
var _out: PackedInt32Array


func before_test() -> void:
	_grid = SpatialHashGrid.new(2.0)
	_out = PackedInt32Array()


func _sorted(arr: PackedInt32Array) -> Array:
	var a := Array(arr)
	a.sort()
	return a


func test_query_finds_points_within_radius() -> void:
	_grid.insert(0, Vector2(0, 0))
	_grid.insert(1, Vector2(1, 0))
	_grid.insert(2, Vector2(5, 5))
	_grid.query_radius(Vector2(0, 0), 1.5, _out)
	assert_array(_sorted(_out)).is_equal([0, 1])


func test_query_crosses_cell_boundaries() -> void:
	_grid.insert(0, Vector2(1.9, 1.9))
	_grid.insert(1, Vector2(2.1, 2.1))
	_grid.query_radius(Vector2(2.0, 2.0), 0.5, _out)
	assert_array(_sorted(_out)).is_equal([0, 1])


func test_negative_coordinates() -> void:
	_grid.insert(3, Vector2(-3.0, -7.0))
	_grid.query_radius(Vector2(-3.2, -6.8), 0.5, _out)
	assert_array(_sorted(_out)).is_equal([3])


func test_radius_is_inclusive_distance_not_cell() -> void:
	_grid.insert(0, Vector2(0, 0))
	_grid.insert(1, Vector2(1.9, 0))
	_grid.query_radius(Vector2(0, 0), 1.0, _out)
	assert_array(_sorted(_out)).is_equal([0])


func test_clear_removes_everything() -> void:
	_grid.insert(0, Vector2(0, 0))
	_grid.clear()
	_grid.query_radius(Vector2(0, 0), 10.0, _out)
	assert_int(_out.size()).is_equal(0)


func test_query_resets_output_buffer() -> void:
	_grid.insert(0, Vector2(0, 0))
	_out.append(42)
	_grid.query_radius(Vector2(0, 0), 1.0, _out)
	assert_array(_sorted(_out)).is_equal([0])


func test_many_points_query_matches_brute_force() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var pts: Array[Vector2] = []
	for i in 200:
		var p := Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		pts.append(p)
		_grid.insert(i, p)
	var center := Vector2(3, -4)
	var expected: Array = []
	for i in pts.size():
		if pts[i].distance_to(center) <= 6.0:
			expected.append(i)
	_grid.query_radius(center, 6.0, _out)
	assert_array(_sorted(_out)).is_equal(expected)


func test_separation_sum_matches_pairwise_steering() -> void:
	_grid.insert(0, Vector2(0, 0))
	_grid.insert(1, Vector2(0.5, 0))
	_grid.insert(2, Vector2(0, -0.4))
	_grid.insert(3, Vector2(9, 9))
	var expected := HordeSteering.separation(Vector2(0, 0), Vector2(0.5, 0), 1.0) \
		+ HordeSteering.separation(Vector2(0, 0), Vector2(0, -0.4), 1.0)
	var got := _grid.separation_sum(0, 1.0)
	assert_float(got.distance_to(expected)).is_less(0.0001)


func test_separation_sum_ignores_unknown_id() -> void:
	_grid.insert(0, Vector2(0, 0))
	assert_vector(_grid.separation_sum(5, 1.0)).is_equal(Vector2.ZERO)
