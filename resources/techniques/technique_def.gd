## Data definition for a character technique or spell (special move).
## Techniques cost TP, deal elemental damage, and can apply status effects.
## Spells use the spell_type field to differentiate behavior (projectile, heal, AOE, buff).
class_name TechniqueDef
extends Resource


## Spell behavior type — determines execution logic in PlayerStateSpell.
enum SpellType { PROJECTILE, HEAL, AOE_BURST, BUFF }

## Unique identifier.
@export var technique_id: StringName = &""

## Display name shown in UI.
@export var display_name: String = ""

## Description for menus.
@export var description: String = ""

## TP cost to use this technique.
@export var tp_cost: float = 25.0

## Base damage before stat scaling.
@export var base_damage: float = 20.0

## Elemental type: "fire", "ice", "lightning", "dark", or "" for neutral.
@export var element_type: StringName = &""

## Chance (0.0-1.0) to apply the element's status effect.
@export var status_effect_chance: float = 0.3

## Duration of the applied status effect in seconds.
@export var status_effect_duration: float = 3.0

## Knockback force applied to target.
@export var knockback_force: float = 10.0

## Whether this technique fires a projectile.
@export var is_projectile: bool = true

## Projectile travel speed (if is_projectile is true).
@export var projectile_speed: float = 18.0

## Area of effect radius. 0 = single target.
@export var aoe_radius: float = 0.0

## Animation to play during technique.
@export var animation_name: StringName = &"attack_heavy"

## Color for the technique's visual effects.
@export var particle_color: Color = Color(0.3, 0.85, 1.0)

## Character level required to learn this technique.
@export var unlock_level: int = 1

## Whether damage scales with magic (true) or strength (false).
@export var scales_with_magic: bool = true

## Spell type — determines execution behavior (projectile, heal, AOE burst, buff).
@export var spell_type: SpellType = SpellType.PROJECTILE

## Amount of HP restored when spell_type is HEAL.
@export var heal_amount: float = 0.0

## Stat to buff when spell_type is BUFF (e.g., &"defense").
@export var buff_stat: StringName = &""

## Amount to add to the buffed stat.
@export var buff_amount: float = 0.0

## Duration of the buff in seconds.
@export var buff_duration: float = 0.0
