## A single spawn entry within a wave — how many of which enemy, from where.
class_name SpawnEntry
extends Resource


## The enemy definition to spawn.
@export var enemy_def: EnemyDef = null

## How many of this enemy to spawn.
@export var count: int = 1

## Which side to spawn from: "left", "right", or "both" (split evenly).
@export var spawn_side: StringName = &"both"

## Spawn lightweight horde grunts instead of a full EnemyController (used when enemy_def is null).
@export var horde_unit: HordeUnitDef = null
