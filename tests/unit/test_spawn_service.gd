## Tests for SpawnService — position validation.
extends GdUnitTestSuite


func test_valid_position_inside_bounds() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(0, 0, 0),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_true()


func test_valid_position_at_min_bound() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(-10, 0, -5),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_true()


func test_valid_position_at_max_bound() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(10, 0, 5),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_true()


func test_invalid_position_outside_x() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(15, 0, 0),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_false()


func test_invalid_position_outside_z() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(0, 0, 10),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_false()


func test_invalid_position_below_y() -> void:
	var result: bool = SpawnService.is_valid_spawn_position(
		Vector3(0, -1, 0),
		Vector3(-10, 0, -5),
		Vector3(10, 0, 5)
	)
	assert_bool(result).is_false()
