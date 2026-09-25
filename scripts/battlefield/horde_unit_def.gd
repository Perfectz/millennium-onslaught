## Data for a lightweight horde grunt type (the mass enemies of battlefield mode).
class_name HordeUnitDef
extends Resource


## Stable id used for events, analytics and tallies.
@export var unit_id: StringName = &"crawler"
## Name shown in UI.
@export var display_name: String = "Crawler"
@export var max_hp: float = 28.0
@export var move_speed: float = 4.2
## Attack the grunt performs when it holds an attack token.
@export var attack: AttackDef = null
@export var knockback_resistance: float = 0.0
@export var weakness: StringName = &""
@export var resistance: StringName = &""
## Procedural body style (see HordeMeshFactory): PSIV families "grub", "mantis", "cone_slime", "beetle",
## "fly", "newt", "mushroom", "spider_crab", "tentacle", "bird", "soldier"; generic "blob", "insect", "brute".
@export var body_style: StringName = &"blob"
@export var body_color: Color = Color(0.55, 0.75, 0.3)
@export var accent_color: Color = Color(0.95, 0.85, 0.2)
@export var body_scale: float = 1.0
## Collision radius used for hurtbox and crowd separation.
@export var radius: float = 0.5
## Drops rolled on KO: [{item_id: StringName, chance: float}] (see DropRoller).
@export var drop_table: Array[Dictionary] = []
