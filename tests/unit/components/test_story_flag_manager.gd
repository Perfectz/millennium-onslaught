## TDD tests for StoryFlagManager — set/get/check story flags, gate node access.
class_name TestStoryFlagManager
extends GdUnitTestSuite


var _flags: StoryFlagManager


func before_test() -> void:
	_flags = StoryFlagManager.new()


# --- Set / Has ---

func test_has_flag_returns_false_for_unset() -> void:
	assert_bool(_flags.has_flag(&"unknown")).is_false()


func test_set_flag_stores_value() -> void:
	_flags.set_flag(&"dungeon_1_complete")
	assert_bool(_flags.has_flag(&"dungeon_1_complete")).is_true()


func test_set_flag_with_custom_value() -> void:
	_flags.set_flag(&"npc_talked", 3)
	assert_int(_flags.get_flag(&"npc_talked", 0) as int).is_equal(3)


# --- Get ---

func test_get_flag_returns_default_for_missing() -> void:
	var result: Variant = _flags.get_flag(&"nonexistent", 42)
	assert_int(result as int).is_equal(42)


func test_get_flag_returns_stored_value() -> void:
	_flags.set_flag(&"chapter", 2)
	assert_int(_flags.get_flag(&"chapter", 0) as int).is_equal(2)


# --- Clear ---

func test_clear_flag_removes_it() -> void:
	_flags.set_flag(&"temp_flag")
	_flags.clear_flag(&"temp_flag")
	assert_bool(_flags.has_flag(&"temp_flag")).is_false()


func test_clear_nonexistent_flag_does_nothing() -> void:
	_flags.clear_flag(&"nonexistent")
	assert_bool(_flags.has_flag(&"nonexistent")).is_false()


# --- Bulk ---

func test_get_all_flags_returns_dictionary() -> void:
	_flags.set_flag(&"a", true)
	_flags.set_flag(&"b", 5)
	var all: Dictionary = _flags.get_all_flags()
	assert_int(all.size()).is_equal(2)


func test_load_from_replaces_flags() -> void:
	_flags.set_flag(&"old")
	_flags.load_from({"new": true})
	assert_bool(_flags.has_flag(&"old")).is_false()
	assert_bool(_flags.has_flag(&"new")).is_true()


# --- Node Access Gating ---

func test_is_accessible_empty_flag_always_true() -> void:
	assert_bool(_flags.is_node_accessible(&"")).is_true()


func test_is_accessible_with_required_flag_present() -> void:
	_flags.set_flag(&"dungeon_1_complete")
	assert_bool(_flags.is_node_accessible(&"dungeon_1_complete")).is_true()


func test_is_accessible_with_required_flag_missing() -> void:
	assert_bool(_flags.is_node_accessible(&"dungeon_1_complete")).is_false()


# --- Signal ---

func test_set_flag_emits_signal() -> void:
	var monitor := monitor_signals(_flags)
	_flags.set_flag(&"test_flag")
	await assert_signal(monitor).is_emitted("flag_set", [&"test_flag"])
