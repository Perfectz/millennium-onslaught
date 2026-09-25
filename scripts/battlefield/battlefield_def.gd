## Data for one battlefield (Dynasty-Warriors style open battle map).
class_name BattlefieldDef
extends Resource


@export var battlefield_id: StringName = &""
@export var display_name: String = ""
@export var subtitle: String = ""
## Full playable area in metres (X width, Z depth), centred on the origin.
@export var arena_size: Vector2 = Vector2(110, 110)
@export var player_spawn: Vector2 = Vector2.ZERO
@export var bases: Array[BattlefieldBaseDef] = []
## Enemy commander that appears once every enemy base has fallen.
@export var commander_def: EnemyDef = null
@export var commander_name: String = ""
@export var commander_spawn: Vector2 = Vector2.ZERO
@export var commander_escort: int = 10
@export var commander_escort_unit: HordeUnitDef = null
## Roaming reinforcements sent from enemy bases toward the player.
@export var reinforcement_units: Array[HordeUnitDef] = []
@export var reinforcement_squad_size: int = 8
@export var reinforcement_interval: float = 6.0
## Soft cap on grunts alive at once (hard cap is Constants.HORDE_MAX_GRUNTS).
@export var max_alive: int = 110
## Look.
@export var ground_color: Color = Color(0.78, 0.62, 0.4)
@export var ground_color_alt: Color = Color(0.66, 0.5, 0.32)
@export var sky_top_color: Color = Color(0.32, 0.55, 0.85)
@export var sky_horizon_color: Color = Color(0.93, 0.78, 0.58)
@export var scatter_seed: int = 4
@export var music_track: StringName = &"stage_2"
## Story flag set on victory (unlocks later overworld nodes).
@export var victory_flag: StringName = &""
