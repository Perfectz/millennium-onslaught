## Data definition for a single wave within an encounter.
## Contains spawn entries that define what enemies to spawn.
class_name WaveDef
extends Resource


## Spawn entries in this wave.
@export var spawn_entries: Array[SpawnEntry] = []

## Delay before this wave begins (after previous wave clears).
@export var delay_before_spawn: float = 1.0
