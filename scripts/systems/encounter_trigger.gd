## Area3D trigger zone that activates an encounter when the player enters.
## Created dynamically by StageRunner at encounter positions.
class_name EncounterTrigger
extends Area3D


## Emitted once when the player first enters this trigger zone.
signal triggered(trigger_index: int)

## Index of this encounter within the StageDef.encounters array.
var trigger_index: int = -1

## Whether this trigger has already fired.
var _activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = Constants.LAYER_PLAYER
	monitoring = true
	monitorable = false


## Configure the trigger's collision shape at the given world X position (backward compat).
func setup_shape(world_x: float, depth: float = Constants.STAGE_TRIGGER_BOX_DEPTH) -> void:
	setup_shape_at(Vector3(world_x, Constants.STAGE_TRIGGER_BOX_HEIGHT * 0.5, 0.0), depth)


## Configure the trigger's collision shape at an arbitrary world position.
func setup_shape_at(world_pos: Vector3, depth: float = Constants.STAGE_TRIGGER_BOX_DEPTH) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		Constants.STAGE_TRIGGER_BOX_WIDTH,
		Constants.STAGE_TRIGGER_BOX_HEIGHT,
		maxf(depth, Constants.STAGE_TRIGGER_BOX_DEPTH)
	)
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)
	if is_inside_tree():
		global_position = world_pos
	else:
		position = world_pos


## Check if this trigger has already been activated.
func is_activated() -> bool:
	return _activated


## Reset trigger so it can fire again (used for debug/restart).
func reset() -> void:
	_activated = false


func _on_body_entered(body: Node3D) -> void:
	if _activated:
		return
	# Only trigger on the player (collision mask already filters, but double-check).
	if not (body is CharacterBody3D and body.collision_layer & Constants.LAYER_PLAYER):
		return
	_activated = true
	triggered.emit(trigger_index)
	EventBus.stage_encounter_triggered.emit(trigger_index)
