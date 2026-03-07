## Data definition for a complete dungeon.
## Supports legacy room mode and continuous stage mode.
class_name DungeonDef
extends Resource


## Unique dungeon identifier.
@export var dungeon_id: StringName = &""

## Display name.
@export var dungeon_name: String = ""

## Ordered list of room scene paths for legacy room-based dungeons.
@export var room_scenes: Array[String] = []

## Encounter definitions for legacy room mode (index matches room_scenes).
@export var room_encounters: Array[EncounterDef] = []

## Boss encounter for the final room in legacy room mode.
@export var boss_encounter: EncounterDef = null

## Whether the dungeon is currently unlocked (managed by story flags at runtime).
@export var requires_story_flag: StringName = &""

## Optional: when set, this dungeon uses single-stage continuous mode instead of rooms.
@export var stage_def: StageDef = null

## Optional: multi-stage mode for sequential continuous stages (for example, multiple floors).
@export var stage_defs: Array[StageDef] = []
