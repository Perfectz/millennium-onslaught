## Dungeon run orchestrator — loads rooms, manages transitions, coordinates systems.
## Creates WaveSystem, DungeonManager, HUD, and juice systems. Loads rooms dynamically.
extends Node3D


const EnemyScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const VictoryScene := preload("res://scenes/ui/victory_screen.tscn")
const DefeatScene := preload("res://scenes/ui/defeat_screen.tscn")
const DungeonData := preload("res://resources/dungeons/dungeon_1.tres")

@onready var player: PlayerController = $Player
@onready var camera: CameraFollow = $Camera3D
@onready var fade_rect: ColorRect = $FadeOverlay/FadeRect

var _dungeon_manager: DungeonManager
var _wave_system: WaveSystem
var _current_room: Node3D = null
var _hud: Node = null
var _transitioning: bool = false


func _ready() -> void:
	# Log connected controllers for debugging.
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		print("[Input] No controllers detected. Use keyboard: WASD move, J attack, K heavy, L dodge, Space jump")
	else:
		for joypad_id in joypads:
			print("[Input] Controller %d: %s (GUID: %s)" % [joypad_id, Input.get_joy_name(joypad_id), Input.get_joy_guid(joypad_id)])

	_setup_juice_systems()
	_setup_hud()
	_setup_wave_system()
	_setup_dungeon_manager()

	EventBus.dungeon_room_cleared.connect(_on_room_cleared)
	EventBus.dungeon_completed.connect(_on_dungeon_completed)
	EventBus.dungeon_failed.connect(_on_dungeon_failed)

	# Load first room and start dungeon.
	_load_room(0)
	_dungeon_manager.start_dungeon(DungeonData, _wave_system)


func _setup_juice_systems() -> void:
	var hitstop := HitstopSystem.new()
	hitstop.name = "HitstopSystem"
	add_child(hitstop)

	var shake := CameraShakeSystem.new()
	shake.name = "CameraShakeSystem"
	shake.camera = camera
	add_child(shake)

	var vfx := VFXSystem.new()
	vfx.name = "VFXSystem"
	add_child(vfx)


func _setup_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _setup_wave_system() -> void:
	_wave_system = WaveSystem.new()
	_wave_system.name = "WaveSystem"
	_wave_system.player = player
	_wave_system.enemy_container = self
	add_child(_wave_system)


func _setup_dungeon_manager() -> void:
	_dungeon_manager = DungeonManager.new()
	_dungeon_manager.name = "DungeonManager"
	add_child(_dungeon_manager)


func _load_room(index: int) -> void:
	# Clean up enemies from previous room.
	if _wave_system:
		_wave_system.clear_all_enemies()

	if _current_room:
		_current_room.queue_free()
		_current_room = null

	var dungeon_def := DungeonData as DungeonDef
	if index >= dungeon_def.room_scenes.size():
		return

	var room_path := dungeon_def.room_scenes[index]
	var room_scene := load(room_path) as PackedScene
	if room_scene == null:
		push_error("DungeonRun: Failed to load room scene: " + room_path)
		return

	_current_room = room_scene.instantiate()
	add_child(_current_room)

	# Position player at room spawn point.
	var spawn := _current_room.get_node_or_null("SpawnPoints/PlayerSpawn") as Node3D
	if spawn:
		player.global_position = spawn.global_position
	player.velocity = Vector3.ZERO

	# Set wave system spawn points from room markers.
	var left := _current_room.get_node_or_null("SpawnPoints/EnemySpawnLeft") as Node3D
	var right := _current_room.get_node_or_null("SpawnPoints/EnemySpawnRight") as Node3D
	if left:
		_wave_system.spawn_left = left.global_position
	if right:
		_wave_system.spawn_right = right.global_position


func _on_room_cleared(_room_index: int) -> void:
	if _transitioning:
		return
	if not _dungeon_manager.is_active():
		return
	_do_room_transition()


func _do_room_transition() -> void:
	_transitioning = true
	var half_time := Constants.DUNGEON_ROOM_TRANSITION_TIME * 0.5

	# Fade out.
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, half_time)
	await tween.finished

	# Load next room and advance dungeon.
	var next_index := _dungeon_manager.get_current_room_index() + 1
	_load_room(next_index)
	_dungeon_manager.advance_to_next_room()

	# Fade in.
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, half_time)
	await tween.finished

	_transitioning = false


func _on_dungeon_completed(_dungeon_id: StringName) -> void:
	get_tree().paused = true
	var screen := VictoryScene.instantiate()
	add_child(screen)
	screen.display_stats(_dungeon_manager.get_score_tracker())
	screen.continue_pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/dungeon/rooms/test_arena.tscn")
	)


func _on_dungeon_failed() -> void:
	# Delay before showing defeat screen.
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = true
	var screen := DefeatScene.instantiate()
	add_child(screen)
	screen.retry_pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/dungeon/dungeon_run.tscn")
	)


func _process(_delta: float) -> void:
	_check_kill_plane()
	_update_debug_label()

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _check_kill_plane() -> void:
	if player.position.y < -10.0:
		var spawn: Node3D = null
		if _current_room:
			spawn = _current_room.get_node_or_null("SpawnPoints/PlayerSpawn") as Node3D
		if spawn:
			player.position = spawn.global_position
		else:
			player.position = Vector3(0, 0.1, 0)
		player.velocity = Vector3.ZERO
		player.collision_layer = Constants.LAYER_PLAYER
		player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM


func _update_debug_label() -> void:
	if not player or not player.state_machine:
		return

	var room_idx := _dungeon_manager.get_current_room_index() if _dungeon_manager else 0
	var info := "Room: %d | State: %s | FPS: %d" % [
		room_idx + 1,
		str(player.state_machine.current_state_name),
		Engine.get_frames_per_second()
	]
	info += "\nPos: (%.1f, %.1f, %.1f) | Vel: (%.1f, %.1f)" % [
		player.position.x, player.position.y, player.position.z,
		player.velocity.x, player.velocity.y
	]
	info += "\n[ESC] Quit"
	if _hud and _hud.has_method("update_state_info"):
		_hud.update_state_info(info)
