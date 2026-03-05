## Integration test for dungeon lifecycle: enter → rooms → clear → exit.
extends GdUnitTestSuite


func test_dungeon_enter_sets_game_state() -> void:
	# Reset state.
	GameState.reset_dungeon()
	GameState.current_dungeon_id = &""
	# Simulate dungeon entry.
	GameState.current_dungeon_id = &"test_dungeon"
	GameState.current_room_index = 0
	GameState.encounter_active = true
	assert_str(GameState.current_dungeon_id).is_equal("test_dungeon")
	assert_int(GameState.current_room_index).is_equal(0)
	assert_bool(GameState.encounter_active).is_true()


func test_room_progression_updates_index() -> void:
	GameState.current_room_index = 0
	GameState.current_room_index += 1
	assert_int(GameState.current_room_index).is_equal(1)
	GameState.current_room_index += 1
	assert_int(GameState.current_room_index).is_equal(2)


func test_dungeon_failure_resets_transient_state() -> void:
	GameState.current_dungeon_id = &"test_dungeon"
	GameState.current_room_index = 3
	GameState.dungeon_buffs.append({"type": "speed"})
	GameState.dungeon_drops.append({"id": &"potion"})
	GameState.encounter_active = true
	GameState.encounter_enemies_alive = 5
	# Simulate failure.
	GameState.reset_dungeon()
	assert_str(GameState.current_dungeon_id).is_equal("")
	assert_int(GameState.current_room_index).is_equal(0)
	assert_int(GameState.dungeon_buffs.size()).is_equal(0)
	assert_int(GameState.dungeon_drops.size()).is_equal(0)
	assert_bool(GameState.encounter_active).is_false()


func test_dungeon_completion_banks_rewards() -> void:
	GameState.inventory.clear()
	GameState.dungeon_drops.clear()
	GameState.dungeon_drops.append({"id": &"sword", "type": &"weapon"})
	GameState.dungeon_drops.append({"id": &"potion", "type": &"item"})
	# Simulate completion.
	GameState.bank_dungeon_rewards()
	assert_int(GameState.inventory.size()).is_equal(2)
	assert_int(GameState.dungeon_drops.size()).is_equal(0)
	assert_str(GameState.current_dungeon_id).is_equal("")


func test_full_dungeon_lifecycle() -> void:
	# Clean state.
	GameState.reset_dungeon()
	GameState.inventory.clear()
	GameState.gold = 100
	# Enter dungeon.
	GameState.current_dungeon_id = &"dungeon_01"
	GameState.encounter_active = true
	assert_str(GameState.current_dungeon_id).is_equal("dungeon_01")
	# Progress through rooms.
	for room: int in [0, 1, 2]:
		GameState.current_room_index = room
		assert_int(GameState.current_room_index).is_equal(room)
	# Collect drops.
	GameState.dungeon_drops.append({"id": &"gold_coin", "value": 50})
	GameState.dungeon_drops.append({"id": &"iron_sword"})
	# Complete dungeon.
	GameState.bank_dungeon_rewards()
	assert_int(GameState.inventory.size()).is_equal(2)
	assert_str(GameState.current_dungeon_id).is_equal("")
	# Gold should still be preserved.
	assert_int(GameState.gold).is_equal(100)


func test_encounter_generation_for_dungeon() -> void:
	var encounter_def: Dictionary = {
		"waves": [
			{"enemy_types": [&"rusher"], "count_range": [3, 3]},
			{"enemy_types": [&"rusher", &"ranger"], "count_range": [2, 4]},
		]
	}
	var errors: Array[String] = EncounterService.validate_encounter_def(encounter_def)
	assert_int(errors.size()).is_equal(0)
	var waves: Array[Dictionary] = EncounterService.generate_encounter(encounter_def, 42)
	assert_int(waves.size()).is_equal(2)
	assert_int(waves[0]["count"]).is_equal(3)


func test_wave_spawn_positions_valid() -> void:
	var room_min := Vector3(-10, 0, -3)
	var room_max := Vector3(10, 0, 3)
	var positions: Array[Vector3] = EncounterService.generate_spawn_positions(
		5, room_min, room_max, 2.0, 42
	)
	for pos: Vector3 in positions:
		assert_bool(SpawnService.is_valid_spawn_position(pos, room_min, room_max)).is_true()
