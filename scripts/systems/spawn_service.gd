## Handles enemy spawning via ObjectPool with position validation.
## Stateless — spawn requests produce positioned enemy instances.
class_name SpawnService
extends RefCounted


## Spawn an enemy of a given type at a position.
## Returns the spawned enemy node or null if pool is empty.
static func spawn_enemy(
	enemy_type: StringName,
	position: Vector3,
	parent: Node
) -> Node:
	var enemy: Node = ObjectPool.get_instance(enemy_type)
	if enemy == null:
		push_warning("SpawnService: Pool empty for type: " + str(enemy_type))
		return null
	if enemy is Node3D:
		(enemy as Node3D).global_position = position
	if enemy.get_parent() != parent:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		parent.add_child(enemy)
	# Emit spawn event.
	EventBus.enemy_spawned.emit(enemy, enemy_type)
	EventBus.log_event(&"enemy_spawned", {
		"type": enemy_type,
		"position": {"x": position.x, "y": position.y, "z": position.z},
	})
	return enemy


## Spawn a wave of enemies from wave data and positions.
static func spawn_wave(
	wave_data: Dictionary,
	positions: Array[Vector3],
	parent: Node,
	wave_system: WaveSystem
) -> Array[Node]:
	var spawned: Array[Node] = []
	var enemies: Array = wave_data.get("enemies", [])
	for i: int in enemies.size():
		var enemy_def: Dictionary = enemies[i]
		var enemy_type: StringName = enemy_def.get("type", &"")
		var pos: Vector3 = positions[i] if i < positions.size() else Vector3.ZERO
		var enemy: Node = spawn_enemy(enemy_type, pos, parent)
		if enemy:
			spawned.append(enemy)
			wave_system.register_enemy(enemy)
	return spawned


## Return an enemy to the pool (call on death after VFX).
static func despawn_enemy(enemy: Node) -> void:
	ObjectPool.return_instance(enemy)


## Validate spawn position is within room bounds.
static func is_valid_spawn_position(
	position: Vector3,
	room_min: Vector3,
	room_max: Vector3
) -> bool:
	return (
		position.x >= room_min.x and position.x <= room_max.x and
		position.y >= room_min.y and position.y <= room_max.y and
		position.z >= room_min.z and position.z <= room_max.z
	)
