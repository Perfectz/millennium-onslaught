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


## Current game phase.
var current_phase: StringName = &"main_menu"


## Initialize default character data for a new character.
func init_character(character_id: StringName) -> void:
	if character_id in character_data:
		return
	character_data[character_id] = {
		"level": 1,
		"xp": 0,
		"hp": 100.0,
		"max_hp": 100.0,
		"tp": Constants.TP_MAX,
		"stats": {
			"strength": 5,
			"magic": 5,
			"defense": 5,
			"agility": 5,
		},
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


## Bank transient rewards into persistent state. Called on dungeon completion.
func bank_dungeon_rewards() -> void:
	for drop in dungeon_drops:
		inventory.append(drop)
	reset_dungeon()


## Serialize persistent state to a dictionary for saving.
func serialize_persistent() -> Dictionary:
	return {
		"party_roster": party_roster.duplicate(),
		"character_data": character_data.duplicate(true),
		"inventory": inventory.duplicate(true),
		"gold": gold,
		"story_flags": story_flags.duplicate(true),
		"active_party": active_party.duplicate(),
	}


## Deserialize persistent state from a loaded dictionary.
## Returns false if required fields are missing or have wrong types.
func deserialize_persistent(data: Dictionary) -> bool:
	if not data is Dictionary:
		push_error("GameState: deserialize_persistent received non-Dictionary data.")
		return false

	# Validate required fields exist.
	var required_fields: Array[String] = ["party_roster", "character_data", "inventory", "gold", "story_flags", "active_party"]
	for field in required_fields:
		if field not in data:
			push_warning("GameState: Missing field '%s' in save data. Using default." % field)

	party_roster = data.get("party_roster", [])
	character_data = data.get("character_data", {})
	inventory = data.get("inventory", [])
	gold = int(data.get("gold", 0))
	story_flags = data.get("story_flags", {})
	active_party = data.get("active_party", [])
	return true
