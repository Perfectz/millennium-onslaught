## TDD tests for EncounterRoller — validates encounter generation from pool.
class_name TestEncounterRoller
extends GdUnitTestSuite


var _roller: EncounterRoller


func before_test() -> void:
	_roller = EncounterRoller.new()


# --- Enemy Pool Validation ---

func test_roll_from_single_entry_pool() -> void:
	var pool: Array[Dictionary] = [
		{"enemy_type": &"rusher", "count": 3}
	]
	var result := _roller.roll_wave(pool)
	assert_array(result).has_size(1)
	assert_str(result[0].enemy_type).is_equal("rusher")
	assert_int(result[0].count).is_equal(3)


func test_roll_from_multi_entry_pool() -> void:
	var pool: Array[Dictionary] = [
		{"enemy_type": &"rusher", "count": 2},
		{"enemy_type": &"ranged", "count": 1},
		{"enemy_type": &"shield", "count": 1},
	]
	var result := _roller.roll_wave(pool)
	# Should return one of the entries
	assert_array(result).has_size(1)
	var valid_types: Array[StringName] = [&"rusher", &"ranged", &"shield"]
	assert_bool(result[0].enemy_type in valid_types).is_true()


func test_roll_respects_enemy_count() -> void:
	var pool: Array[Dictionary] = [
		{"enemy_type": &"rusher", "count": 5}
	]
	var result := _roller.roll_wave(pool)
	assert_int(result[0].count).is_equal(5)


func test_roll_multi_wave_returns_sequence() -> void:
	var waves: Array[Array] = [
		[{"enemy_type": &"rusher", "count": 2}],
		[{"enemy_type": &"ranged", "count": 1}],
	]
	var result := _roller.roll_encounter(waves)
	assert_int(result.size()).is_equal(2)


func test_empty_pool_returns_empty() -> void:
	var pool: Array[Dictionary] = []
	var result := _roller.roll_wave(pool)
	assert_array(result).is_empty()


func test_total_enemy_count_from_wave() -> void:
	var wave: Array[Dictionary] = [
		{"enemy_type": &"rusher", "count": 3},
		{"enemy_type": &"ranged", "count": 2},
	]
	var total := _roller.count_enemies_in_wave(wave)
	assert_int(total).is_equal(5)


func test_randomization_varies_output() -> void:
	var pool: Array[Dictionary] = [
		{"enemy_type": &"rusher", "count": 2},
		{"enemy_type": &"ranged", "count": 1},
		{"enemy_type": &"shield", "count": 1},
	]
	var results: Dictionary = {}
	for i in 30:
		var result := _roller.roll_wave(pool)
		var key: StringName = result[0].enemy_type
		results[key] = results.get(key, 0) + 1
	# With 30 rolls from 3 options, we expect at least 2 different types chosen
	assert_int(results.size()).is_greater_equal(2)
