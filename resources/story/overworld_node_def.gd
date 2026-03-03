## Data definition for a node on the overworld map.
class_name OverworldNodeDef
extends Resource


## Unique node identifier.
@export var node_id: StringName = &""

## Display name on the map.
@export var display_name: String = ""

## Node type: "town", "dungeon", "landmark"
@export var node_type: StringName = &"town"

## Scene path to load when entering this node. Empty for landmarks.
@export var scene_path: String = ""

## IDs of connected nodes (bidirectional navigation).
@export var connections: Array[StringName] = []

## Story flag required to unlock this node. Empty means always unlocked.
@export var requires_flag: StringName = &""

## Position on the map UI (normalized 0-1 coordinates).
@export var map_position: Vector2 = Vector2(0.5, 0.5)

## Brief description shown when selected.
@export var description: String = ""
