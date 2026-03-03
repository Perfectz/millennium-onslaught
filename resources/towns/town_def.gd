## Data definition for a town — shop inventory, inn, NPCs.
class_name TownDef
extends Resource


## Unique town identifier.
@export var town_id: StringName = &""

## Display name.
@export var town_name: String = ""

## Equipment available in this town's shop.
@export var shop_items: Array[EquipmentDef] = []

## Whether this town has an inn.
@export var has_inn: bool = true

## Inn cost multiplier (applied to Constants.INN_COST_BASE).
@export var inn_cost_multiplier: float = 1.0

## NPC dialogue entries. Each entry: {"name": String, "lines": Array[String], "requires_flag": StringName}
@export var npcs: Array[Dictionary] = []
