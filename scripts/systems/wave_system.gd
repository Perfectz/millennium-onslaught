## Wave system — spawns enemy waves from encounter data, arena-locks camera.
## Listens to enemy_died to track wave completion. Emits enemy_wave_cleared.
class_name WaveSystem
extends Node


## The encounter definition driving this wave system.
var _encounter: EncounterDef = null
var _current_wave_index: int = 0
var _enemies_alive: int = 0
var _is_active: bool = false
var _spawn_delay_timer: float = 0.0
var _waiting_for_spawn: bool = false

## Reference to the player for targeting enemies.
var player: Node3D = null

## Spawn positions (set by room).
var spawn_left: Vector3 = Vector3(-8, 1, 0)
var spawn_right: Vector3 = Vector3(8, 1, 0)

## Enemy scene to instantiate.
var enemy_scene: PackedScene = null

## Container node for spawned enemies (set by dungeon_run).
var enemy_container: Node = null

## Track all spawned enemies for cleanup.
var _spawned_enemies: Array[Node] = []


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _process(delta: float) -> void:
	if not _is_active:
		return
	if _waiting_for_spawn:
		_spawn_delay_timer -= delta
		if _spawn_delay_timer <= 0.0:
			_waiting_for_spawn = false
			_spawn_current_wave()


## Start an encounter from an EncounterDef.
func start_encounter(encounter: EncounterDef, enemy_packed_scene: PackedScene) -> void:
	_encounter = encounter
	enemy_scene = enemy_packed_scene
	_current_wave_index = 0
	_is_active = true
	GameState.encounter_active = true

	if _encounter.arena_lock:
		GameState.arena_lock_min_x = _encounter.arena_min_x
		GameState.arena_lock_max_x = _encounter.arena_max_x
		EventBus.encounter_arena_locked.emit(_encounter.arena_min_x, _encounter.arena_max_x)

	if _encounter.waves.is_empty():
		_finish_encounter()
		return

	_begin_wave()


## Begin the current wave.
func _begin_wave() -> void:
	if _current_wave_index >= _encounter.waves.size():
		_finish_encounter()
		return

	var wave := _encounter.waves[_current_wave_index]
	_spawn_delay_timer = wave.delay_before_spawn
	_waiting_for_spawn = true


## Spawn all enemies in the current wave.
func _spawn_current_wave() -> void:
	var wave := _encounter.waves[_current_wave_index]
	_enemies_alive = 0

	for entry in wave.spawn_entries:
		_spawn_entry(entry)

	GameState.encounter_enemies_alive = _enemies_alive


## Spawn enemies from a single SpawnEntry.
func _spawn_entry(entry: SpawnEntry) -> void:
	if entry.enemy_def == null:
		return
	for i in entry.count:
		var enemy := enemy_scene.instantiate() as EnemyController
		var parent: Node = enemy_container if enemy_container else get_tree().root
		parent.add_child(enemy)
		_spawned_enemies.append(enemy)

		# Configure from definition.
		enemy.configure(entry.enemy_def, player)

		# Position based on spawn side.
		match entry.spawn_side:
			&"left":
				enemy.global_position = spawn_left + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.5, 0.5))
			&"right":
				enemy.global_position = spawn_right + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.5, 0.5))
			_:  # "both" — alternate
				if i % 2 == 0:
					enemy.global_position = spawn_left + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.5, 0.5))
				else:
					enemy.global_position = spawn_right + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.5, 0.5))

		_enemies_alive += 1


func _on_enemy_died(_enemy: Node, _enemy_type: StringName, _position: Vector3) -> void:
	if not _is_active:
		return
	_enemies_alive -= 1
	GameState.encounter_enemies_alive = _enemies_alive
	if _enemies_alive <= 0:
		_advance_wave()


## Advance to the next wave or finish the encounter.
func _advance_wave() -> void:
	_current_wave_index += 1
	if _current_wave_index >= _encounter.waves.size():
		_finish_encounter()
	else:
		_begin_wave()


## Encounter complete — release arena lock.
func _finish_encounter() -> void:
	_is_active = false
	GameState.encounter_active = false
	GameState.encounter_enemies_alive = 0

	if _encounter and _encounter.arena_lock:
		GameState.arena_lock_min_x = -100.0
		GameState.arena_lock_max_x = 100.0
		EventBus.encounter_arena_unlocked.emit()

	EventBus.enemy_wave_cleared.emit()


## Clean up all spawned enemies (call on room transition or restart).
func clear_all_enemies() -> void:
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			enemy.queue_free()
	_spawned_enemies.clear()
	_enemies_alive = 0
	_is_active = false
	GameState.encounter_active = false
	GameState.encounter_enemies_alive = 0


## Check if an encounter is currently active.
func is_active() -> bool:
	return _is_active


## Get remaining enemies in current wave.
func get_enemies_alive() -> int:
	return _enemies_alive
