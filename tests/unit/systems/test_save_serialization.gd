## TDD tests for GameState serialization round-trip — ensure save/load preserves all persistent data.
class_name TestSaveSerializationRoundTrip
extends GdUnitTestSuite


func before_test() -> void:
	# Reset GameState to clean defaults before each test.
	GameState.gold = 0
	GameState.story_flags.clear()
	GameState.inventory.clear()
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.active_party.clear()


# --- Serialize ---

func test_serialize_returns_all_required_fields() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	assert_bool(data.has("save_schema")).is_true()
	assert_bool(data.has("party_roster")).is_true()
	assert_bool(data.has("character_data")).is_true()
	assert_bool(data.has("inventory")).is_true()
	assert_bool(data.has("gold")).is_true()
	assert_bool(data.has("story_flags")).is_true()
	assert_bool(data.has("active_party")).is_true()


func test_serialize_normalizes_character_record_shape() -> void:
	GameState.character_data[&"alys"] = {
		"level": 0,
		"xp": -10,
		"hp": 150.0,
		"max_hp": 80.0,
		"tp": 999.0,
		"stats": {"strength": 8},
		"stat_points": 3,
		"equipment": {"weapon": "iron_sword"},
		"techniques": ["fire_slash"],
		"skill_tree": {"tier_1_attack": 1},
	}
	var data: Dictionary = GameState.serialize_persistent()
	var roster: Array = data.get("party_roster", [])
	assert_int(roster.size()).is_equal(1)
	var serialized_chars: Dictionary = data.get("character_data", {})
	var alys: Dictionary = serialized_chars.get(&"alys", {})
	assert_int(alys.get("level", 0) as int).is_equal(1)
	assert_int(alys.get("xp", 0) as int).is_equal(0)
	assert_float(alys.get("hp", 0.0) as float).is_equal(80.0)
	assert_float(alys.get("max_hp", 0.0) as float).is_equal(80.0)
	assert_float(alys.get("tp", 0.0) as float).is_equal(Constants.TP_MAX)
	assert_int(alys.get("stat_points_available", 0) as int).is_equal(3)
	assert_str(str(alys.get("equipped", {}).get("weapon", ""))).is_equal("iron_sword")
	assert_bool(alys.get("skill_tree_progress", {}).get("tier_1_attack", false) as bool).is_true()


# --- Round-Trips ---

func test_round_trip_preserves_gold() -> void:
	GameState.gold = 1234
	var data: Dictionary = GameState.serialize_persistent()
	GameState.gold = 0
	GameState.deserialize_persistent(data)
	assert_int(GameState.gold).is_equal(1234)


func test_round_trip_preserves_story_flags() -> void:
	GameState.story_flags["dungeon_1_complete"] = true
	GameState.story_flags["chapter"] = 3
	var data: Dictionary = GameState.serialize_persistent()
	GameState.story_flags.clear()
	GameState.deserialize_persistent(data)
	assert_bool(GameState.story_flags.get("dungeon_1_complete", false) as bool).is_true()
	assert_int(GameState.story_flags.get("chapter", 0) as int).is_equal(3)


func test_round_trip_preserves_inventory() -> void:
	GameState.inventory.append({"item_id": "iron_sword", "slot": "weapon"})
	var data: Dictionary = GameState.serialize_persistent()
	GameState.inventory.clear()
	GameState.deserialize_persistent(data)
	assert_int(GameState.inventory.size()).is_equal(1)


func test_round_trip_preserves_party_roster() -> void:
	GameState.party_roster.append(&"alys")
	GameState.party_roster.append(&"hahn")
	var data: Dictionary = GameState.serialize_persistent()
	GameState.party_roster.clear()
	GameState.deserialize_persistent(data)
	assert_int(GameState.party_roster.size()).is_equal(2)


# --- Edge Cases ---

func test_deserialize_handles_missing_fields() -> void:
	var partial: Dictionary = {"gold": 50}
	var success: bool = GameState.deserialize_persistent(partial)
	assert_bool(success).is_true()
	assert_int(GameState.gold).is_equal(50)


func test_deserialize_returns_true_on_valid_data() -> void:
	var data: Dictionary = GameState.serialize_persistent()
	var success: bool = GameState.deserialize_persistent(data)
	assert_bool(success).is_true()
