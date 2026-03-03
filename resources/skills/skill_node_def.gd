## Data definition for a single node in a character's skill tree.
class_name SkillNodeDef
extends Resource


## Unique skill identifier.
@export var skill_id: StringName = &""

## Display name for UI.
@export var display_name: String = ""

## Description of what this skill does.
@export var description: String = ""

## Stat bonuses granted when unlocked.
@export var stat_bonuses: Dictionary = {}

## Passive effects granted when unlocked (e.g., {"crit_chance": 0.05}).
@export var passive_effects: Dictionary = {}

## Skill IDs that must be unlocked before this one.
@export var prerequisites: Array[StringName] = []

## Skill points required to unlock.
@export var point_cost: int = 1

## Tier for UI layout (0 = root, 1 = mid, 2 = capstone).
@export var tier: int = 0

## Position hint for UI layout.
@export var ui_position: Vector2 = Vector2.ZERO
