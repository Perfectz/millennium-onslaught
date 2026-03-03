## Data definition for a single encounter (one wave or multi-wave fight).
## Used by the wave system to spawn enemies in a room.
class_name EncounterDef
extends Resource


## Encounter identifier.
@export var encounter_id: StringName = &""

## Array of waves. Each wave is an Array of spawn entries.
## Each spawn entry: { "enemy_def": EnemyDef, "count": int, "spawn_side": "left"/"right"/"both" }
@export var waves: Array[WaveDef] = []

## Whether the camera should arena-lock during this encounter.
@export var arena_lock: bool = true

## Arena bounds (left, right X limits) used during lock. Set in world coords.
@export var arena_min_x: float = -10.0
@export var arena_max_x: float = 10.0

## Arena Z bounds (near, far depth limits) for belt-depth clamping.
@export var arena_min_z: float = -3.0
@export var arena_max_z: float = 3.0
