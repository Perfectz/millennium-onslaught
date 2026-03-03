## Data for a single encounter placement within a continuous stage.
## Defines where the encounter triggers and the arena bounds for the fight.
class_name StageEncounterEntry
extends Resource


## The encounter wave data (reused from existing EncounterDef system).
@export var encounter_def: EncounterDef = null

## World X position where this encounter triggers when the player crosses it.
@export var trigger_x: float = 0.0

## Arena lock extends trigger_x +/- this value.
@export var arena_half_width: float = 12.0

## Belt-depth Z bounds during arena lock.
@export var arena_min_z: float = -3.0
@export var arena_max_z: float = 3.0

## If true, this is the final boss encounter of the stage.
@export var is_boss: bool = false
