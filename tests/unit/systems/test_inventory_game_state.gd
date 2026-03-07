class_name TestInventoryGameState
extends GdUnitTestSuite


func before_test() -> void:
	GameState.inventory.clear()
	GameState.party_roster.clear()
	GameState.character_data.clear()
	GameState.active_party.clear()
	GameState.init_character(&"alys")
	GameState.init_character(&"chaz")
	GameState.active_party = [&"alys", &"chaz"]


func test_add_inventory_item_stacks_quantity_in_game_state() -> void:
	GameState.add_inventory_item({"item_id": &"iron_sword", "slot": &"weapon"}, 1)
	GameState.add_inventory_item({"item_id": &"iron_sword", "slot": &"weapon"}, 2)
	assert_int(GameState.get_inventory_quantity(&"iron_sword")).is_equal(3)


func test_equip_inventory_item_updates_character_slot() -> void:
	GameState.add_inventory_item({"item_id": &"iron_sword", "slot": &"weapon", "stat_bonuses": {"strength": 2}}, 1)
	assert_bool(GameState.equip_inventory_item(&"alys", &"iron_sword")).is_true()
	var alys := GameState.character_data.get(&"alys", {}) as Dictionary
	var equipped := alys.get("equipped", {}) as Dictionary
	assert_str(str(equipped.get("weapon", ""))).is_equal("iron_sword")


func test_can_equip_inventory_item_blocks_when_all_copies_are_in_use() -> void:
	GameState.add_inventory_item({"item_id": &"iron_sword", "slot": &"weapon"}, 1)
	assert_bool(GameState.equip_inventory_item(&"alys", &"iron_sword")).is_true()
	assert_bool(GameState.can_equip_inventory_item(&"chaz", &"iron_sword")).is_false()


func test_get_equipped_item_state_hydrates_stat_bonuses() -> void:
	GameState.add_inventory_item({"item_id": &"iron_sword", "slot": &"weapon", "stat_bonuses": {"strength": 2}}, 1)
	GameState.equip_inventory_item(&"alys", &"iron_sword")
	var state := GameState.get_equipped_item_state(&"alys")
	var weapon := state.get(&"weapon", {}) as Dictionary
	var bonuses := weapon.get("stat_bonuses", {}) as Dictionary
	assert_int(bonuses.get("strength", 0) as int).is_equal(2)
