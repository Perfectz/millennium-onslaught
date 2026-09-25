## A usable item (PSIV consumables: Monomate, Dimate, Trimate, Antidote, Star/Moon/Sol Dew, pipes...).
class_name ItemDef
extends Resource


@export var item_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
## "consumable" or "key".
@export var category: StringName = &"consumable"
## Flat HP restored.
@export var heal_hp: float = 0.0
## Fraction of max HP restored (stacks with heal_hp).
@export var heal_hp_ratio: float = 0.0
@export var heal_tp: float = 0.0
## Status effects removed (e.g. poison, paralysis).
@export var cures: Array[StringName] = []
## Can restore a KO'd character.
@export var revive: bool = false
## Battlefield pickup: consumed instantly on touch (musou-style) instead of going to the bag.
@export var auto_use_on_pickup: bool = false
## Pickup orb colour.
@export var pickup_color: Color = Color(0.4, 0.9, 1.0)
## Special out-of-battle effect: "", "telepipe" (return to town), "escapipe" (leave dungeon).
@export var field_effect: StringName = &""
