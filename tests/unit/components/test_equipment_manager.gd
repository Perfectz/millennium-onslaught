class_name TestEquipmentManager
extends GdUnitTestSuite


var _equip: EquipmentManager


func before_test() -> void:
	_equip = EquipmentManager.new()


func test_initial_slots_are_empty() -> void:
	assert_str(String(_equip.get_equipped(&"weapon"))).is_equal("")
	assert_str(String(_equip.get_equipped(&"armor"))).is_equal("")
	assert_str(String(_equip.get_equipped(&"accessory"))).is_equal("")


func test_equip_weapon_sets_slot() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	assert_str(String(_equip.get_equipped(&"weapon"))).is_equal("iron_sword")


func test_equip_returns_old_item() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	var old := _equip.equip(&"weapon", &"steel_sword", {"strength": 3})
	assert_str(String(old["item_id"])).is_equal("iron_sword")


func test_equip_empty_slot_returns_empty() -> void:
	var old := _equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	assert_bool(old.is_empty()).is_true()


func test_unequip_clears_slot() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	_equip.unequip(&"weapon")
	assert_str(String(_equip.get_equipped(&"weapon"))).is_equal("")


func test_unequip_returns_removed_item() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	var removed := _equip.unequip(&"weapon")
	assert_str(String(removed["item_id"])).is_equal("iron_sword")


func test_unequip_empty_slot_returns_empty() -> void:
	var removed := _equip.unequip(&"weapon")
	assert_bool(removed.is_empty()).is_true()


func test_invalid_slot_rejected() -> void:
	assert_bool(_equip.is_slot_valid(&"helmet")).is_false()
	assert_bool(_equip.is_slot_valid(&"weapon")).is_true()


func test_total_bonuses_empty_when_no_equipment() -> void:
	var bonuses := _equip.get_total_bonuses()
	assert_bool(bonuses.is_empty()).is_true()


func test_total_bonuses_from_single_item() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	var bonuses := _equip.get_total_bonuses()
	assert_int(bonuses["strength"]).is_equal(2)


func test_total_bonuses_from_multiple_items() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	_equip.equip(&"armor", &"leather_armor", {"defense": 1})
	_equip.equip(&"accessory", &"power_ring", {"strength": 1, "defense": 1})
	var bonuses := _equip.get_total_bonuses()
	assert_int(bonuses["strength"]).is_equal(3)
	assert_int(bonuses["defense"]).is_equal(2)


func test_equip_emits_signal() -> void:
	var signal_collector := monitor_signals(_equip)
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	await assert_signal(signal_collector).is_emitted("equipment_changed", [&"weapon", &"iron_sword"])


func test_set_state_restores() -> void:
	var state := {
		"weapon": {"item_id": &"steel_sword", "stat_bonuses": {"strength": 3}},
		"armor": {"item_id": &"", "stat_bonuses": {}},
		"accessory": {"item_id": &"", "stat_bonuses": {}},
	}
	_equip.set_state(state)
	assert_str(String(_equip.get_equipped(&"weapon"))).is_equal("steel_sword")


func test_clear_all_empties_slots() -> void:
	_equip.equip(&"weapon", &"iron_sword", {"strength": 2})
	_equip.equip(&"armor", &"leather_armor", {"defense": 1})
	_equip.clear_all()
	assert_str(String(_equip.get_equipped(&"weapon"))).is_equal("")
	assert_str(String(_equip.get_equipped(&"armor"))).is_equal("")
