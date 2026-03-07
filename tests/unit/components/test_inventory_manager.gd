class_name TestInventoryManager
extends GdUnitTestSuite


var _inventory: InventoryManager


func before_test() -> void:
	_inventory = InventoryManager.new()


func test_add_item_creates_entry_with_quantity() -> void:
	_inventory.add_item({"item_id": &"iron_sword", "display_name": "Iron Sword", "slot": &"weapon"}, 2)
	var entry := _inventory.get_item(&"iron_sword")
	assert_str(str(entry.get("display_name", ""))).is_equal("Iron Sword")
	assert_int(entry.get("quantity", 0) as int).is_equal(2)


func test_add_item_stacks_existing_quantity() -> void:
	_inventory.add_item({"item_id": &"iron_sword", "display_name": "Iron Sword"}, 1)
	_inventory.add_item({"item_id": &"iron_sword"}, 3)
	assert_int(_inventory.get_quantity(&"iron_sword")).is_equal(4)


func test_remove_item_decrements_quantity() -> void:
	_inventory.add_item({"item_id": &"iron_sword"}, 3)
	assert_bool(_inventory.remove_item(&"iron_sword", 2)).is_true()
	assert_int(_inventory.get_quantity(&"iron_sword")).is_equal(1)


func test_remove_item_erases_entry_at_zero() -> void:
	_inventory.add_item({"item_id": &"iron_sword"}, 1)
	assert_bool(_inventory.remove_item(&"iron_sword", 1)).is_true()
	assert_bool(_inventory.get_item(&"iron_sword").is_empty()).is_true()


func test_remove_item_fails_when_quantity_insufficient() -> void:
	_inventory.add_item({"item_id": &"iron_sword"}, 1)
	assert_bool(_inventory.remove_item(&"iron_sword", 2)).is_false()
	assert_int(_inventory.get_quantity(&"iron_sword")).is_equal(1)


func test_set_state_aggregates_duplicate_entries() -> void:
	_inventory.set_state([
		{"item_id": &"iron_sword", "display_name": "Iron Sword", "quantity": 1},
		{"item_id": &"iron_sword", "quantity": 2},
		{"item_id": &"leather_armor", "quantity": 1},
	])
	assert_int(_inventory.get_quantity(&"iron_sword")).is_equal(3)
	assert_int(_inventory.get_quantity(&"leather_armor")).is_equal(1)


func test_serialize_state_returns_sorted_entries() -> void:
	_inventory.add_item({"item_id": &"steel_sword", "display_name": "Steel Sword"}, 1)
	_inventory.add_item({"item_id": &"iron_sword", "display_name": "Iron Sword"}, 1)
	var state := _inventory.serialize_state()
	assert_int(state.size()).is_equal(2)
	assert_str(str((state[0] as Dictionary).get("item_id", ""))).is_equal("iron_sword")


func test_from_equipment_def_copies_equipment_fields() -> void:
	var def := load("res://resources/equipment/iron_sword.tres") as EquipmentDef
	var entry := InventoryManager.from_equipment_def(def, 2)
	assert_str(str(entry.get("item_id", ""))).is_equal("iron_sword")
	assert_str(str(entry.get("slot", ""))).is_equal("weapon")
	assert_int(entry.get("quantity", 0) as int).is_equal(2)
