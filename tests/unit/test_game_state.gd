## Tests for GameState — serialization round-trip, character init, dungeon reset.
extends GdUnitTestSuite


func before_test() -> void:
	# Reset GameState before each test.
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.inventory.clear()
	GameState.gold = 0
	GameState.story_flags.clear()
	GameState.active_party.clear()
	GameState.reset_dungeon()


func test_init_character_creates_default_data() -> void:
	GameState.init_character(&"chaz")
	assert_bool(&"chaz" in GameState.character_data).is_true()
	var data: Dictionary = GameState.character_data[&"chaz"]
	assert_int(data["level"]).is_equal(1)
	assert_int(data["xp"]).is_equal(0)
	assert_float(data["hp"]).is_equal(100.0)


func test_init_character_does_not_overwrite() -> void:
	GameState.init_character(&"chaz")
	GameState.character_data[&"chaz"]["level"] = 5
	GameState.init_character(&"chaz")
	assert_int(GameState.character_data[&"chaz"]["level"]).is_equal(5)


func test_serialize_deserialize_round_trip() -> void:
	GameState.party_roster = [&"chaz", &"alys"]
	GameState.gold = 500
	GameState.story_flags["boss_defeated"] = true
	GameState.init_character(&"chaz")
	GameState.inventory.append({"id": &"sword", "type": &"weapon"})
	GameState.active_party = [&"chaz"]
	var serialized: Dictionary = GameState.serialize_persistent()
	# Clear everything.
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.inventory.clear()
	GameState.gold = 0
	GameState.story_flags.clear()
	GameState.active_party.clear()
	# Deserialize.
	GameState.deserialize_persistent(serialized)
	assert_int(GameState.party_roster.size()).is_equal(2)
	assert_int(GameState.gold).is_equal(500)
	assert_bool(GameState.story_flags.get("boss_defeated", false)).is_true()
	assert_int(GameState.inventory.size()).is_equal(1)
	assert_int(GameState.active_party.size()).is_equal(1)


func test_reset_dungeon_clears_transient() -> void:
	GameState.current_dungeon_id = &"dungeon_01"
	GameState.current_room_index = 3
	GameState.dungeon_buffs.append({"buff": "speed"})
	GameState.dungeon_drops.append({"item": "potion"})
	GameState.encounter_active = true
	GameState.encounter_enemies_alive = 5
	GameState.reset_dungeon()
	assert_str(GameState.current_dungeon_id).is_equal("")
	assert_int(GameState.current_room_index).is_equal(0)
	assert_int(GameState.dungeon_buffs.size()).is_equal(0)
	assert_int(GameState.dungeon_drops.size()).is_equal(0)
	assert_bool(GameState.encounter_active).is_false()
	assert_int(GameState.encounter_enemies_alive).is_equal(0)


func test_bank_dungeon_rewards_moves_drops_to_inventory() -> void:
	GameState.dungeon_drops.append({"id": &"potion", "type": &"item"})
	GameState.dungeon_drops.append({"id": &"sword", "type": &"weapon"})
	GameState.bank_dungeon_rewards()
	assert_int(GameState.inventory.size()).is_equal(2)
	assert_int(GameState.dungeon_drops.size()).is_equal(0)


func test_serialize_does_not_include_transient() -> void:
	GameState.current_dungeon_id = &"dungeon_01"
	GameState.dungeon_buffs.append({"buff": "speed"})
	var serialized: Dictionary = GameState.serialize_persistent()
	assert_bool("current_dungeon_id" in serialized).is_false()
	assert_bool("dungeon_buffs" in serialized).is_false()
