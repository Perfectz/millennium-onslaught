## Wave system — spawns enemy waves from encounter data, arena-locks camera.
## Listens to enemy_died to track wave completion. Emits enemy_wave_cleared.
class_name WaveSystem
extends Node

const SpawnPositionResolverScript := preload("res://scripts/systems/spawn_position_resolver.gd")
const ENEMY_SPAWN_RADIUS := 0.35
const ENCOUNTER_HEALTH_CHECK_INTERVAL := 0.6


## The encounter definition driving this wave system.
var _encounter: EncounterDef = null
var _current_wave_index: int = 0
var _enemies_alive: int = 0
var _is_active: bool = false
var _spawn_delay_timer: float = 0.0
var _waiting_for_spawn: bool = false
var _between_wave_breather_timer: float = 0.0

## Reference to the player for targeting enemies.
var player: Node3D = null

## Spawn positions (set by room or stage runner, 4 edges for isometric).
var spawn_left: Vector3 = Vector3(-8, 1, 0)
var spawn_right: Vector3 = Vector3(8, 1, 0)
var spawn_top: Vector3 = Vector3(0, 1, -8)
var spawn_bottom: Vector3 = Vector3(0, 1, 8)

## Enemy scene to instantiate.
var enemy_scene: PackedScene = null

## Container node for spawned enemies (set by dungeon_run).
var enemy_container: Node = null

## Track all spawned enemies for cleanup.
var _spawned_enemies: Array[Node] = []
var _health_check_timer: float = 0.0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _process(_delta: float) -> void:
	if not _is_active or _encounter == null:
		return
	_health_check_timer -= _delta
	if _health_check_timer > 0.0:
		return
	_health_check_timer = ENCOUNTER_HEALTH_CHECK_INTERVAL
	_run_encounter_health_check()


## Start an encounter from an EncounterDef.
## Pre-places all enemies at fixed positions within the arena in dormant mode.
func start_encounter(encounter: EncounterDef, enemy_packed_scene: PackedScene) -> void:
	_encounter = encounter
	enemy_scene = enemy_packed_scene
	_current_wave_index = 0
	_is_active = true
	_between_wave_breather_timer = 0.0
	_health_check_timer = ENCOUNTER_HEALTH_CHECK_INTERVAL
	RuntimeState.encounter_active = true

	if _encounter.arena_lock:
		RuntimeState.arena_lock_min_x = _encounter.arena_min_x
		RuntimeState.arena_lock_max_x = _encounter.arena_max_x
		RuntimeState.arena_lock_min_z = _encounter.arena_min_z
		RuntimeState.arena_lock_max_z = _encounter.arena_max_z
		EventBus.encounter_arena_locked.emit(_encounter.arena_min_x, _encounter.arena_max_x, _encounter.arena_min_z, _encounter.arena_max_z)

	if _encounter.waves.is_empty():
		_finish_encounter()
		return

	# Pre-place all enemies from all waves at fixed positions immediately.
	_spawn_all_waves_preplaced()


## Pre-place all enemies from every wave at fixed positions within the arena.
## Enemies start in dormant state and wake up when the player is nearby.
func _spawn_all_waves_preplaced() -> void:
	_enemies_alive = 0
	# Collect all spawn entries from all waves.
	var all_entries: Array[SpawnEntry] = []
	for wave in _encounter.waves:
		for entry in wave.spawn_entries:
			all_entries.append(entry)

	# Count total enemies for position distribution.
	var total_enemies: int = 0
	for entry in all_entries:
		if entry.enemy_def != null:
			total_enemies += entry.count

	# Compute arena bounds for placement (pad inward from edges).
	var pad := Constants.ENCOUNTER_SPAWN_PADDING
	var min_x := _encounter.arena_min_x + pad
	var max_x := _encounter.arena_max_x - pad
	var min_z := _encounter.arena_min_z + pad * 0.5
	var max_z := _encounter.arena_max_z - pad * 0.5

	var spawn_index: int = 0
	for entry in all_entries:
		if entry.enemy_def == null:
			continue
		for i in entry.count:
			var enemy := enemy_scene.instantiate() as EnemyController
			var parent: Node = enemy_container if enemy_container else get_tree().root
			parent.add_child(enemy)
			_spawned_enemies.append(enemy)

			# Configure in dormant mode — enemy stands idle until player approaches.
			enemy.configure(entry.enemy_def, player, true)

			# Distribute at fixed grid positions within the arena.
			var t_x: float = float(spawn_index) / maxf(total_enemies - 1, 1)
			var z_row: float = float(spawn_index % 3) / 2.0
			var x_pos := lerpf(min_x, max_x, t_x)
			var z_pos := lerpf(min_z, max_z, z_row)
			enemy.global_position = SpawnPositionResolverScript.resolve_position(
				_get_spawn_world(),
				Vector3(x_pos, 0.0, z_pos),
				min_x,
				max_x,
				min_z,
				max_z,
				ENEMY_SPAWN_RADIUS
			)

			_enemies_alive += 1
			spawn_index += 1

	# Mark the last wave as current so _advance_wave finishes the encounter.
	_current_wave_index = _encounter.waves.size() - 1
	RuntimeState.encounter_enemies_alive = _enemies_alive

	# Guard: if no valid enemies were spawned, finish immediately to avoid stall.
	if _enemies_alive <= 0:
		_finish_encounter()


func _on_enemy_died(enemy: Node, _enemy_type: StringName, _position: Vector3) -> void:
	if not _is_active or _encounter == null:
		return
	# Only decrement for enemies belonging to this encounter (prevents cross-encounter desync).
	if enemy not in _spawned_enemies:
		return
	_enemies_alive = maxi(0, _enemies_alive - 1)
	RuntimeState.encounter_enemies_alive = _enemies_alive
	if _enemies_alive <= 0:
		_advance_wave()


## Advance to the next wave or finish the encounter.
func _advance_wave() -> void:
	_current_wave_index += 1
	if _current_wave_index >= _encounter.waves.size():
		_finish_encounter()
	else:
		_between_wave_breather_timer = Constants.WAVE_BREATHER_DURATION
		ToastSystem.show_toast("WAVE CLEAR", Color(0.8, 0.95, 1.0))


## Encounter complete — release arena lock.
func _finish_encounter() -> void:
	_is_active = false
	RuntimeState.encounter_active = false
	RuntimeState.encounter_enemies_alive = 0
	_between_wave_breather_timer = 0.0
	_health_check_timer = 0.0

	if _encounter and _encounter.arena_lock:
		RuntimeState.clear_arena_bounds()
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
	_between_wave_breather_timer = 0.0
	_health_check_timer = 0.0
	RuntimeState.encounter_active = false
	RuntimeState.encounter_enemies_alive = 0


## Start an encounter using enemies that were already pre-spawned and placed.
## Does arena-lock + death tracking only (no instantiation).
func start_encounter_prescreened(encounter: EncounterDef, enemies: Array) -> void:
	_encounter = encounter
	_current_wave_index = 0
	_is_active = true
	_between_wave_breather_timer = 0.0
	_spawned_enemies.clear()
	_health_check_timer = ENCOUNTER_HEALTH_CHECK_INTERVAL
	RuntimeState.encounter_active = true

	if _encounter.arena_lock:
		RuntimeState.arena_lock_min_x = _encounter.arena_min_x
		RuntimeState.arena_lock_max_x = _encounter.arena_max_x
		RuntimeState.arena_lock_min_z = _encounter.arena_min_z
		RuntimeState.arena_lock_max_z = _encounter.arena_max_z
		EventBus.encounter_arena_locked.emit(
			_encounter.arena_min_x, _encounter.arena_max_x,
			_encounter.arena_min_z, _encounter.arena_max_z)

	if enemies.is_empty():
		_finish_encounter()
		return

	_enemies_alive = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.health.is_dead():
			_spawned_enemies.append(enemy)
			if enemy is EnemyController:
				(enemy as EnemyController).activate_for_encounter()
			_enemies_alive += 1

	_current_wave_index = _encounter.waves.size() - 1
	RuntimeState.encounter_enemies_alive = _enemies_alive

	if _enemies_alive <= 0:
		_finish_encounter()


## Check if an encounter is currently active.
func is_active() -> bool:
	return _is_active


## Get remaining enemies in current wave.
func get_enemies_alive() -> int:
	return _enemies_alive


func get_debug_snapshot() -> Dictionary:
	return {
		"active": _is_active,
		"encounter_id": _encounter.encounter_id if _encounter != null else &"",
		"current_wave_index": _current_wave_index,
		"enemies_alive": _enemies_alive,
		"tracked_enemy_count": _spawned_enemies.size(),
		"arena_lock": _encounter.arena_lock if _encounter != null else false,
		"arena_bounds": {
			"min_x": _encounter.arena_min_x if _encounter != null else 0.0,
			"max_x": _encounter.arena_max_x if _encounter != null else 0.0,
			"min_z": _encounter.arena_min_z if _encounter != null else 0.0,
			"max_z": _encounter.arena_max_z if _encounter != null else 0.0,
		},
	}


func _get_spawn_world() -> World3D:
	if player != null and is_instance_valid(player):
		return player.get_world_3d()
	if enemy_container is Node3D:
		return (enemy_container as Node3D).get_world_3d()
	return null


func _run_encounter_health_check() -> void:
	if _encounter == null:
		return
	var live_enemies: Array[Node] = []
	var recovered_count := 0
	var spawn_world := _get_spawn_world()
	for enemy in _spawned_enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if enemy is EnemyController:
			var controller := enemy as EnemyController
			if controller.health == null or controller.health.is_dead():
				continue
			if controller.state_machine != null and controller.state_machine.current_state_name == &"dormant":
				controller.activate_for_encounter()
				recovered_count += 1
			var safe_position := SpawnPositionResolverScript.resolve_position(
				spawn_world,
				controller.global_position,
				_encounter.arena_min_x,
				_encounter.arena_max_x,
				_encounter.arena_min_z,
				_encounter.arena_max_z,
				ENEMY_SPAWN_RADIUS
			)
			if safe_position.distance_squared_to(controller.global_position) > 0.01:
				controller.global_position = safe_position
				controller.velocity = Vector3.ZERO
				recovered_count += 1
		live_enemies.append(enemy)
	_spawned_enemies = live_enemies
	if _enemies_alive != _spawned_enemies.size():
		_enemies_alive = _spawned_enemies.size()
		RuntimeState.encounter_enemies_alive = _enemies_alive
	if recovered_count > 0:
		EventBus.log_event(&"encounter_enemy_recovered", {
			"encounter_id": _encounter.encounter_id,
			"count": recovered_count,
		})
	if _is_active and _enemies_alive <= 0:
		_finish_encounter()
