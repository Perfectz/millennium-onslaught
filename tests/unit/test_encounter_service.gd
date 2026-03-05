## Tests for EncounterService — encounter generation, validation, positions.
extends GdUnitTestSuite


var _valid_encounter: Dictionary = {
	"waves": [
		{
			"enemy_types": [&"rusher", &"ranger"],
			"count_range": [2, 4],
		},
		{
			"enemy_types": [&"rusher"],
			"count_range": [3, 3],
		},
	]
}


func test_generate_encounter_produces_correct_wave_count() -> void:
	var waves: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, 42)
	assert_int(waves.size()).is_equal(2)


func test_generate_encounter_respects_count_range() -> void:
	var waves: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, 42)
	var first_wave: Dictionary = waves[0]
	var count: int = first_wave["count"]
	assert_int(count).is_between(2, 4)


func test_generate_encounter_fixed_count() -> void:
	var waves: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, 42)
	var second_wave: Dictionary = waves[1]
	assert_int(second_wave["count"]).is_equal(3)


func test_generate_encounter_same_seed_same_result() -> void:
	var a: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, 42)
	var b: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, 42)
	assert_int(a[0]["count"]).is_equal(b[0]["count"])


func test_generate_encounter_different_seed_may_differ() -> void:
	# Run with many seeds and check at least one differs.
	var results: Array[int] = []
	for seed_val: int in range(10):
		var waves: Array[Dictionary] = EncounterService.generate_encounter(_valid_encounter, seed_val)
		results.append(waves[0]["count"])
	# At least two different counts in 10 seeds.
	var unique := {}
	for r: int in results:
		unique[r] = true
	assert_int(unique.size()).is_greater(1)


func test_generate_spawn_positions_correct_count() -> void:
	var positions: Array[Vector3] = EncounterService.generate_spawn_positions(
		5, Vector3(-10, 0, -5), Vector3(10, 0, 5), 1.0, 42
	)
	assert_int(positions.size()).is_equal(5)


func test_generate_spawn_positions_within_bounds() -> void:
	var room_min := Vector3(-10, 0, -5)
	var room_max := Vector3(10, 0, 5)
	var positions: Array[Vector3] = EncounterService.generate_spawn_positions(
		10, room_min, room_max, 1.0, 42
	)
	for pos: Vector3 in positions:
		assert_float(pos.x).is_between(room_min.x, room_max.x)
		assert_float(pos.z).is_between(room_min.z, room_max.z)


func test_generate_spawn_positions_respect_spacing() -> void:
	var positions: Array[Vector3] = EncounterService.generate_spawn_positions(
		5, Vector3(-10, 0, -5), Vector3(10, 0, 5), 2.0, 42
	)
	for i: int in positions.size():
		for j: int in range(i + 1, positions.size()):
			var dist: float = positions[i].distance_to(positions[j])
			assert_float(dist).is_greater_equal(2.0)


func test_validate_encounter_def_valid() -> void:
	var errors: Array[String] = EncounterService.validate_encounter_def(_valid_encounter)
	assert_int(errors.size()).is_equal(0)


func test_validate_encounter_def_missing_waves() -> void:
	var errors: Array[String] = EncounterService.validate_encounter_def({})
	assert_int(errors.size()).is_greater(0)
	assert_str(errors[0]).contains("waves")


func test_validate_encounter_def_empty_waves() -> void:
	var errors: Array[String] = EncounterService.validate_encounter_def({"waves": []})
	assert_int(errors.size()).is_greater(0)


func test_validate_encounter_def_missing_enemy_types() -> void:
	var bad_def: Dictionary = {"waves": [{"count_range": [1, 2]}]}
	var errors: Array[String] = EncounterService.validate_encounter_def(bad_def)
	assert_int(errors.size()).is_greater(0)
	assert_str(errors[0]).contains("enemy_types")


func test_validate_encounter_def_missing_count_range() -> void:
	var bad_def: Dictionary = {"waves": [{"enemy_types": [&"rusher"]}]}
	var errors: Array[String] = EncounterService.validate_encounter_def(bad_def)
	assert_int(errors.size()).is_greater(0)
	assert_str(errors[0]).contains("count_range")
