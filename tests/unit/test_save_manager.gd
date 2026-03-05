## Tests for SaveManager — save/load integrity, missing files, atomic writes.
extends GdUnitTestSuite


const TEST_SLOT: int = 99


func before_test() -> void:
	# Clean test slot.
	SaveManager.delete_save(TEST_SLOT)
	# Reset GameState.
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.inventory.clear()
	GameState.gold = 0
	GameState.story_flags.clear()
	GameState.active_party.clear()


func after_test() -> void:
	SaveManager.delete_save(TEST_SLOT)


func test_has_save_returns_false_for_missing() -> void:
	assert_bool(SaveManager.has_save(TEST_SLOT)).is_false()


func test_save_creates_file() -> void:
	GameState.gold = 100
	var result: bool = SaveManager.save_game(TEST_SLOT)
	assert_bool(result).is_true()
	assert_bool(SaveManager.has_save(TEST_SLOT)).is_true()


func test_save_load_round_trip() -> void:
	GameState.party_roster = [&"chaz"]
	GameState.gold = 250
	GameState.init_character(&"chaz")
	SaveManager.save_game(TEST_SLOT)
	# Clear state.
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.gold = 0
	# Load.
	var result: bool = SaveManager.load_game(TEST_SLOT)
	assert_bool(result).is_true()
	assert_int(GameState.gold).is_equal(250)
	assert_int(GameState.party_roster.size()).is_equal(1)


func test_load_nonexistent_returns_false() -> void:
	var result: bool = SaveManager.load_game(TEST_SLOT)
	assert_bool(result).is_false()


func test_delete_save_removes_file() -> void:
	GameState.gold = 50
	SaveManager.save_game(TEST_SLOT)
	assert_bool(SaveManager.has_save(TEST_SLOT)).is_true()
	SaveManager.delete_save(TEST_SLOT)
	assert_bool(SaveManager.has_save(TEST_SLOT)).is_false()


func test_save_overwrites_previous() -> void:
	GameState.gold = 100
	SaveManager.save_game(TEST_SLOT)
	GameState.gold = 200
	SaveManager.save_game(TEST_SLOT)
	GameState.gold = 0
	SaveManager.load_game(TEST_SLOT)
	assert_int(GameState.gold).is_equal(200)
