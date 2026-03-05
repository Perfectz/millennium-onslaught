## Stage runner — orchestrates continuous belt-scroller stage flow.
## Loads chunks, places encounter triggers, coordinates WaveSystem, manages forward bounds.
## Replaces room-based loading when a DungeonDef has a stage_def assigned.
class_name StageRunner
extends Node


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


## Initialize the stage runner with all required references.
func setup(stage_def: StageDef, player: Node3D, wave_system: WaveSystem,
		enemy_scene: PackedScene, enemy_container: Node) -> void:
	_stage_def = stage_def
	_player = player
	_wave_system = wave_system
	_enemy_scene = enemy_scene
	_enemy_container = enemy_container

	# Set GameState stage mode.
	GameState.stage_mode = true
	GameState.current_stage_id = stage_def.stage_id
	GameState.stage_encounters_completed = 0
	GameState.stage_total_encounters = stage_def.get_encounter_count()

	# Validate stage data.
	var errors := stage_def.validate()
	if not errors.is_empty():
		for err in errors:
			push_warning("StageRunner: %s" % err)

	# Build the stage.
	_load_all_chunks()
	_place_encounter_triggers()
	_pre_spawn_all_encounters()
	_add_video_background()

	# Position player at start.
	_player.global_position = Vector3(2.0, 0.1, 0.0)
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
	for i in _stage_def.chunk_scenes.size():
		var path := _stage_def.chunk_scenes[i]
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("StageRunner: Failed to load chunk scene: %s" % path)
			continue
		var chunk := scene.instantiate() as Node3D
		chunk.position.x = float(i) * _stage_def.chunk_width
		chunk.name = "Chunk_%d" % i
		add_child(chunk)
		_chunks.append(chunk)


## Create EncounterTrigger Area3D nodes at each encounter position.
func _place_encounter_triggers() -> void:
	for i in _stage_def.encounters.size():
		var entry := _stage_def.encounters[i]
		var trigger := EncounterTrigger.new()
		trigger.trigger_index = i
		trigger.name = "EncounterTrigger_%d" % i
		add_child(trigger)
		trigger.setup_shape(entry.trigger_x)
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
		var half_belt := _stage_def.belt_depth * 0.5
		min_z = maxf(min_z, -half_belt)
		max_z = minf(max_z, half_belt)

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
				enemy.global_position = Vector3(x_pos, 0.0, z_pos)

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
## DungeonManager handles stage_encounters_completed tracking — StageRunner
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
	var min_z := -8.0
	var max_z := 8.0

	var half_depth: float = _stage_def.belt_depth * 0.5
	min_z = -half_depth
	max_z = half_depth

	if _encounters_completed < _stage_def.encounters.size():
		# Player can walk up to next encounter trigger + buffer.
		var next_entry := _stage_def.encounters[_encounters_completed]
		max_x = next_entry.trigger_x + Constants.STAGE_FORWARD_BUFFER
	else:
		# All encounters cleared — full stage freedom.
		max_x = _stage_def.get_total_width()

	GameState.set_room_bounds(min_x, max_x, min_z, max_z)
	EventBus.stage_bounds_updated.emit(min_x, max_x, min_z, max_z)


## Stage completed — all encounters cleared, player reached the end.
func _complete_stage() -> void:
	_stage_complete = true
	EventBus.stage_completed.emit(_stage_def.stage_id)


## Add the animated video background (CanvasLayer behind everything).
func _add_video_background() -> void:
	var bg_path := "res://assets/textures/dreamy_background.ogv"
	var stream := load(bg_path) as VideoStream
	if stream == null:
		push_warning("StageRunner: Video background not found: %s" % bg_path)
		return

	var canvas := CanvasLayer.new()
	canvas.layer = -1
	canvas.name = "BackgroundLayer"
	add_child(canvas)

	var player := VideoStreamPlayer.new()
	player.name = "VideoBackground"
	player.stream = stream
	player.autoplay = true
	player.loop = true
	player.expand = true
	player.volume_db = -80.0
	player.anchors_preset = 15
	player.anchor_right = 1.0
	player.anchor_bottom = 1.0
	player.grow_horizontal = Control.GROW_DIRECTION_BOTH
	player.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas.add_child(player)


## Clean up all chunks, triggers, and pre-spawned enemies.
func cleanup() -> void:
	if EventBus.enemy_wave_cleared.is_connected(_on_wave_cleared):
		EventBus.enemy_wave_cleared.disconnect(_on_wave_cleared)
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
