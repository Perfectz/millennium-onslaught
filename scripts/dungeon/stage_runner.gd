## Stage runner - orchestrates continuous belt-scroller stage flow.
## Loads chunks, places encounter triggers, coordinates WaveSystem, manages forward bounds.
## Replaces room-based loading when a DungeonDef has a stage_def assigned.
class_name StageRunner
extends Node3D

const SpawnPositionResolverScript := preload("res://scripts/systems/spawn_position_resolver.gd")
const PLAYER_STAGE_SPAWN := Vector3(2.0, 0.1, 0.0)
const PLAYER_STAGE_SPAWN_RADIUS := 0.45
const ENEMY_STAGE_SPAWN_RADIUS := 0.35

var _stage_def: StageDef = null
var _wave_system: WaveSystem = null
var _player: Node3D = null
var _enemy_scene: PackedScene = null
var _enemy_container: Node = null

## Loaded chunk scene instances.
var _chunks: Array[Node3D] = []

## Encounter trigger Area3D nodes.
var _triggers: Array[EncounterTrigger] = []

## Index of the currently active encounter (-1 = none).
var _current_encounter_index: int = -1

## Pre-spawned enemies indexed by encounter index.
var _pre_spawned_enemies: Dictionary = {}

## How many encounters have been completed.
var _encounters_completed: int = 0

## Whether the stage is finished (all encounters cleared).
var _stage_complete: bool = false
var _stage_exit_area: Area3D = null
var _stage_exit_triggered: bool = false
var _stage_min_z: float = -5.0
var _stage_max_z: float = 5.0
var _stage_max_x: float = 0.0


func _physics_process(_delta: float) -> void:
	if _stage_complete and not _stage_exit_triggered and _stage_exit_area != null:
		_try_consume_stage_exit()


## Initialize the stage runner with all required references.
func setup(stage_def: StageDef, player: Node3D, wave_system: WaveSystem,
		enemy_scene: PackedScene, enemy_container: Node) -> void:
	_stage_def = stage_def
	_player = player
	_wave_system = wave_system
	_enemy_scene = enemy_scene
	_enemy_container = enemy_container

	# Set RuntimeState stage mode.
	RuntimeState.stage_mode = true
	RuntimeState.current_stage_id = stage_def.stage_id

	# Validate stage data.
	var errors := stage_def.validate()
	if not errors.is_empty():
		for err in errors:
			push_warning("StageRunner: %s" % err)

	# Build the stage.
	_load_all_chunks()
	_recalculate_stage_bounds()
	_find_stage_exit()
	_place_encounter_triggers()
	_pre_spawn_all_encounters()

	# Position player at start.
	_player.global_position = get_safe_respawn_position(PLAYER_STAGE_SPAWN)
	_player.velocity = Vector3.ZERO

	# Set initial forward bounds.
	_update_forward_bounds()

	# Listen for wave clear.
	EventBus.enemy_wave_cleared.connect(_on_wave_cleared)

	# Play stage-specific music.
	if _stage_def.music_track != &"":
		EventBus.audio_music_requested.emit(_stage_def.music_track, true)


## Load all chunk scenes and tile them along the X axis.
func _load_all_chunks() -> void:
	var total_chunks := _stage_def.chunk_scenes.size()
	for i in _stage_def.chunk_scenes.size():
		var path := _stage_def.chunk_scenes[i]
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("StageRunner: Failed to load chunk scene: %s" % path)
			continue
		var chunk := scene.instantiate() as Node3D
		chunk.position.x = float(i) * _stage_def.chunk_width
		chunk.name = "Chunk_%d" % i
		_strip_fullscreen_background(chunk)
		_configure_chunk_connections(chunk, i, total_chunks)
		add_child(chunk)
		_chunks.append(chunk)


func _configure_chunk_connections(chunk: Node3D, chunk_index: int, total_chunks: int) -> void:
	if chunk == null:
		return
	var open_west := chunk_index > 0
	var open_east := chunk_index < total_chunks - 1
	if open_west:
		_remove_chunk_nodes(chunk, ["WestBoundary"])
		_remove_visual_wall_side(chunk, "westwall")
	if open_east:
		_remove_chunk_nodes(chunk, ["EastBoundary", "EastBoundaryNorth", "EastBoundarySouth"])
		_remove_visual_wall_side(chunk, "eastwall")


func _remove_chunk_nodes(chunk: Node3D, node_names: Array[String]) -> void:
	for node_name in node_names:
		var node := chunk.get_node_or_null(node_name)
		if node != null:
			node.free()


func _remove_visual_wall_side(chunk: Node3D, side_prefix: String) -> void:
	var visuals := chunk.get_node_or_null("Visuals") as Node3D
	if visuals == null:
		return
	var to_remove: Array[Node] = []
	for child in visuals.get_children():
		var child_name := String(child.name).to_lower()
		if child_name.begins_with(side_prefix):
			to_remove.append(child)
	for child in to_remove:
		child.free()


func _recalculate_stage_bounds() -> void:
	_stage_min_z = INF
	_stage_max_z = -INF
	_stage_max_x = 0.0
	for chunk in _chunks:
		var floor_shape := chunk.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
		if floor_shape == null:
			floor_shape = chunk.find_child("CollisionShape3D", true, false) as CollisionShape3D
		if floor_shape == null:
			continue
		var box := floor_shape.shape as BoxShape3D
		if box == null:
			continue
		var scale := floor_shape.global_transform.basis.get_scale()
		var half_x := box.size.x * absf(scale.x) * 0.5
		var half_z := box.size.z * absf(scale.z) * 0.5
		var center := floor_shape.global_position
		_stage_max_x = maxf(_stage_max_x, center.x + half_x)
		_stage_min_z = minf(_stage_min_z, center.z - half_z)
		_stage_max_z = maxf(_stage_max_z, center.z + half_z)
	if not is_finite(_stage_min_z) or not is_finite(_stage_max_z) or _stage_min_z >= _stage_max_z:
		var half_depth := maxf(_stage_def.belt_depth * 0.5, 8.0)
		_stage_min_z = -half_depth
		_stage_max_z = half_depth
	if _stage_max_x <= 0.0:
		_stage_max_x = _stage_def.get_total_width()


func _find_stage_exit() -> void:
	_stage_exit_area = null
	_stage_exit_triggered = false
	for chunk in _chunks:
		if chunk == null:
			continue
		var exit_area := chunk.get_node_or_null("StageExitArea") as Area3D
		if exit_area == null:
			exit_area = chunk.find_child("StageExitArea", true, false) as Area3D
		if exit_area != null:
			_stage_exit_area = exit_area
			if not _stage_exit_area.body_entered.is_connected(_on_stage_exit_body_entered):
				_stage_exit_area.body_entered.connect(_on_stage_exit_body_entered)
			return


## Create EncounterTrigger Area3D nodes at each encounter position.
func _place_encounter_triggers() -> void:
	var trigger_depth := maxf(_stage_max_z - _stage_min_z, Constants.STAGE_TRIGGER_BOX_DEPTH)
	for i in _stage_def.encounters.size():
		var entry := _stage_def.encounters[i]
		var trigger := EncounterTrigger.new()
		trigger.trigger_index = i
		trigger.name = "EncounterTrigger_%d" % i
		add_child(trigger)
		trigger.setup_shape(entry.trigger_x, trigger_depth)
		trigger.triggered.connect(_on_encounter_triggered)
		_triggers.append(trigger)


## Pre-spawn all enemies for every encounter at stage load time.
## Enemies are placed in dormant state at their grid positions.
func _pre_spawn_all_encounters() -> void:
	for enc_idx in _stage_def.encounters.size():
		var entry := _stage_def.encounters[enc_idx]
		var enc := entry.encounter_def.duplicate() as EncounterDef
		enc.arena_min_x = entry.trigger_x - entry.arena_half_width
		enc.arena_max_x = entry.trigger_x + entry.arena_half_width
		enc.arena_min_z = entry.arena_min_z
		enc.arena_max_z = entry.arena_max_z

		# Collect all spawn entries from all waves.
		var all_entries: Array[SpawnEntry] = []
		for wave in enc.waves:
			for spawn_entry in wave.spawn_entries:
				all_entries.append(spawn_entry)

		var total_enemies: int = 0
		for spawn_entry in all_entries:
			if spawn_entry.enemy_def != null:
				total_enemies += spawn_entry.count

		# Compute placement bounds (pad inward from edges).
		var pad := Constants.STAGE_SPAWN_PADDING
		var min_x := enc.arena_min_x + pad
		var max_x := enc.arena_max_x - pad
		var min_z := enc.arena_min_z + pad * 0.5
		var max_z := enc.arena_max_z - pad * 0.5

		# Cap spawn Z by belt_depth to keep enemies in visible corridor.
		min_z = maxf(min_z, _stage_min_z + pad * 0.25)
		max_z = minf(max_z, _stage_max_z - pad * 0.25)

		var enemies: Array = []
		var spawn_index: int = 0
		for spawn_entry in all_entries:
			if spawn_entry.enemy_def == null:
				continue
			for i in spawn_entry.count:
				var enemy := _enemy_scene.instantiate() as EnemyController
				_enemy_container.add_child(enemy)
				enemy.configure(spawn_entry.enemy_def, _player, true)

				var t_x: float = float(spawn_index) / maxf(total_enemies - 1, 1)
				var z_row: float = float(spawn_index % 3) / 2.0
				var x_pos := lerpf(min_x, max_x, t_x)
				var z_pos := lerpf(min_z, max_z, z_row)
				enemy.global_position = _resolve_stage_spawn_position(
					Vector3(x_pos, 0.0, z_pos),
					min_x,
					max_x,
					min_z,
					max_z,
					ENEMY_STAGE_SPAWN_RADIUS
				)

				enemies.append(enemy)
				spawn_index += 1

		_pre_spawned_enemies[enc_idx] = enemies


## Called when a player enters an encounter trigger zone.
func _on_encounter_triggered(trigger_index: int) -> void:
	if _current_encounter_index >= 0:
		return
	if trigger_index < 0 or trigger_index >= _stage_def.encounters.size():
		push_error("StageRunner: Invalid trigger index %d" % trigger_index)
		return

	_current_encounter_index = trigger_index
	var entry := _stage_def.encounters[trigger_index]

	# Duplicate EncounterDef to avoid mutating shared resource.
	var enc := entry.encounter_def.duplicate() as EncounterDef
	enc.arena_lock = true
	enc.arena_min_x = entry.trigger_x - entry.arena_half_width
	enc.arena_max_x = entry.trigger_x + entry.arena_half_width
	enc.arena_min_z = entry.arena_min_z
	enc.arena_max_z = entry.arena_max_z

	# Start encounter with pre-spawned enemies (no new spawning).
	var enemies: Array = _pre_spawned_enemies.get(trigger_index, [])
	_wave_system.start_encounter_prescreened(enc, enemies)

	# Encounter start juice.
	JuiceManager.screen_flash(Color(1.0, 0.85, 0.4, 0.18), 0.1)
	ToastSystem.show_toast("ENCOUNTER!", Color(1.0, 0.9, 0.5))


## Called when all waves in the current encounter are cleared.
## DungeonManager handles stage_encounters_completed tracking - StageRunner
## only updates forward bounds and local state.
func _on_wave_cleared() -> void:
	if _current_encounter_index < 0:
		return

	_encounters_completed += 1
	_current_encounter_index = -1

	# Encounter clear juice.
	JuiceManager.screen_flash(Color(0.4, 1.0, 0.6, 0.15), 0.12)
	ToastSystem.show_toast("CLEAR!", Color(0.5, 1.0, 0.7))

	# Expand forward bounds so player can walk to next encounter.
	_update_forward_bounds()

	# Check if all encounters are done.
	if _encounters_completed >= _stage_def.get_encounter_count():
		_complete_stage()


## Update room bounds to allow forward progress up to the next encounter.
func _update_forward_bounds() -> void:
	var min_x := 0.0
	var max_x: float
	var min_z := _stage_min_z
	var max_z := _stage_max_z

	if _encounters_completed < _stage_def.encounters.size():
		# Player can walk up to next encounter trigger + buffer.
		var next_entry := _stage_def.encounters[_encounters_completed]
		max_x = next_entry.trigger_x + Constants.STAGE_FORWARD_BUFFER
	else:
		# All encounters cleared - full stage freedom.
		max_x = _stage_max_x

	RuntimeState.set_room_bounds(min_x, max_x, min_z, max_z)
	EventBus.stage_bounds_updated.emit(min_x, max_x, min_z, max_z)


## Stage completed - all encounters cleared, player reached the end.
func _complete_stage() -> void:
	_stage_complete = true
	if _stage_exit_area != null:
		ToastSystem.show_toast("EXIT OPEN - FOLLOW THE STAIRS", Color(0.9, 0.85, 0.55))
		_try_consume_stage_exit()
	else:
		EventBus.stage_completed.emit(_stage_def.stage_id)


func _on_stage_exit_body_entered(body: Node) -> void:
	if body != _player:
		return
	_try_consume_stage_exit(true)


func _try_consume_stage_exit(force: bool = false) -> void:
	if not _stage_complete or _stage_exit_triggered:
		return
	if _stage_exit_area == null:
		return
	if not force:
		var overlapping := _stage_exit_area.get_overlapping_bodies()
		if _player not in overlapping:
			return
	_stage_exit_triggered = true
	EventBus.stage_completed.emit(_stage_def.stage_id)


func get_stage_def() -> StageDef:
	return _stage_def


func get_debug_snapshot() -> Dictionary:
	return {
		"stage_id": _stage_def.stage_id if _stage_def != null else &"",
		"chunk_count": _chunks.size(),
		"trigger_count": _triggers.size(),
		"encounters_completed": _encounters_completed,
		"total_encounters": _stage_def.get_encounter_count() if _stage_def != null else 0,
		"current_encounter_index": _current_encounter_index,
		"stage_complete": _stage_complete,
		"stage_exit_present": _stage_exit_area != null,
		"stage_exit_triggered": _stage_exit_triggered,
		"bounds": {
			"max_x": _stage_max_x,
			"min_z": _stage_min_z,
			"max_z": _stage_max_z,
		},
	}


func get_safe_respawn_position(preferred_position: Vector3 = PLAYER_STAGE_SPAWN) -> Vector3:
	return _resolve_stage_spawn_position(
		preferred_position,
		0.0,
		_stage_max_x,
		_stage_min_z,
		_stage_max_z,
		PLAYER_STAGE_SPAWN_RADIUS
	)


func _resolve_stage_spawn_position(
		preferred_position: Vector3,
		min_x: float,
		max_x: float,
		min_z: float,
		max_z: float,
		radius: float
	) -> Vector3:
	return SpawnPositionResolverScript.resolve_position(
		get_world_3d(),
		preferred_position,
		min_x,
		max_x,
		min_z,
		max_z,
		radius
	)


func _strip_fullscreen_background(root: Node) -> void:
	if root == null:
		return
	var background := root.get_node_or_null("BackgroundLayer")
	if background != null:
		background.queue_free()

## Clean up all chunks, triggers, and pre-spawned enemies.
func cleanup() -> void:
	if EventBus.enemy_wave_cleared.is_connected(_on_wave_cleared):
		EventBus.enemy_wave_cleared.disconnect(_on_wave_cleared)
	if _stage_exit_area != null and _stage_exit_area.body_entered.is_connected(_on_stage_exit_body_entered):
		_stage_exit_area.body_entered.disconnect(_on_stage_exit_body_entered)
	_stage_exit_area = null
	for trigger in _triggers:
		if is_instance_valid(trigger):
			trigger.queue_free()
	_triggers.clear()
	for chunk in _chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	_chunks.clear()
	# Free any pre-spawned enemies that were never activated.
	for enc_idx in _pre_spawned_enemies:
		var enemies: Array = _pre_spawned_enemies[enc_idx]
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_inside_tree():
				enemy.queue_free()
	_pre_spawned_enemies.clear()


func _exit_tree() -> void:
	cleanup()
