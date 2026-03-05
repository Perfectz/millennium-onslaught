# GdUnit4 Test Suite for GameState
extends GdUnitTestSuite

var _game_state: GameStateSingleton


func before_test():
	_game_state = GameStateSingleton.new()


func after_test():
	_game_state.free()


func test_gold_management():
	# Initial state — gold is a public var, default 0.
	assert_int(_game_state.gold).is_equal(0)

	# Add gold.
	_game_state.gold += 100
	assert_int(_game_state.gold).is_equal(100)

	# Spend gold.
	_game_state.gold -= 40
	assert_int(_game_state.gold).is_equal(60)


func test_transient_reset():
	# Simulate dungeon progress using actual transient fields.
	_game_state.current_room_index = 5
	_game_state.dungeon_drops.append({"name": "Iron Sword"})

	# Reset via reset_dungeon().
	_game_state.reset_dungeon()

	# Verify reset.
	assert_int(_game_state.current_room_index).is_equal(0)
	assert_array(_game_state.dungeon_drops).is_empty()


func test_deserialize_validation():
	# Valid data with all required fields.
	var valid_data := {
		"save_version": Constants.SAVE_VERSION,
		"party_roster": [],
		"character_data": {},
		"inventory": [],
		"gold": 50,
		"story_flags": {},
		"active_party": [],
		"current_overworld_node": "piata",
	}
	assert_bool(_game_state.deserialize_persistent(valid_data)).is_true()
	assert_int(_game_state.gold).is_equal(50)

	# Future version should be rejected.
	var future_version := {"save_version": 9999, "gold": 999}
	assert_bool(_game_state.deserialize_persistent(future_version)).is_false()
