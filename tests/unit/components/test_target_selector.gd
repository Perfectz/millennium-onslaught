## TDD tests for TargetSelector — closest alive target selection logic.
class_name TestTargetSelector
extends GdUnitTestSuite


var _selector: TargetSelector


func before_test() -> void:
	_selector = TargetSelector.new()


func test_empty_candidates_returns_neg1() -> void:
	var result := _selector.select_closest(Vector3.ZERO, [])
	assert_int(result).is_equal(-1)


func test_single_alive_candidate_returns_0() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(5, 0, 0), "alive": true},
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(0)


func test_returns_closest_of_two_alive() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(10, 0, 0), "alive": true},
		{"position": Vector3(3, 0, 0), "alive": true},
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(1)


func test_skips_dead_candidates() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(1, 0, 0), "alive": false},
		{"position": Vector3(5, 0, 0), "alive": true},
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(1)


func test_all_dead_returns_closest_dead() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(10, 0, 0), "alive": false},
		{"position": Vector3(2, 0, 0), "alive": false},
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(1)


func test_three_candidates_different_distances() -> void:
	var origin := Vector3(5, 0, 0)
	var candidates: Array[Dictionary] = [
		{"position": Vector3(0, 0, 0), "alive": true},   # dist 5
		{"position": Vector3(6, 0, 0), "alive": true},   # dist 1
		{"position": Vector3(15, 0, 0), "alive": true},  # dist 10
	]
	assert_int(_selector.select_closest(origin, candidates)).is_equal(1)


func test_prefers_alive_over_closer_dead() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(1, 0, 0), "alive": false},   # closest but dead
		{"position": Vector3(10, 0, 0), "alive": true},   # far but alive
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(1)


func test_zero_origin_works() -> void:
	var candidates: Array[Dictionary] = [
		{"position": Vector3(3, 4, 0), "alive": true},   # dist 5
		{"position": Vector3(1, 0, 0), "alive": true},   # dist 1
	]
	assert_int(_selector.select_closest(Vector3.ZERO, candidates)).is_equal(1)
