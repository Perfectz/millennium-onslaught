## Data definition for an enemy type. Pure data — no logic beyond defaults.
## Used to configure EnemyController instances at spawn time.
class_name EnemyDef
extends Resource


## Display name for UI and debugging.
@export var enemy_name: StringName = &""

## Enemy type identifier for encounter system and score tracking.
@export var enemy_type: StringName = &""

## Base HP for this enemy type.
@export var base_hp: float = 50.0

## Movement speed.
@export var move_speed: float = 4.0

## Attack range — how close the enemy needs to be to attack.
@export var attack_range: float = 1.5

## Perception delay — reaction time before noticing the player.
@export var perception_delay: float = 0.3

## Attack cooldown between consecutive attacks.
@export var attack_cooldown: float = 1.5

## Which attack resource this enemy uses.
@export var attack: AttackDef = null

## AI behavior type: "rusher", "ranged", "shield"
@export var behavior: StringName = &"rusher"

## Whether this enemy blocks frontal attacks.
@export var can_block: bool = false

## Block damage reduction (0.0 = full block, 1.0 = no block).
@export var block_damage_reduction: float = 0.0

## Resistance to incoming knockback (0.0 = normal, 1.0 = immovable).
@export var knockback_resistance: float = 0.0

## Projectile scene for ranged enemies.
@export var projectile_scene: PackedScene = null

## Color for placeholder mesh (visual identification).
@export var mesh_color: Color = Color.RED

## XP reward on death.
@export var xp_reward: int = 10

## Gold dropped on death.
@export var gold_reward: int = 5

## Equipment drop table. Each entry: {item_id: StringName, chance: float (0.0-1.0)}
@export var drop_table: Array[Dictionary] = []

## Elemental weakness (takes bonus damage from this element).
@export var weakness: StringName = &""

## Elemental resistance (takes reduced damage from this element).
@export var resistance: StringName = &""
