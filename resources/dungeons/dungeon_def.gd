## Data definition for a complete dungeon — sequence of rooms with encounters.
class_name DungeonDef
extends Resource


## Unique dungeon identifier.
@export var dungeon_id: StringName = &""

## Display name.
@export var dungeon_name: String = ""

## Ordered list of room scene paths.
@export var room_scenes: Array[String] = []

## Encounter definitions for each room (index matches room_scenes).
@export var room_encounters: Array[EncounterDef] = []

## Boss encounter for the final room.
@export var boss_encounter: EncounterDef = null

## Whether the dungeon is currently unlocked (managed by story flags at runtime).
@export var requires_story_flag: StringName = &""
