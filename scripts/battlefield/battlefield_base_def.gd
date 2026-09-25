## A capturable base (outpost / bio-hive) on a battlefield.
class_name BattlefieldBaseDef
extends Resource


@export var base_id: StringName = &""
@export var display_name: String = ""
## XZ position on the battlefield.
@export var position: Vector2 = Vector2.ZERO
## Starting owner (BattlefieldControl.Side: 0 neutral, 1 ally, 2 enemy).
@export var side: int = 2
## Horde grunts guarding the base; all must fall (plus the officer) before it can be taken.
@export var garrison: int = 18
## Grunt types the garrison is drawn from (cycled).
@export var garrison_units: Array[HordeUnitDef] = []
## Officer guarding the base (full EnemyController). Leave null for no officer.
@export var officer_def: EnemyDef = null
@export var officer_name: String = ""
