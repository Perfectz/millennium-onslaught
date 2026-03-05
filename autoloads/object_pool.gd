## Pre-instantiation pool for frequently spawned objects.
## Systems request objects from the pool instead of instantiating.
## Systems return objects to the pool instead of freeing.
class_name ObjectPoolSingleton
extends Node


## Pool storage: scene_path -> Array of inactive instances.
var _pools: Dictionary = {}

## Active instance tracking for debugging.
var _active_counts: Dictionary = {}


## Pre-populate a pool with a given number of instances.
func warm_pool(scene: PackedScene, count: int, pool_name: StringName = &"") -> void:
	var key: StringName = pool_name if pool_name != &"" else StringName(scene.resource_path)
	if key not in _pools:
		_pools[key] = []
		_active_counts[key] = 0
	for i in count:
		var instance := scene.instantiate()
		instance.set_meta(&"pool_key", key)
		instance.set_meta(&"pool_scene", scene)
		_deactivate(instance)
		_pools[key].append(instance)
		add_child(instance)


## Get an instance from the pool. Returns null if pool is empty.
func get_instance(pool_name: StringName) -> Node:
	if pool_name not in _pools or _pools[pool_name].is_empty():
		return null
	var instance: Node = _pools[pool_name].pop_back()
	_activate(instance)
	_active_counts[pool_name] += 1
	return instance


## Return an instance to its pool.
func return_instance(instance: Node) -> void:
	var key: StringName = instance.get_meta(&"pool_key", &"")
	if key == &"":
		push_warning("ObjectPool: Returning instance without pool_key meta. Freeing instead.")
		instance.queue_free()
		return
	if not instance.get_meta(&"pool_active", false):
		push_warning("ObjectPool: Double-return detected for pool '%s'. Ignoring." % key)
		return
	if key not in _pools:
		push_warning("ObjectPool: Key '%s' not registered in pool. Freeing instead." % key)
		instance.queue_free()
		return
	_deactivate(instance)
	_pools[key].append(instance)
	_active_counts[key] = maxi(0, _active_counts.get(key, 1) - 1)


## Get active instance count for a pool (debugging).
func get_active_count(pool_name: StringName) -> int:
	return _active_counts.get(pool_name, 0)


## Get total pool size (active + inactive) for a pool.
func get_total_count(pool_name: StringName) -> int:
	var inactive: int = _pools[pool_name].size() if pool_name in _pools else 0
	return inactive + get_active_count(pool_name)


func _activate(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	instance.visible = true
	instance.set_meta(&"pool_active", true)


func _deactivate(instance: Node) -> void:
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	instance.visible = false
	instance.set_meta(&"pool_active", false)
	if instance is Node3D:
		instance.position = Constants.POOL_DEACTIVATE_POSITION
