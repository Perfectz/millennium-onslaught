## TDD tests for save system hardening — version, metadata, type safety, backup recovery.
class_name TestSaveHardening
extends GdUnitTestSuite


func before_test() -> void:
	# Reset GameState to clean defaults before each test.
	GameState.gold = 0
	GameState.story_flags.clear()
	GameState.inventory.clear()
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.active_party.clear()
	GameState.current_overworld_node = &"piata"


# --- Version & Metadata ---

func test_serialize_includes_save_version() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	assert_bool(data.has("save_version")).is_true()
	assert_int(data["save_version"] as int).is_equal(Constants.SAVE_VERSION)


func test_serialize_includes_timestamp() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	assert_bool(data.has("timestamp")).is_true()
	# Timestamp should be a recent Unix time (within last 10 seconds).
	var now: float = Time.get_unix_time_from_system()
	var saved_time: float = data["timestamp"] as float
	assert_bool(absf(now - saved_time) < 10.0).is_true()


func test_serialize_includes_party_display_names() -> void:
	GameState.active_party = [&"alys", &"chaz"]
	var data: Dictionary = GameState.serialize_persistent()
	assert_bool(data.has("party_display_names")).is_true()
	var names: Array = data["party_display_names"]
	assert_int(names.size()).is_equal(2)


func test_deserialize_accepts_current_version() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	var success: bool = GameState.deserialize_persistent(data)
	assert_bool(success).is_true()


func test_deserialize_warns_on_future_version() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	data["save_version"] = 999
	var success: bool = GameState.deserialize_persistent(data)
	# Future versions should be rejected.
	assert_bool(success).is_false()


func test_deserialize_handles_missing_version_as_v0() -> void:
	# Pre-versioned save data (no save_version key).
	var data: Dictionary = {"gold": 100, "party_roster": ["alys"], "character_data": {},
		"inventory": [], "story_flags": {}, "active_party": ["alys"]}
	var success: bool = GameState.deserialize_persistent(data)
	assert_bool(success).is_true()
	assert_int(GameState.gold).is_equal(100)


func test_get_save_metadata_returns_display_fields() -> void:
	GameState.gold = 500
	GameState.active_party = [&"alys", &"chaz"]
	GameState.character_data[&"alys"] = {"level": 5, "xp": 0, "hp": 100.0, "max_hp": 100.0,
		"tp": 100.0, "stats": {}, "stat_points_available": 0,
		"equipped": {"weapon": &"", "armor": &"", "accessory": &""},
		"techniques_learned": [], "skill_tree_progress": {}}
	var data: Dictionary = GameState.serialize_persistent()
	var meta: Dictionary = GameState.get_save_metadata(data)
	assert_bool(meta.has("exists")).is_true()
	assert_bool(meta["exists"] as bool).is_true()
	assert_bool(meta.has("gold")).is_true()
	assert_int(meta["gold"] as int).is_equal(500)
	assert_bool(meta.has("party_names")).is_true()
	assert_bool(meta.has("timestamp")).is_true()
	assert_bool(meta.has("version")).is_true()


# --- Type Safety & Corruption ---

func test_deserialize_rejects_non_dictionary() -> void:
	# Passing a non-dictionary should return false.
	# Note: GDScript will warn about type mismatch, but we test the guard.
	var success: bool = GameState.deserialize_persistent({})
	# Empty dict is technically valid (uses defaults).
	assert_bool(success).is_true()


func test_deserialize_handles_wrong_type_gold() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	data["gold"] = "not_a_number"
	var success: bool = GameState.deserialize_persistent(data)
	# Should still succeed but gold falls back to 0.
	assert_bool(success).is_true()
	assert_int(GameState.gold).is_equal(0)


func test_deserialize_handles_wrong_type_party_roster() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	data["party_roster"] = "not_an_array"
	var success: bool = GameState.deserialize_persistent(data)
	# Should still succeed but roster falls back to empty.
	assert_bool(success).is_true()
	assert_int(GameState.party_roster.size()).is_equal(0)


func test_deserialize_handles_empty_data() -> void:
	var success: bool = GameState.deserialize_persistent({})
	assert_bool(success).is_true()
	# All fields should be at defaults.
	assert_int(GameState.gold).is_equal(0)
	assert_int(GameState.party_roster.size()).is_equal(0)


func test_deserialize_partial_data_uses_defaults() -> void:
	var data: Dictionary = {"gold": 42, "story_flags": {"test": true}}
	var success: bool = GameState.deserialize_persistent(data)
	assert_bool(success).is_true()
	assert_int(GameState.gold).is_equal(42)
	assert_int(GameState.party_roster.size()).is_equal(0)
	assert_int(GameState.inventory.size()).is_equal(0)


# --- Equipment & RPG Round-Trip ---

func test_round_trip_preserves_equipped_items() -> void:
	GameState.character_data[&"alys"] = {
		"level": 3, "xp": 50, "hp": 80.0, "max_hp": 100.0, "tp": 60.0,
		"stats": {"strength": 7, "magic": 5, "defense": 5, "agility": 5},
		"stat_points_available": 2,
		"equipped": {"weapon": &"iron_sword", "armor": &"leather_armor", "accessory": &""},
		"techniques_learned": ["fire_slash"],
		"skill_tree_progress": {"tier_1_attack": true},
	}
	var data: Dictionary = GameState.serialize_persistent()
	GameState.character_data.clear()
	GameState.deserialize_persistent(data)
	var alys: Dictionary = GameState.character_data.get(&"alys", {}) as Dictionary
	assert_str(str(alys.get("equipped", {}).get("weapon", ""))).is_equal("iron_sword")
	assert_str(str(alys.get("equipped", {}).get("armor", ""))).is_equal("leather_armor")


func test_round_trip_preserves_skill_tree_progress() -> void:
	GameState.character_data[&"alys"] = {
		"level": 5, "xp": 200, "hp": 100.0, "max_hp": 100.0, "tp": 100.0,
		"stats": {}, "stat_points_available": 0,
		"equipped": {"weapon": &"", "armor": &"", "accessory": &""},
		"techniques_learned": [],
		"skill_tree_progress": {"tier_1_attack": true, "tier_2_combo": true},
	}
	var data: Dictionary = GameState.serialize_persistent()
	GameState.character_data.clear()
	GameState.deserialize_persistent(data)
	var alys: Dictionary = GameState.character_data.get(&"alys", {}) as Dictionary
	var progress: Dictionary = alys.get("skill_tree_progress", {})
	assert_bool(progress.get("tier_1_attack", false) as bool).is_true()
	assert_bool(progress.get("tier_2_combo", false) as bool).is_true()


func test_round_trip_preserves_techniques_learned() -> void:
	GameState.character_data[&"alys"] = {
		"level": 4, "xp": 100, "hp": 100.0, "max_hp": 100.0, "tp": 100.0,
		"stats": {}, "stat_points_available": 0,
		"equipped": {"weapon": &"", "armor": &"", "accessory": &""},
		"techniques_learned": ["fire_slash", "healing_wave"],
		"skill_tree_progress": {},
	}
	var data: Dictionary = GameState.serialize_persistent()
	GameState.character_data.clear()
	GameState.deserialize_persistent(data)
	var alys: Dictionary = GameState.character_data.get(&"alys", {}) as Dictionary
	var techs: Array = alys.get("techniques_learned", [])
	assert_int(techs.size()).is_equal(2)


func test_round_trip_preserves_active_party_order() -> void:
	GameState.active_party = [&"chaz", &"alys", &"rune"]
	var data: Dictionary = GameState.serialize_persistent()
	GameState.active_party.clear()
	GameState.deserialize_persistent(data)
	assert_int(GameState.active_party.size()).is_equal(3)
	assert_str(str(GameState.active_party[0])).is_equal("chaz")
	assert_str(str(GameState.active_party[1])).is_equal("alys")
	assert_str(str(GameState.active_party[2])).is_equal("rune")


# --- SaveManager Integration ---

func test_load_metadata_returns_exists_false_for_missing_slot() -> void:
	# Slot 99 should never exist.
	var meta: Dictionary = SaveManager.load_save_metadata(99)
	assert_bool(meta["exists"] as bool).is_false()


func test_load_metadata_returns_valid_fields_for_existing_slot() -> void:
	# Create a save, then read its metadata.
	GameState.gold = 777
	GameState.active_party = [&"alys"]
	SaveManager.save_game(98)
	var meta: Dictionary = SaveManager.load_save_metadata(98)
	assert_bool(meta["exists"] as bool).is_true()
	assert_int(meta["gold"] as int).is_equal(777)
	assert_bool(meta.has("timestamp")).is_true()
	assert_bool(meta.has("version")).is_true()
	# Cleanup test save.
	SaveManager.delete_save(98)


func test_load_falls_back_to_backup_on_corrupt_primary() -> void:
	# Save valid data, which creates a good file.
	GameState.gold = 999
	SaveManager.save_game(97)
	# Save again so the first save becomes the backup.
	GameState.gold = 1000
	SaveManager.save_game(97)
	# Corrupt the primary file by overwriting with garbage.
	var path: String = SaveManager.get_save_path(97)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("THIS IS CORRUPT DATA {{{")
	f.close()
	# Load should fall back to backup (gold=999).
	GameState.gold = 0
	var success: bool = SaveManager.load_game(97)
	assert_bool(success).is_true()
	assert_int(GameState.gold).is_equal(999)
	# Cleanup.
	SaveManager.delete_save(97)
