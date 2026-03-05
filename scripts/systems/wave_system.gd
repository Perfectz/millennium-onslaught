## Manages enemy wave spawning, tracking, and wave-clear detection.
class_name WaveSystem
extends Node


signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_cleared()

## Wave definitions: Array of wave dictionaries.
## Each wave: { "enemies": [{"type": StringName, "count": int, "position": Vector3}] }
var _waves: Array[Dictionary] = []

## Current wave index.
var _current_wave: int = 0

## Tracking alive enemies by instance ID.
var _alive_enemies: Dictionary = {}

## Whether waves are actively running.
var _active: bool = false


## Load wave definitions for an encounter.
func load_waves(waves: Array[Dictionary]) -> void:
	_waves = waves
	_current_wave = 0
	_alive_enemies.clear()
	_active = false


## Start the first wave.
func start() -> void:
	if _waves.is_empty():
		push_warning("WaveSystem: No waves loaded")
		return
	_active = true
	_spawn_current_wave()


## Register an enemy as alive (called by spawn system).
func register_enemy(enemy: Node) -> void:
	var id: int = enemy.get_instance_id()
	_alive_enemies[id] = enemy


## Notify that an enemy has died.
func on_enemy_died(enemy: Node) -> void:
	var id: int = enemy.get_instance_id()
	if id in _alive_enemies:
		_alive_enemies.erase(id)
	_check_wave_clear()


## Get count of alive enemies.
func get_alive_count() -> int:
	# Clean invalid references.
	var to_remove: Array[int] = []
	for id: int in _alive_enemies:
		if not is_instance_valid(_alive_enemies[id]):
			to_remove.append(id)
	for id: int in to_remove:
		_alive_enemies.erase(id)
	return _alive_enemies.size()


## Check if all waves are complete.
func is_complete() -> bool:
	return _current_wave >= _waves.size() and _alive_enemies.is_empty()


func _spawn_current_wave() -> void:
	if _current_wave >= _waves.size():
		return
	var wave_def: Dictionary = _waves[_current_wave]
	wave_started.emit(_current_wave)
	EventBus.log_event(&"wave_started", {"wave": _current_wave})
	# Enemies are spawned by the spawn service reading the wave definition.
	# This system just tracks them.


func _check_wave_clear() -> void:
	if not _active:
		return
	if get_alive_count() > 0:
		return
	wave_cleared.emit(_current_wave)
	EventBus.dungeon_room_cleared.emit(_current_wave)
	EventBus.log_event(&"wave_cleared", {"wave": _current_wave})
	_current_wave += 1
	if _current_wave >= _waves.size():
		_active = false
		all_waves_cleared.emit()
		EventBus.enemy_wave_cleared.emit()
	else:
		_spawn_current_wave()
