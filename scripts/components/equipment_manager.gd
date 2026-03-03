## Pure equipment slot management. No scene tree dependency — fully testable.
## Manages weapon/armor/accessory slots and computes total stat bonuses.
class_name EquipmentManager
extends RefCounted


signal equipment_changed(slot: StringName, item_id: StringName)

const VALID_SLOTS: Array[StringName] = [&"weapon", &"armor", &"accessory"]

## Internal storage: slot -> {item_id: StringName, stat_bonuses: Dictionary}
var _slots: Dictionary = {}


func _init() -> void:
	clear_all()


## Equip an item to a slot. Returns the previously equipped item dict, or empty if slot was empty.
func equip(slot: StringName, item_id: StringName, stat_bonuses: Dictionary) -> Dictionary:
	if not is_slot_valid(slot):
		return {}
	var old: Dictionary = {}
	if _slots[slot]["item_id"] != &"":
		old = _slots[slot].duplicate()
	_slots[slot] = {"item_id": item_id, "stat_bonuses": stat_bonuses.duplicate()}
	equipment_changed.emit(slot, item_id)
	return old


## Remove equipment from a slot. Returns the removed item dict, or empty if already empty.
func unequip(slot: StringName) -> Dictionary:
	if not is_slot_valid(slot):
		return {}
	var old: Dictionary = {}
	if _slots[slot]["item_id"] != &"":
		old = _slots[slot].duplicate()
		_slots[slot] = {"item_id": &"", "stat_bonuses": {}}
		equipment_changed.emit(slot, &"")
	return old


## Get the item_id in a slot. Returns empty StringName if nothing equipped.
func get_equipped(slot: StringName) -> StringName:
	if not is_slot_valid(slot):
		return &""
	return _slots[slot]["item_id"]


## Get sum of all stat bonuses from all equipped items.
func get_total_bonuses() -> Dictionary:
	var total: Dictionary = {}
	for slot: StringName in VALID_SLOTS:
		var bonuses: Dictionary = _slots[slot]["stat_bonuses"]
		for key: String in bonuses:
			total[key] = total.get(key, 0) + bonuses[key]
	return total


## Check if a slot name is valid.
func is_slot_valid(slot: StringName) -> bool:
	return slot in VALID_SLOTS


## Clear all equipment slots.
func clear_all() -> void:
	_slots = {}
	for slot: StringName in VALID_SLOTS:
		_slots[slot] = {"item_id": &"", "stat_bonuses": {}}


## Restore state from save data.
func set_state(state: Dictionary) -> void:
	for slot: StringName in VALID_SLOTS:
		if slot in state:
			_slots[slot] = state[slot].duplicate(true)
		else:
			_slots[slot] = {"item_id": &"", "stat_bonuses": {}}
