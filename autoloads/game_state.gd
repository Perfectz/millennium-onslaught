## Single source of truth for all game data.
## Split into persistent (RPG, saved to file) and transient (dungeon-only, lost on death).
class_name GameStateSingleton
extends Node


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


# --- Transient State (lost on dungeon death, never saved) ---

## Current dungeon being played.
var current_dungeon_id: StringName = &""

## Current room index within the dungeon.
var current_room_index: int = 0

## Temporary buffs from dungeon pickups.
var dungeon_buffs: Array[Dictionary] = []

## Items found in dungeon, not yet banked.
var dungeon_drops: Array[Dictionary] = []

## Current encounter state.
var encounter_active: bool = false
var encounter_enemies_alive: int = 0

## Arena lock bounds (set when encounter with arena_lock starts).
var arena_lock_min_x: float = -100.0
var arena_lock_max_x: float = 100.0
var arena_lock_min_z: float = -100.0
var arena_lock_max_z: float = 100.0

## Current room bounds (always-on clamp while active).
var room_bounds_active: bool = false
var room_bounds_min_x: float = -100.0
var room_bounds_max_x: float = 100.0

## Stage mode (transient — lost on dungeon death).
var stage_mode: bool = false
var current_stage_id: StringName = &""
var stage_encounters_completed: int = 0
var stage_total_encounters: int = 0


## Current game phase.
var current_phase: StringName = &"main_menu"


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
	party_roster = [&"alys"]
	active_party = [&"alys"]
	character_data.clear()
	init_character(&"alys")
	inventory.clear()
	gold = 100
	story_flags.clear()
	current_overworld_node = &"piata"
	active_save_slot = 0
	reset_dungeon()


## Initialize default character data for a new character.
## Loads base stats from CharacterDef if available, otherwise uses generic defaults.
func init_character(character_id: StringName) -> void:
	if character_id in character_data:
		return
	# Try loading base stats from CharacterDef resource.
	var base_stats: Dictionary = {"strength": 5, "magic": 5, "defense": 5, "agility": 5}
	if character_id in Constants.CHARACTER_DEFS:
		var def := load(Constants.CHARACTER_DEFS[character_id]) as CharacterDef
		if def:
			base_stats = def.base_stats.duplicate()
	character_data[character_id] = {
		"level": 1,
		"xp": 0,
		"hp": Constants.PLAYER_MAX_HP,
		"max_hp": Constants.PLAYER_MAX_HP,
		"tp": Constants.TP_MAX,
		"stats": base_stats,
		"stat_points_available": 0,
		"equipped": {
			"weapon": &"",
			"armor": &"",
			"accessory": &"",
		},
		"techniques_learned": [],
		"skill_tree_progress": {},
	}


## Reset all transient dungeon state. Called on dungeon death.
func reset_dungeon() -> void:
	current_dungeon_id = &""
	current_room_index = 0
	dungeon_buffs.clear()
	dungeon_drops.clear()
	encounter_active = false
	encounter_enemies_alive = 0
	arena_lock_min_x = -100.0
	arena_lock_max_x = 100.0
	arena_lock_min_z = -100.0
	arena_lock_max_z = 100.0
	clear_room_bounds()
	stage_mode = false
	current_stage_id = &""
	stage_encounters_completed = 0
	stage_total_encounters = 0


## Set active room X bounds used for player clamping and safer knockback.
func set_room_bounds(min_x: float, max_x: float) -> void:
	if min_x >= max_x:
		clear_room_bounds()
		return
	room_bounds_active = true
	room_bounds_min_x = min_x
	room_bounds_max_x = max_x


## Disable room X bounds and restore wide defaults.
func clear_room_bounds() -> void:
	room_bounds_active = false
	room_bounds_min_x = -100.0
	room_bounds_max_x = 100.0


## Bank transient rewards into persistent state. Called on dungeon completion.
func bank_dungeon_rewards() -> void:
	for drop in dungeon_drops:
		inventory.append(drop)
	reset_dungeon()


## Serialize persistent state to a dictionary for saving.
func serialize_persistent() -> Dictionary:
	var display_names: Array[String] = []
	for member in active_party:
		display_names.append(Constants.CHARACTER_DISPLAY_NAMES.get(member, str(member)))
	return {
		"save_version": Constants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"party_display_names": display_names,
		"party_roster": party_roster.duplicate(),
		"character_data": character_data.duplicate(true),
		"inventory": inventory.duplicate(true),
		"gold": gold,
		"story_flags": story_flags.duplicate(true),
		"active_party": active_party.duplicate(),
		"current_overworld_node": current_overworld_node,
	}


## Extract display-friendly metadata from raw save data without applying it.
static func get_save_metadata(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {"exists": false}
	var leader_id: String = ""
	var raw_party: Array = data.get("active_party", [])
	if raw_party.size() > 0:
		leader_id = str(raw_party[0])
	var leader_level: int = 0
	var char_data: Dictionary = data.get("character_data", {})
	if leader_id != "" and leader_id in char_data:
		leader_level = int(char_data[leader_id].get("level", 1))
	return {
		"exists": true,
		"version": int(data.get("save_version", 0)),
		"timestamp": data.get("timestamp", 0),
		"party_names": data.get("party_display_names", []),
		"gold": int(data.get("gold", 0)),
		"leader_level": leader_level,
	}


## Deserialize persistent state from a loaded dictionary.
## Returns false if save version is from the future or data is invalid.
func deserialize_persistent(data: Dictionary) -> bool:
	if not data is Dictionary:
		push_error("GameState: deserialize_persistent received non-Dictionary data.")
		return false

	# Version gate — reject saves from future versions.
	var version: int = int(data.get("save_version", 0))
	if version > Constants.SAVE_VERSION:
		push_error("GameState: Save version %d is newer than supported %d." % [version, Constants.SAVE_VERSION])
		return false

	# Warn about missing fields but continue with defaults.
	var required_fields: Array[String] = ["party_roster", "character_data", "inventory", "gold", "story_flags", "active_party"]
	for field in required_fields:
		if field not in data:
			push_warning("GameState: Missing field '%s' in save data. Using default." % field)

	# Party roster — type-safe array conversion.
	var raw_roster = data.get("party_roster", [])
	party_roster.clear()
	if raw_roster is Array:
		for entry in raw_roster:
			party_roster.append(StringName(entry))

	# Character data.
	var raw_char_data = data.get("character_data", {})
	if raw_char_data is Dictionary:
		character_data = raw_char_data
	else:
		character_data = {}

	# Inventory — type-safe array conversion.
	var raw_inventory = data.get("inventory", [])
	inventory.clear()
	if raw_inventory is Array:
		for entry in raw_inventory:
			inventory.append(entry as Dictionary)

	# Gold — type-safe numeric conversion.
	var raw_gold = data.get("gold", 0)
	if raw_gold is float or raw_gold is int:
		gold = int(raw_gold)
	else:
		gold = 0
		push_warning("GameState: Invalid gold type '%s'. Defaulting to 0." % str(typeof(raw_gold)))

	# Story flags.
	var raw_flags = data.get("story_flags", {})
	if raw_flags is Dictionary:
		story_flags = raw_flags
	else:
		story_flags = {}

	# Active party — type-safe array conversion.
	var raw_party = data.get("active_party", [])
	active_party.clear()
	if raw_party is Array:
		for entry in raw_party:
			active_party.append(StringName(entry))

	current_overworld_node = StringName(data.get("current_overworld_node", "piata"))
	return true
