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


## Called when a player enters an encounter trigger zone.
func _on_encounter_triggered(trigger_index: int) -> void:
	if _current_encounter_index >= 0:
		# Already in an encounter — ignore overlapping triggers.
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

	# Set spawn points relative to arena edges.
	_wave_system.spawn_left = Vector3(
		enc.arena_min_x - Constants.STAGE_SPAWN_OFFSET_X, 1.0, 0.0)
	_wave_system.spawn_right = Vector3(
		enc.arena_max_x + Constants.STAGE_SPAWN_OFFSET_X, 1.0, 0.0)

	# Start the encounter.
	_wave_system.start_encounter(enc, _enemy_scene)

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

	if _encounters_completed < _stage_def.encounters.size():
		# Player can walk up to next encounter trigger + buffer.
		var next_entry := _stage_def.encounters[_encounters_completed]
		max_x = next_entry.trigger_x + Constants.STAGE_FORWARD_BUFFER
	else:
		# All encounters cleared — full stage freedom.
		max_x = _stage_def.get_total_width()

	GameState.set_room_bounds(min_x, max_x)
	EventBus.stage_bounds_updated.emit(min_x, max_x)


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


## Clean up all chunks and triggers.
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


func _exit_tree() -> void:
	cleanup()
