## Pure inventory storage. Aggregates items by item_id and tracks quantities.
class_name InventoryManager
extends RefCounted


signal inventory_changed()
signal item_quantity_changed(item_id: StringName, quantity: int)


var _items: Dictionary = {}


## Create a normalized inventory entry from a raw item dictionary.
static func normalize_item_entry(item_data: Dictionary, quantity: int = -1) -> Dictionary:
	var item_id := StringName(item_data.get("item_id", ""))
	if item_id == &"":
		return {}

	var resolved_quantity := quantity if quantity > 0 else int(item_data.get("quantity", 1))
	resolved_quantity = maxi(resolved_quantity, 1)

	return {
		"item_id": item_id,
		"display_name": str(item_data.get("display_name", _humanize_item_id(item_id))),
		"description": str(item_data.get("description", "")),
		"category": StringName(item_data.get("category", "equipment")),
		"slot": StringName(item_data.get("slot", "")),
		"quantity": resolved_quantity,
		"cost": maxi(int(item_data.get("cost", 0)), 0),
		"required_level": maxi(int(item_data.get("required_level", 1)), 1),
		"stat_bonuses": (item_data.get("stat_bonuses", {}) as Dictionary).duplicate(true),
		"passive_effects": (item_data.get("passive_effects", {}) as Dictionary).duplicate(true),
	}


## Convenience conversion from equipment data to an inventory entry.
static func from_equipment_def(def: EquipmentDef, quantity: int = 1) -> Dictionary:
	if def == null:
		return {}
	return normalize_item_entry({
		"item_id": def.equipment_id,
		"display_name": def.display_name,
		"description": def.description,
		"category": &"equipment",
		"slot": def.slot,
		"cost": def.cost,
		"required_level": def.required_level,
		"stat_bonuses": def.stat_bonuses,
		"passive_effects": def.passive_effects,
	}, quantity)


## Add quantity of an item. Returns the updated entry or empty on invalid input.
func add_item(item_data: Dictionary, quantity: int = -1) -> Dictionary:
	var entry := normalize_item_entry(item_data, quantity)
	if entry.is_empty():
		return {}

	var item_id := StringName(entry.get("item_id", &""))
	var amount := int(entry.get("quantity", 1))
	var existing := get_item(item_id)
	if existing.is_empty():
		_items[item_id] = entry
	else:
		existing["quantity"] = int(existing.get("quantity", 0)) + amount
		existing = _merge_metadata(existing, entry)
		_items[item_id] = existing

	_emit_quantity_change(item_id)
	return get_item(item_id)


## Remove quantity of an item. Returns true if enough copies existed.
func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	var current := get_item(item_id)
	if current.is_empty():
		return false

	var new_quantity := int(current.get("quantity", 0)) - quantity
	if new_quantity < 0:
		return false
	if new_quantity == 0:
		_items.erase(item_id)
	else:
		current["quantity"] = new_quantity
		_items[item_id] = current

	_emit_quantity_change(item_id)
	return true


## Whether the inventory contains at least the requested quantity.
func has_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0:
		return true
	return get_quantity(item_id) >= quantity


## Get the stored quantity for a specific item_id.
func get_quantity(item_id: StringName) -> int:
	var entry := get_item(item_id)
	if entry.is_empty():
		return 0
	return int(entry.get("quantity", 0))


## Get a deep copy of a stored item entry.
func get_item(item_id: StringName) -> Dictionary:
	if item_id not in _items:
		return {}
	return (_items[item_id] as Dictionary).duplicate(true)


## Return all items sorted by display name then item_id.
func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: StringName in _items:
		result.append((_items[item_id] as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_name := str(a.get("display_name", ""))
		var b_name := str(b.get("display_name", ""))
		if a_name == b_name:
			return str(a.get("item_id", "")) < str(b.get("item_id", ""))
		return a_name.naturalnocasecmp_to(b_name) < 0
	)
	return result


## Replace the current inventory state with serialized entries.
func set_state(state: Array) -> void:
	_items.clear()
	for entry in state:
		if not entry is Dictionary:
			continue
		var normalized := normalize_item_entry(entry as Dictionary)
		if normalized.is_empty():
			continue
		var item_id := StringName(normalized.get("item_id", &""))
		if item_id in _items:
			var merged := get_item(item_id)
			merged["quantity"] = int(merged.get("quantity", 0)) + int(normalized.get("quantity", 1))
			merged = _merge_metadata(merged, normalized)
			_items[item_id] = merged
		else:
			_items[item_id] = normalized


## Serialize to an array suitable for save data.
func serialize_state() -> Array[Dictionary]:
	return get_all_items()


## Remove all items.
func clear() -> void:
	_items.clear()
	inventory_changed.emit()


func _emit_quantity_change(item_id: StringName) -> void:
	item_quantity_changed.emit(item_id, get_quantity(item_id))
	inventory_changed.emit()


func _merge_metadata(base_entry: Dictionary, new_entry: Dictionary) -> Dictionary:
	if str(base_entry.get("display_name", "")).strip_edges().is_empty():
		base_entry["display_name"] = new_entry.get("display_name", "")
	if str(base_entry.get("description", "")).strip_edges().is_empty():
		base_entry["description"] = new_entry.get("description", "")
	if StringName(base_entry.get("slot", "")) == &"":
		base_entry["slot"] = StringName(new_entry.get("slot", ""))
	if int(base_entry.get("cost", 0)) <= 0:
		base_entry["cost"] = int(new_entry.get("cost", 0))
	if int(base_entry.get("required_level", 1)) <= 1 and int(new_entry.get("required_level", 1)) > 1:
		base_entry["required_level"] = int(new_entry.get("required_level", 1))

	var bonuses := base_entry.get("stat_bonuses", {}) as Dictionary
	if bonuses.is_empty():
		base_entry["stat_bonuses"] = (new_entry.get("stat_bonuses", {}) as Dictionary).duplicate(true)

	var passive_effects := base_entry.get("passive_effects", {}) as Dictionary
	if passive_effects.is_empty():
		base_entry["passive_effects"] = (new_entry.get("passive_effects", {}) as Dictionary).duplicate(true)

	return base_entry


static func _humanize_item_id(item_id: StringName) -> String:
	return str(item_id).replace("_", " ").capitalize()
