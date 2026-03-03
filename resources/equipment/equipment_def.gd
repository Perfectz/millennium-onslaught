## Data definition for a piece of equipment — weapons, armor, accessories.
class_name EquipmentDef
extends Resource


## Unique identifier.
@export var equipment_id: StringName = &""

## Display name.
@export var display_name: String = ""

## Description for shop UI.
@export var description: String = ""

## Gold cost in shops.
@export var cost: int = 0

## Equipment slot: "weapon", "armor", "accessory"
@export var slot: StringName = &"weapon"

## Stat bonuses applied when equipped. Keys are stat names, values are bonus amounts.
@export var stat_bonuses: Dictionary = {}

## Passive effects granted by this equipment. Keys: "crit_chance", "hp_regen", etc.
@export var passive_effects: Dictionary = {}

## Minimum character level required to equip.
@export var required_level: int = 1
