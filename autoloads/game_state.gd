## Single source of truth for persistent profile/save data.
## Transient dungeon/session state lives in RuntimeState.
class_name GameStateSingleton
extends Node

const SAVE_SCHEMA: String = "profile"
const MAX_ACTIVE_PARTY_SIZE: int = 4


# --- Persistent State (survives dungeon death, saved to file) ---

## Party roster — which characters have been recruited.
var party_roster: Array[StringName] = []

## Per-character data keyed by character_id.
var character_data: Dictionary = {}

## Inventory of all owned equipment and items.
var inventory: Array[Dictionary] = []

## Gold currency.
var gold: int = 0

## Story flags — key-value store of completed events.
var story_flags: Dictionary = {}

## Currently active party members (up to 4 for co-op).
var active_party: Array[StringName] = []

## Current overworld node the player is at.
var current_overworld_node: StringName = &"piata"


# --- Debug / Testing ---

## God mode — when true, player takes no damage.
var god_mode: bool = false
var validation_error_handler: Callable = Callable()


# --- Navigation (transient, not saved) ---

## Pending town to load on scene transition.
var pending_town_id: StringName = &""

## Pending dungeon to load on scene transition.
var pending_dungeon_id: StringName = &""

## Which save slot auto-save writes to (set on load, reset on new game).
var active_save_slot: int = 0

## Pending cutscene data for scene transitions.
var pending_cutscene_data: Array = []
var pending_cutscene_next: StringName = &"overworld"
var pending_cutscene_music: StringName = &""


# --- Display Settings (persisted separately from RPG saves) ---

## Scanline overlay toggle.
var scanlines_enabled: bool = true

## Fullscreen mode toggle.
var fullscreen_enabled: bool = false


func _ready() -> void:
	_load_display_settings()
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Toggle scanlines and persist the setting.
func set_scanlines_enabled(enabled: bool) -> void:
	scanlines_enabled = enabled
	_save_display_settings()


func _save_display_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "scanlines_enabled", scanlines_enabled)
	cfg.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	cfg.save(Constants.DISPLAY_SETTINGS_PATH)


func _load_display_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Constants.DISPLAY_SETTINGS_PATH) == OK:
		scanlines_enabled = cfg.get_value("display", "scanlines_enabled", true)
		fullscreen_enabled = cfg.get_value("display", "fullscreen_enabled", false)


## Start a fresh new game with default state.
func start_new_game() -> void:
	party_roster = [&"alys", &"chaz"]
	active_party = [&"alys"]
	character_data.clear()
	init_character(&"alys")
	init_character(&"chaz")
	inventory.clear()
	gold = Constants.NEW_GAME_STARTING_GOLD
	story_flags.clear()
	current_overworld_node = &"piata"
	active_save_slot = 0
	RuntimeState.reset_dungeon()


## Initialize default character data for a new character.
## Loads base stats from CharacterDef if available, otherwise uses generic defaults.
func init_character(character_id: StringName) -> void:
	if character_id in character_data:
		return
	character_data[character_id] = _build_default_character_record(character_id)


## Ensure the character exists in persistent state before reading or writing it.
func ensure_character_record(character_id: StringName) -> Dictionary:
	if character_id == &"":
		return {}
	if character_id not in party_roster:
		party_roster.append(character_id)
	if character_id not in character_data:
		init_character(character_id)
	return character_data.get(character_id, {}) as Dictionary


## Sync live runtime values for a character back into persistent save state.
func sync_character_runtime_state(
	character_id: StringName,
	hp: float,
	max_hp: float,
	tp: float,
	xp: int,
	level: int,
	stat_points_available: int = -1
) -> void:
	var data := ensure_character_record(character_id)
	if data.is_empty():
		return
	data["hp"] = clampf(hp, 0.0, maxf(max_hp, 0.0))
	data["max_hp"] = maxf(max_hp, 0.0)
	data["tp"] = clampf(tp, 0.0, Constants.TP_MAX)
	data["xp"] = maxi(xp, 0)
	data["level"] = maxi(level, 1)
	if stat_points_available >= 0:
		data["stat_points_available"] = maxi(stat_points_available, 0)


## Sync a normalized runtime payload back into persistent save state.
func sync_character_runtime_payload(payload: Dictionary) -> void:
	var character_id := StringName(payload.get("character_id", ""))
	if character_id == &"":
		return
	var stat_points_available := -1
	if payload.has("stat_points_available"):
		stat_points_available = int(payload.get("stat_points_available", -1))
	sync_character_runtime_state(
		character_id,
		float(payload.get("hp", 0.0)),
		float(payload.get("max_hp", 0.0)),
		float(payload.get("tp", 0.0)),
		int(payload.get("xp", 0)),
		int(payload.get("level", 1)),
		stat_points_available
	)


## Return normalized inventory entries for UI/save consumption.
func get_inventory_items() -> Array[Dictionary]:
	var manager := _build_inventory_manager()
	var result: Array[Dictionary] = []
	for entry: Dictionary in manager.get_all_items():
		result.append(_hydrate_inventory_entry(entry))
	inventory = result.duplicate(true)
	return result


## Get a single normalized inventory entry by item id.
func get_inventory_item(item_id: StringName) -> Dictionary:
	if item_id == &"":
		return {}
	var manager := _build_inventory_manager()
	var entry := manager.get_item(item_id)
	if entry.is_empty():
		return _get_item_defaults(item_id)
	return _hydrate_inventory_entry(entry)


## Get the total owned quantity for an item.
func get_inventory_quantity(item_id: StringName) -> int:
	var manager := _build_inventory_manager()
	return manager.get_quantity(item_id)


## Whether the inventory contains at least the requested quantity.
func has_inventory_item(item_id: StringName, quantity: int = 1) -> bool:
	var manager := _build_inventory_manager()
	return manager.has_item(item_id, quantity)


## Add an item to persistent inventory. Returns the updated entry or empty if invalid.
func add_inventory_item(item_data: Dictionary, quantity: int = -1) -> Dictionary:
	var manager := _build_inventory_manager()
	var entry := _hydrate_inventory_entry(item_data)
	if entry.is_empty():
		return {}
	var updated := manager.add_item(entry, quantity)
	inventory = manager.serialize_state()
	return _hydrate_inventory_entry(updated)


## Remove quantity from persistent inventory. Returns false if not enough copies exist.
func remove_inventory_item(item_id: StringName, quantity: int = 1) -> bool:
	var manager := _build_inventory_manager()
	var removed := manager.remove_item(item_id, quantity)
	if removed:
		inventory = manager.serialize_state()
	return removed


## Count how many copies of an item are currently equipped across all characters.
func get_equipped_item_count(item_id: StringName) -> int:
	if item_id == &"":
		return 0
	var count := 0
	for raw_key in character_data.keys():
		var char_id := StringName(raw_key)
		var data: Dictionary = character_data.get(char_id, {}) as Dictionary
		var equipped: Dictionary = data.get("equipped", {})
		for slot in equipped:
			if StringName(equipped.get(slot, "")) == item_id:
				count += 1
	return count


## Whether a character can equip the given owned item.
func can_equip_inventory_item(character_id: StringName, item_id: StringName) -> bool:
	var item_entry := get_inventory_item(item_id)
	if item_entry.is_empty():
		return false
	var slot := StringName(item_entry.get("slot", ""))
	if slot == &"":
		return false
	var data := ensure_character_record(character_id)
	if data.is_empty():
		return false
	var level := int(data.get("level", 1))
	var required_level := int(item_entry.get("required_level", 1))
	if level < required_level:
		return false
	var equipped: Dictionary = data.get("equipped", {})
	var current_item_id := StringName(equipped.get(slot, ""))
	if current_item_id == item_id:
		return true
	var quantity := get_inventory_quantity(item_id)
	var equipped_count := get_equipped_item_count(item_id)
	return quantity > equipped_count


## Equip an owned inventory item to a character. Returns false on validation failure.
func equip_inventory_item(character_id: StringName, item_id: StringName) -> bool:
	if not can_equip_inventory_item(character_id, item_id):
		return false
	var item_entry := get_inventory_item(item_id)
	var slot := StringName(item_entry.get("slot", ""))
	if slot == &"":
		return false
	var data := ensure_character_record(character_id)
	if data.is_empty():
		return false
	var equipped: Dictionary = data.get("equipped", {}).duplicate(true)
	equipped[slot] = item_id
	data["equipped"] = equipped
	var player_idx := active_party.find(character_id)
	if player_idx >= 0:
		EventBus.rpg_equipment_changed.emit(player_idx, slot, item_id)
	return true


## Unequip a slot for a character. Returns false if the slot was already empty or invalid.
func unequip_inventory_slot(character_id: StringName, slot: StringName) -> bool:
	var data := ensure_character_record(character_id)
	if data.is_empty():
		return false
	if not EquipmentManager.VALID_SLOTS.has(slot):
		return false
	var equipped: Dictionary = data.get("equipped", {}).duplicate(true)
	if StringName(equipped.get(slot, "")) == &"":
		return false
	equipped[slot] = &""
	data["equipped"] = equipped
	var player_idx := active_party.find(character_id)
	if player_idx >= 0:
		EventBus.rpg_equipment_changed.emit(player_idx, slot, &"")
	return true


## Build slot -> equipment state for runtime stat calculation.
func get_equipped_item_state(character_id: StringName) -> Dictionary:
	var data := ensure_character_record(character_id)
	if data.is_empty():
		return {}
	var equipped: Dictionary = data.get("equipped", {})
	var state: Dictionary = {}
	for slot: StringName in EquipmentManager.VALID_SLOTS:
		var item_id := StringName(equipped.get(slot, ""))
		var item_entry := get_inventory_item(item_id)
		state[slot] = {
			"item_id": item_id,
			"stat_bonuses": (item_entry.get("stat_bonuses", {}) as Dictionary).duplicate(true),
		}
	return state


## Compatibility wrapper: transient dungeon state now lives in RuntimeState.
func reset_dungeon() -> void:
	RuntimeState.reset_dungeon()


## Compatibility wrapper: room bounds now live in RuntimeState.
func set_room_bounds(min_x: float, max_x: float, min_z: float = -100.0, max_z: float = 100.0) -> void:
	RuntimeState.set_room_bounds(min_x, max_x, min_z, max_z)


## Compatibility wrapper: room bounds now live in RuntimeState.
func clear_room_bounds() -> void:
	RuntimeState.clear_room_bounds()


## Bank transient rewards into persistent state. Called on dungeon completion.
func bank_dungeon_rewards() -> void:
	for drop in RuntimeState.dungeon_drops:
		var added := add_inventory_item(drop)
		if not added.is_empty():
			EventBus.rpg_item_picked_up.emit(StringName(added.get("item_id", "")))
	RuntimeState.reset_dungeon()


## Serialize persistent state to a dictionary for saving.
func serialize_persistent() -> Dictionary:
	var serialized_active_party := _normalize_character_id_list(active_party)
	if serialized_active_party.size() > MAX_ACTIVE_PARTY_SIZE:
		serialized_active_party.resize(MAX_ACTIVE_PARTY_SIZE)
	var serialized_roster := _build_serialized_roster(serialized_active_party, party_roster, character_data)
	var serialized_character_data := _serialize_character_records(serialized_roster)
	var display_names: Array[String] = []
	for member in serialized_active_party:
		display_names.append(Constants.CHARACTER_DISPLAY_NAMES.get(member, str(member)))
	return {
		"save_schema": SAVE_SCHEMA,
		"save_version": Constants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"party_display_names": display_names,
		"party_roster": serialized_roster.duplicate(),
		"character_data": serialized_character_data,
		"inventory": get_inventory_items(),
		"gold": maxi(gold, 0),
		"story_flags": story_flags.duplicate(true),
		"active_party": serialized_active_party.duplicate(),
		"current_overworld_node": _normalize_overworld_node(current_overworld_node),
	}


## Extract display-friendly metadata from raw save data without applying it.
static func get_save_metadata(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return {"exists": false}
	var save_data := data as Dictionary
	if save_data.is_empty():
		return {"exists": false}
	var schema := str(save_data.get("save_schema", "")).strip_edges()
	if not schema.is_empty() and schema != SAVE_SCHEMA:
		return {"exists": false}
	var active_ids := _metadata_normalize_character_id_list(save_data.get("active_party", []))
	if active_ids.is_empty():
		active_ids = _metadata_normalize_character_id_list(save_data.get("party_roster", []))
	if active_ids.size() > MAX_ACTIVE_PARTY_SIZE:
		active_ids.resize(MAX_ACTIVE_PARTY_SIZE)
	var party_names: Array[String] = []
	var raw_names: Variant = save_data.get("party_display_names", [])
	if raw_names is Array:
		for raw_name in raw_names:
			var display_name := str(raw_name).strip_edges()
			if not display_name.is_empty():
				party_names.append(display_name)
	if party_names.is_empty():
		for member in active_ids:
			party_names.append(Constants.CHARACTER_DISPLAY_NAMES.get(member, str(member)))
	var leader_level := 0
	if not active_ids.is_empty():
		var leader_id := active_ids[0]
		var char_data: Variant = save_data.get("character_data", {})
		if char_data is Dictionary:
			var char_dict := char_data as Dictionary
			var leader_state: Variant = char_dict.get(leader_id, char_dict.get(str(leader_id), {}))
			if leader_state is Dictionary:
				leader_level = maxi(_metadata_read_int((leader_state as Dictionary).get("level", 1), 1), 1)
	var version := _metadata_read_int(save_data.get("save_version", 0), 0)
	return {
		"exists": true,
		"compatible": version <= Constants.SAVE_VERSION,
		"version": version,
		"timestamp": _metadata_read_int(save_data.get("timestamp", 0), 0),
		"party_names": party_names,
		"gold": maxi(_metadata_read_int(save_data.get("gold", 0), 0), 0),
		"leader_level": leader_level,
	}


## Deserialize persistent state from a loaded dictionary.
## Returns false if save version is from the future or data is invalid.
func deserialize_persistent(data: Variant) -> bool:
	if not data is Dictionary:
		_report_validation_error("GameState: deserialize_persistent received non-Dictionary data.")
		return false
	var save_data := data as Dictionary
	var schema := str(save_data.get("save_schema", "")).strip_edges()
	if not schema.is_empty() and schema != SAVE_SCHEMA:
		_report_validation_error("GameState: Save schema '%s' is unsupported." % schema)
		return false

	# Version gate — reject saves from future versions.
	var version := _read_non_negative_int(save_data.get("save_version", 0), 0)
	if version > Constants.SAVE_VERSION:
		_report_validation_error("GameState: Save version %d is newer than supported %d." % [version, Constants.SAVE_VERSION])
		return false

	# Warn about missing fields but continue with defaults.
	var normalized_active_party := _normalize_character_id_list(save_data.get("active_party", []))
	if normalized_active_party.size() > MAX_ACTIVE_PARTY_SIZE:
		normalized_active_party.resize(MAX_ACTIVE_PARTY_SIZE)
	var normalized_roster := _normalize_character_id_list(save_data.get("party_roster", []))
	_append_missing_character_ids(normalized_roster, normalized_active_party)
	_append_character_data_keys(normalized_roster, save_data.get("character_data", {}))
	if normalized_active_party.is_empty() and not normalized_roster.is_empty():
		normalized_active_party.append(normalized_roster[0])

	# Party roster — type-safe array conversion.
	party_roster = normalized_roster
	character_data = _normalize_character_records(save_data.get("character_data", {}), party_roster, version)

	# Inventory — type-safe array conversion.
	inventory = _normalize_inventory_entries(save_data.get("inventory", []))

	# Gold — type-safe numeric conversion.
	gold = _read_non_negative_int(save_data.get("gold", 0), 0)

	# Story flags.
	story_flags = _normalize_story_flags(save_data.get("story_flags", {}))

	# Active party — type-safe array conversion.
	active_party = normalized_active_party
	current_overworld_node = _normalize_overworld_node(save_data.get("current_overworld_node", "piata"))

	return true


func set_validation_error_handler(handler: Callable) -> void:
	validation_error_handler = handler


func clear_validation_error_handler() -> void:
	validation_error_handler = Callable()


func _report_validation_error(message: String) -> void:
	if validation_error_handler.is_valid():
		validation_error_handler.call(message)
		return
	push_error(message)


func _build_default_character_record(character_id: StringName) -> Dictionary:
	var base_stats: Dictionary = {"strength": 5, "magic": 5, "defense": 5, "agility": 5}
	if character_id in Constants.CHARACTER_DEFS:
		var def := load(Constants.CHARACTER_DEFS[character_id]) as CharacterDef
		if def:
			base_stats = def.base_stats.duplicate()
	return {
		"level": 1,
		"xp": 0,
		"hp": Constants.PLAYER_MAX_HP,
		"max_hp": Constants.PLAYER_MAX_HP,
		"tp": Constants.TP_MAX,
		"stats": base_stats,
		"stat_points_available": 0,
		"equipped": _build_default_equipped_state(),
		"techniques_learned": [],
		"skill_tree_progress": {},
	}


func _build_default_equipped_state() -> Dictionary:
	var equipped: Dictionary = {}
	for slot: StringName in EquipmentManager.VALID_SLOTS:
		equipped[slot] = &""
	return equipped


func _build_serialized_roster(
	active_party_snapshot: Array[StringName],
	roster_snapshot: Array[StringName],
	source_character_data: Dictionary
) -> Array[StringName]:
	var normalized_roster := _normalize_character_id_list(roster_snapshot)
	_append_missing_character_ids(normalized_roster, active_party_snapshot)
	_append_character_data_keys(normalized_roster, source_character_data)
	return normalized_roster


func _serialize_character_records(roster: Array[StringName]) -> Dictionary:
	var serialized: Dictionary = {}
	for char_id: StringName in roster:
		serialized[char_id] = _normalize_character_record(char_id, character_data.get(char_id, {}), Constants.SAVE_VERSION)
	return serialized


func _normalize_character_records(raw_character_data: Variant, required_ids: Array[StringName], source_version: int) -> Dictionary:
	var normalized: Dictionary = {}
	if raw_character_data is Dictionary:
		var raw_dict := raw_character_data as Dictionary
		for raw_key in raw_dict.keys():
			var char_id := StringName(raw_key)
			if char_id == &"":
				continue
			normalized[char_id] = _normalize_character_record(char_id, raw_dict[raw_key], source_version)
	for char_id: StringName in required_ids:
		if char_id not in normalized:
			normalized[char_id] = _build_default_character_record(char_id)
	return normalized


func _normalize_character_record(character_id: StringName, raw_state: Variant, _source_version: int) -> Dictionary:
	var defaults := _build_default_character_record(character_id)
	if not raw_state is Dictionary:
		return defaults
	var source := raw_state as Dictionary
	var normalized := defaults.duplicate(true)
	normalized["level"] = maxi(_read_non_negative_int(source.get("level", defaults.get("level", 1)), 1), 1)
	normalized["xp"] = _read_non_negative_int(source.get("xp", defaults.get("xp", 0)), 0)

	var default_max_hp := float(defaults.get("max_hp", Constants.PLAYER_MAX_HP))
	var max_hp := _read_float(_get_first_present_value(source, ["max_hp"], default_max_hp), default_max_hp)
	if max_hp <= 0.0:
		max_hp = default_max_hp
	normalized["max_hp"] = max_hp
	normalized["hp"] = clampf(
		_read_float(_get_first_present_value(source, ["hp"], max_hp), max_hp),
		0.0,
		max_hp
	)
	normalized["tp"] = clampf(
		_read_float(_get_first_present_value(source, ["tp"], Constants.TP_MAX), Constants.TP_MAX),
		0.0,
		Constants.TP_MAX
	)
	normalized["stat_points_available"] = _read_non_negative_int(
		_get_first_present_value(source, ["stat_points_available", "stat_points"], 0),
		0
	)
	normalized["stats"] = _normalize_stats(source.get("stats", defaults.get("stats", {})), defaults.get("stats", {}))
	normalized["equipped"] = _normalize_equipped_state(
		_get_first_present_value(source, ["equipped", "equipment"], defaults.get("equipped", {}))
	)
	normalized["techniques_learned"] = _normalize_string_id_array(
		_get_first_present_value(source, ["techniques_learned", "techniques"], defaults.get("techniques_learned", []))
	)
	normalized["skill_tree_progress"] = _normalize_boolean_dictionary(
		_get_first_present_value(source, ["skill_tree_progress", "skill_tree"], defaults.get("skill_tree_progress", {}))
	)
	return normalized


func _normalize_character_id_list(value: Variant) -> Array[StringName]:
	var normalized: Array[StringName] = []
	if not value is Array:
		return normalized
	for entry in value:
		var char_id := StringName(entry)
		if char_id == &"" or char_id in normalized:
			continue
		normalized.append(char_id)
	return normalized


func _append_missing_character_ids(target: Array[StringName], additions: Array[StringName]) -> void:
	for char_id: StringName in additions:
		if char_id == &"" or char_id in target:
			continue
		target.append(char_id)


func _append_character_data_keys(target: Array[StringName], raw_character_data: Variant) -> void:
	if not raw_character_data is Dictionary:
		return
	for raw_key in (raw_character_data as Dictionary).keys():
		var char_id := StringName(raw_key)
		if char_id == &"" or char_id in target:
			continue
		target.append(char_id)


func _normalize_inventory_entries(raw_inventory: Variant) -> Array[Dictionary]:
	var entries: Array = []
	if raw_inventory is Array:
		entries = raw_inventory
	var manager := InventoryManager.new()
	manager.set_state(entries)
	var normalized: Array[Dictionary] = []
	for entry: Dictionary in manager.get_all_items():
		normalized.append(_hydrate_inventory_entry(entry))
	return normalized


func _normalize_story_flags(raw_flags: Variant) -> Dictionary:
	if not raw_flags is Dictionary:
		return {}
	return (raw_flags as Dictionary).duplicate(true)


func _normalize_overworld_node(raw_value: Variant) -> StringName:
	var node_id := StringName(raw_value)
	if node_id == &"":
		return &"piata"
	return node_id


func _normalize_stats(raw_stats: Variant, default_stats: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if default_stats is Dictionary:
		normalized = (default_stats as Dictionary).duplicate(true)
	if not raw_stats is Dictionary:
		return normalized
	var stats := raw_stats as Dictionary
	for raw_key in stats.keys():
		var stat_key := StringName(raw_key)
		if stat_key == &"":
			continue
		var stat_value: Variant = stats.get(raw_key)
		if stat_value is int or stat_value is float:
			normalized[stat_key] = int(stat_value)
	return normalized


func _normalize_equipped_state(raw_equipped: Variant) -> Dictionary:
	var normalized := _build_default_equipped_state()
	if not raw_equipped is Dictionary:
		return normalized
	var equipped := raw_equipped as Dictionary
	for slot: StringName in EquipmentManager.VALID_SLOTS:
		normalized[slot] = StringName(equipped.get(slot, ""))
	return normalized


func _normalize_string_id_array(raw_values: Variant) -> Array:
	var normalized: Array = []
	if not raw_values is Array:
		return normalized
	for entry in raw_values:
		var entry_id := StringName(entry)
		if entry_id == &"" or entry_id in normalized:
			continue
		normalized.append(entry_id)
	return normalized


func _normalize_boolean_dictionary(raw_values: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not raw_values is Dictionary:
		return normalized
	var source := raw_values as Dictionary
	for raw_key in source.keys():
		var key := StringName(raw_key)
		if key == &"":
			continue
		normalized[key] = bool(source[raw_key])
	return normalized


func _get_first_present_value(data: Dictionary, field_names: Array[String], fallback: Variant = null) -> Variant:
	for field_name in field_names:
		if data.has(field_name):
			return data.get(field_name)
	return fallback


func _read_non_negative_int(value: Variant, default_value: int) -> int:
	if value is int or value is float:
		return maxi(int(value), 0)
	return maxi(default_value, 0)


func _read_float(value: Variant, default_value: float) -> float:
	if value is int or value is float:
		return float(value)
	return default_value


static func _metadata_normalize_character_id_list(value: Variant) -> Array[StringName]:
	var normalized: Array[StringName] = []
	if not value is Array:
		return normalized
	for entry in value:
		var char_id := StringName(entry)
		if char_id == &"" or char_id in normalized:
			continue
		normalized.append(char_id)
	return normalized


static func _metadata_read_int(value: Variant, default_value: int) -> int:
	if value is int or value is float:
		return int(value)
	return default_value


func _build_inventory_manager() -> InventoryManager:
	var manager := InventoryManager.new()
	manager.set_state(inventory)
	return manager


func _hydrate_inventory_entry(entry: Dictionary) -> Dictionary:
	var normalized := InventoryManager.normalize_item_entry(entry)
	if normalized.is_empty():
		return {}
	var item_id := StringName(normalized.get("item_id", ""))
	var defaults := _get_item_defaults(item_id)
	if defaults.is_empty():
		return normalized
	if str(normalized.get("display_name", "")).strip_edges().is_empty():
		normalized["display_name"] = defaults.get("display_name", "")
	if str(normalized.get("description", "")).strip_edges().is_empty():
		normalized["description"] = defaults.get("description", "")
	if StringName(normalized.get("slot", "")) == &"":
		normalized["slot"] = StringName(defaults.get("slot", ""))
	if int(normalized.get("cost", 0)) <= 0:
		normalized["cost"] = int(defaults.get("cost", 0))
	if int(normalized.get("required_level", 1)) <= 1 and int(defaults.get("required_level", 1)) > 1:
		normalized["required_level"] = int(defaults.get("required_level", 1))
	var stat_bonuses := normalized.get("stat_bonuses", {}) as Dictionary
	if stat_bonuses.is_empty():
		normalized["stat_bonuses"] = (defaults.get("stat_bonuses", {}) as Dictionary).duplicate(true)
	var passive_effects := normalized.get("passive_effects", {}) as Dictionary
	if passive_effects.is_empty():
		normalized["passive_effects"] = (defaults.get("passive_effects", {}) as Dictionary).duplicate(true)
	return normalized


func _get_item_defaults(item_id: StringName) -> Dictionary:
	var def := _load_equipment_def(item_id)
	if def == null:
		return {}
	return InventoryManager.from_equipment_def(def)


func _load_equipment_def(item_id: StringName) -> EquipmentDef:
	if item_id == &"":
		return null
	var path := "res://resources/equipment/%s.tres" % str(item_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as EquipmentDef
