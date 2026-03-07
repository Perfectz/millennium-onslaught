## Dedicated transient runtime state for the active session and dungeon run.
## This data is never serialized into RPG save files.
class_name RuntimeStateSingleton
extends Node


const DEFAULT_MIN_X := -100.0
const DEFAULT_MAX_X := 100.0
const DEFAULT_MIN_Z := -100.0
const DEFAULT_MAX_Z := 100.0


## Current game phase.
var current_phase: StringName = &"main_menu"

## Current dungeon session identifiers.
var current_dungeon_id: StringName = &""
var current_room_index: int = 0

## Temporary rewards/buffs gained during the active dungeon run.
var dungeon_buffs: Array[Dictionary] = []
var dungeon_drops: Array[Dictionary] = []

## Active encounter state.
var encounter_active: bool = false
var encounter_enemies_alive: int = 0

## Arena lock bounds (set when an encounter owns the active arena).
var arena_lock_min_x: float = DEFAULT_MIN_X
var arena_lock_max_x: float = DEFAULT_MAX_X
var arena_lock_min_z: float = DEFAULT_MIN_Z
var arena_lock_max_z: float = DEFAULT_MAX_Z

## Active room/stage traversal bounds.
var room_bounds_active: bool = false
var room_bounds_min_x: float = DEFAULT_MIN_X
var room_bounds_max_x: float = DEFAULT_MAX_X
var room_bounds_min_z: float = DEFAULT_MIN_Z
var room_bounds_max_z: float = DEFAULT_MAX_Z

## Stage progression state for multi-floor continuous dungeons.
var stage_mode: bool = false
var current_stage_id: StringName = &""
var stage_encounters_completed: int = 0
var stage_total_encounters: int = 0
var current_stage_index: int = 0
var stage_floor_count: int = 0


func reset_dungeon() -> void:
	current_dungeon_id = &""
	current_room_index = 0
	dungeon_buffs.clear()
	dungeon_drops.clear()
	encounter_active = false
	encounter_enemies_alive = 0
	clear_arena_bounds()
	clear_room_bounds()
	stage_mode = false
	current_stage_id = &""
	stage_encounters_completed = 0
	stage_total_encounters = 0
	current_stage_index = 0
	stage_floor_count = 0


func set_room_bounds(min_x: float, max_x: float, min_z: float = DEFAULT_MIN_Z, max_z: float = DEFAULT_MAX_Z) -> void:
	if min_x >= max_x:
		clear_room_bounds()
		return
	room_bounds_active = true
	room_bounds_min_x = min_x
	room_bounds_max_x = max_x
	room_bounds_min_z = min_z
	room_bounds_max_z = max_z


func clear_room_bounds() -> void:
	room_bounds_active = false
	room_bounds_min_x = DEFAULT_MIN_X
	room_bounds_max_x = DEFAULT_MAX_X
	room_bounds_min_z = DEFAULT_MIN_Z
	room_bounds_max_z = DEFAULT_MAX_Z


func clear_arena_bounds() -> void:
	arena_lock_min_x = DEFAULT_MIN_X
	arena_lock_max_x = DEFAULT_MAX_X
	arena_lock_min_z = DEFAULT_MIN_Z
	arena_lock_max_z = DEFAULT_MAX_Z


func get_room_bounds() -> Dictionary:
	return {
		"min_x": room_bounds_min_x,
		"max_x": room_bounds_max_x,
		"min_z": room_bounds_min_z,
		"max_z": room_bounds_max_z,
		"source": "room",
	}


func get_arena_bounds() -> Dictionary:
	return {
		"min_x": arena_lock_min_x,
		"max_x": arena_lock_max_x,
		"min_z": arena_lock_min_z,
		"max_z": arena_lock_max_z,
		"source": "arena",
	}


func get_active_bounds() -> Dictionary:
	if room_bounds_active:
		return get_room_bounds()
	if encounter_active:
		return get_arena_bounds()
	return {
		"min_x": DEFAULT_MIN_X,
		"max_x": DEFAULT_MAX_X,
		"min_z": DEFAULT_MIN_Z,
		"max_z": DEFAULT_MAX_Z,
		"source": "default",
	}


func get_debug_snapshot() -> Dictionary:
	return {
		"phase": current_phase,
		"current_dungeon_id": current_dungeon_id,
		"current_stage_id": current_stage_id,
		"current_stage_index": current_stage_index,
		"stage_encounters_completed": stage_encounters_completed,
		"stage_total_encounters": stage_total_encounters,
		"stage_floor_count": stage_floor_count,
		"current_room_index": current_room_index,
		"encounter_active": encounter_active,
		"encounter_enemies_alive": encounter_enemies_alive,
		"room_bounds_active": room_bounds_active,
		"room_bounds": {
			"min_x": room_bounds_min_x,
			"max_x": room_bounds_max_x,
			"min_z": room_bounds_min_z,
			"max_z": room_bounds_max_z,
		},
		"arena_bounds": {
			"min_x": arena_lock_min_x,
			"max_x": arena_lock_max_x,
			"min_z": arena_lock_min_z,
			"max_z": arena_lock_max_z,
		},
		"active_party": GameState.active_party.duplicate(),
		"party_roster": GameState.party_roster.duplicate(),
		"gold": GameState.gold,
	}
