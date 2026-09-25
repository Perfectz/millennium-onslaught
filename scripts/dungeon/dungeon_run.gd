## Dungeon run orchestrator - loads rooms, manages transitions, coordinates systems.
## Creates WaveSystem, DungeonManager, HUD, and juice systems. Loads rooms dynamically.
extends Node3D


const EnemyScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const VictoryScene := preload("res://scenes/ui/victory_screen.tscn")
const DefeatScene := preload("res://scenes/ui/defeat_screen.tscn")
const DefaultDungeonData := preload("res://resources/dungeons/dungeon_1.tres")

## Registry mapping dungeon_id to resource path.
const DUNGEON_REGISTRY: Dictionary = {
	&"dungeon_1": "res://resources/dungeons/dungeon_1.tres",
	&"birth_valley": "res://resources/dungeons/birth_valley.tres",
}
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const SpawnPositionResolverScript := preload("res://scripts/systems/spawn_position_resolver.gd")
const RuntimeBoundsPolicyScript := preload("res://scripts/components/runtime_bounds_policy.gd")
const PLAYER_SPAWN_RADIUS := 0.45

@onready var player: PlayerController = $Player
@onready var camera: CameraFollow = $Camera3D
@onready var fade_rect: ColorRect = $FadeOverlay/FadeRect

var _dungeon_manager: DungeonManager
var _horde: HordeDirector
var _pickups: PickupField
var _wave_system: WaveSystem
var _stage_runner: StageRunner = null
var _current_room: Node3D = null
var _hud: Node = null
var _transitioning: bool = false
var _pause_menu: CanvasLayer = null
var _char_switch_cooldown: float = 0.0
var _stage_defs: Array[StageDef] = []
var _current_stage_index: int = 0
var _loading_panel: PanelContainer = null
var _loading_title: Label = null
var _loading_subtitle: Label = null


func _ready() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	# Start with black screen to cover loading.
	fade_rect.color = Color(0, 0, 0, 1)
	_setup_loading_message()

	# Log connected controllers for debugging.
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		print("[Input] No controllers detected. Use keyboard: WASD move, J attack, K heavy, L dodge, Space jump")
	else:
		for joypad_id in joypads:
			print("[Input] Controller %d: %s (GUID: %s)" % [joypad_id, Input.get_joy_name(joypad_id), Input.get_joy_guid(joypad_id)])

	_setup_juice_systems()
	_setup_horde()
	_setup_hud()
	_setup_wave_system()
	_setup_dungeon_manager()

	EventBus.dungeon_room_cleared.connect(_on_room_cleared)
	EventBus.dungeon_completed.connect(_on_dungeon_completed)
	EventBus.dungeon_failed.connect(_on_dungeon_failed)
	EventBus.enemy_died.connect(_on_enemy_died_xp)
	EventBus.rpg_level_up.connect(_on_level_up)

	# Resolve which dungeon to load.
	var dungeon_def := _resolve_dungeon_def()

	# Route: multi-stage vs single-stage vs room mode.
	if dungeon_def.stage_defs.size() > 0:
		_show_loading_message("DESCENDING", "Preparing floor 1")
		_start_multi_stage_mode(dungeon_def)
	elif dungeon_def.stage_def != null:
		_show_loading_message("ENTERING STAGE", "Building combat space")
		_start_stage_mode(dungeon_def)
	else:
		_show_loading_message("LOADING ROOM", "Preparing encounter")
		_start_room_mode(dungeon_def)

	# Fade in from loading screen after everything is set up.
	_fade_in_from_loading()


## Fade in from loading screen after stage setup completes.
func _fade_in_from_loading() -> void:
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(_loading_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	_loading_panel.visible = false


func _setup_loading_message() -> void:
	var overlay := fade_rect.get_parent() as CanvasLayer
	if overlay == null:
		return

	_loading_panel = PanelContainer.new()
	_loading_panel.name = "LoadingPanel"
	_loading_panel.visible = false
	_loading_panel.modulate = Color(1, 1, 1, 0)
	_loading_panel.set_anchors_preset(Control.PRESET_CENTER)
	_loading_panel.offset_left = -180
	_loading_panel.offset_top = -56
	_loading_panel.offset_right = 180
	_loading_panel.offset_bottom = 56
	_loading_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.05, 0.09, 0.9)
	panel_style.border_color = Color(0.38, 0.62, 0.95, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 6
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	_loading_panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(_loading_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_loading_panel.add_child(vbox)

	_loading_title = Label.new()
	_loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_title.add_theme_font_size_override("font_size", 24)
	_loading_title.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	vbox.add_child(_loading_title)

	_loading_subtitle = Label.new()
	_loading_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_subtitle.add_theme_font_size_override("font_size", 14)
	_loading_subtitle.add_theme_color_override("font_color", Color(0.58, 0.8, 1.0))
	vbox.add_child(_loading_subtitle)


func _show_loading_message(title: String, subtitle: String = "") -> void:
	if _loading_panel == null:
		return
	_loading_title.text = title
	_loading_subtitle.text = subtitle
	_loading_subtitle.visible = subtitle != ""
	_loading_panel.visible = true
	_loading_panel.modulate = Color(1, 1, 1, 1)


func _setup_juice_systems() -> void:
	var hitstop := HitstopSystem.new()
	hitstop.name = "HitstopSystem"
	add_child(hitstop)

	var vfx := VFXSystem.new()
	vfx.name = "VFXSystem"
	add_child(vfx)


## Pooled horde grunts (musou-density encounters) and item pickups.
func _setup_horde() -> void:
	_horde = HordeDirector.new()
	_horde.name = "HordeDirector"
	_horde.player = player
	add_child(_horde)
	_horde.grunt_defeated.connect(_on_grunt_defeated)
	_pickups = PickupField.new()
	_pickups.name = "PickupField"
	_pickups.player = player
	add_child(_pickups)
	EventBus.enemy_summon_requested.connect(_on_summon_requested)


func _on_grunt_defeated(grunt: HordeGrunt, _base_id: StringName, _attacker: Node3D) -> void:
	player.xp_tracker.add_xp(Constants.BATTLE_XP_PER_KO)
	if grunt.def and not grunt.def.drop_table.is_empty():
		for item_id in DropRoller.roll_drops(grunt.def.drop_table):
			_pickups.spawn(item_id, grunt.global_position)


func _on_summon_requested(_summoner: Node, unit: Resource, count: int, origin: Vector3) -> void:
	var horde_unit := unit as HordeUnitDef
	if horde_unit == null:
		return
	for i in count:
		var a := TAU * float(i) / float(maxi(count, 1))
		var grunt := _horde.spawn(horde_unit, origin + Vector3(cos(a), 0.0, sin(a)) * 2.0)
		if grunt:
			grunt.state = HordeGrunt.GruntState.ADVANCE


func _setup_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)
	var debug_overlay := DebugOverlay.new()
	debug_overlay.name = "DebugOverlay"
	add_child(debug_overlay)


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


var _active_dungeon_def: DungeonDef = null


## Start in continuous stage mode.
func _start_stage_mode(dungeon_def: DungeonDef) -> void:
	_active_dungeon_def = dungeon_def
	RuntimeState.stage_total_encounters = dungeon_def.stage_def.get_encounter_count()
	RuntimeState.stage_encounters_completed = 0
	RuntimeState.current_stage_index = 0
	RuntimeState.stage_floor_count = 1
	_stage_runner = StageRunner.new()
	_stage_runner.name = "StageRunner"
	_stage_runner.horde_director = _horde
	add_child(_stage_runner)
	_stage_runner.setup(
		dungeon_def.stage_def, player, _wave_system, EnemyScene, self)
	_restore_player_presentation()
	_snap_camera_to_player()
	_dungeon_manager.start_dungeon(dungeon_def, _wave_system)


## Start in multi-stage mode - multiple continuous stages played sequentially.
func _start_multi_stage_mode(dungeon_def: DungeonDef) -> void:
	_active_dungeon_def = dungeon_def
	_stage_defs = dungeon_def.stage_defs
	_current_stage_index = 0
	# Set total encounters across ALL stages.
	var total := 0
	for stage_def in _stage_defs:
		total += stage_def.get_encounter_count()
	RuntimeState.stage_total_encounters = total
	RuntimeState.stage_encounters_completed = 0
	RuntimeState.current_stage_index = 0
	RuntimeState.stage_floor_count = _stage_defs.size()
	# Listen for individual stage completions.
	EventBus.stage_completed.connect(_on_stage_completed)
	# Load first stage.
	_load_stage(0)
	call_deferred("_show_stage_floor_toast", 0)
	_dungeon_manager.start_dungeon(dungeon_def, _wave_system)


## Load a specific stage by index, cleaning up the previous one.
func _load_stage(index: int) -> void:
	# Clean up previous stage runner.
	if _stage_runner:
		_wave_system.clear_all_enemies()
		_horde.clear_all()
		_stage_runner.queue_free()
		_stage_runner = null
	_current_stage_index = index
	RuntimeState.current_stage_index = index
	_stage_runner = StageRunner.new()
	_stage_runner.name = "StageRunner"
	_stage_runner.horde_director = _horde
	add_child(_stage_runner)
	_stage_runner.setup(
		_stage_defs[index], player, _wave_system, EnemyScene, self)
	_restore_player_presentation()
	_snap_camera_to_player()
	if _hud and _hud.has_method("update_objective"):
		_hud.update_objective("Reach the next encounter")


## Handle stage completion in multi-stage mode - transition to next floor.
func _on_stage_completed(_stage_id: StringName) -> void:
	if _stage_defs.is_empty():
		return  # Not in multi-stage mode.
	if _current_stage_index + 1 >= _stage_defs.size():
		return  # Last stage - DungeonManager handles dungeon completion.
	# Transition to next stage with fade.
	_do_stage_transition(_current_stage_index + 1)


## Fade transition between stages (floors).
func _do_stage_transition(next_index: int) -> void:
	_transitioning = true
	var half_time := Constants.DUNGEON_ROOM_TRANSITION_TIME * 0.5
	var floor_label := "Floor %d" % (next_index + 1)
	var stage_name := _stage_defs[next_index].stage_name if next_index < _stage_defs.size() else ""
	_show_loading_message("DESCENDING", "%s  |  %s" % [floor_label, stage_name] if stage_name != "" else floor_label)
	# Fade out.
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, half_time)
	tween.parallel().tween_property(_loading_panel, "modulate:a", 1.0, 0.15)
	await tween.finished
	# Load next stage.
	_load_stage(next_index)
	# Fade in.
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, half_time)
	tween.parallel().tween_property(_loading_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	_loading_panel.visible = false
	_transitioning = false
	_show_stage_floor_toast(next_index)


func _show_stage_floor_toast(index: int) -> void:
	if index < 0 or index >= _stage_defs.size():
		return
	var label := "FLOOR %d" % (index + 1)
	var stage_name := _stage_defs[index].stage_name
	if stage_name != "":
		label = "%s  |  %s" % [label, stage_name]
	ToastSystem.show_toast(label, Color(0.8, 0.9, 1.0))


## Start in legacy room-based mode.
func _start_room_mode(dungeon_def: DungeonDef) -> void:
	_load_room_from(dungeon_def, 0)
	_dungeon_manager.start_dungeon(dungeon_def, _wave_system)


## Resolve which DungeonDef to use based on pending_dungeon_id.
func _resolve_dungeon_def() -> DungeonDef:
	var pending := GameState.pending_dungeon_id
	if pending != &"" and DUNGEON_REGISTRY.has(pending):
		return load(DUNGEON_REGISTRY[pending]) as DungeonDef
	return DefaultDungeonData


func _load_room_from(dungeon_def: DungeonDef, index: int) -> void:
	_active_dungeon_def = dungeon_def
	_load_room(index)


func _load_room(index: int) -> void:
	# Clean up enemies from previous room.
	if _wave_system:
		_wave_system.clear_all_enemies()
	RuntimeState.clear_room_bounds()

	if _current_room:
		_current_room.queue_free()
		_current_room = null

	var dungeon_def := _active_dungeon_def if _active_dungeon_def else DefaultDungeonData as DungeonDef
	if index >= dungeon_def.room_scenes.size():
		return

	var room_path := dungeon_def.room_scenes[index]
	var room_scene := load(room_path) as PackedScene
	if room_scene == null:
		push_error("DungeonRun: Failed to load room scene: " + room_path)
		return

	_current_room = room_scene.instantiate()
	_strip_fullscreen_background(_current_room)
	add_child(_current_room)
	_update_room_bounds(_current_room)

	# Position player at room spawn point.
	var spawn := _current_room.get_node_or_null("SpawnPoints/PlayerSpawn") as Node3D
	if spawn:
		player.global_position = _resolve_room_spawn_position(_current_room, spawn.global_position)
	player.velocity = Vector3.ZERO
	_restore_player_presentation()
	_snap_camera_to_player()

	# Set wave system spawn points from room markers (4 edges for isometric).
	var left := _current_room.get_node_or_null("SpawnPoints/EnemySpawnLeft") as Node3D
	var right := _current_room.get_node_or_null("SpawnPoints/EnemySpawnRight") as Node3D
	var top := _current_room.get_node_or_null("SpawnPoints/EnemySpawnTop") as Node3D
	var bottom := _current_room.get_node_or_null("SpawnPoints/EnemySpawnBottom") as Node3D
	if left:
		_wave_system.spawn_left = left.global_position
	if right:
		_wave_system.spawn_right = right.global_position
	if top:
		_wave_system.spawn_top = top.global_position
	if bottom:
		_wave_system.spawn_bottom = bottom.global_position


func _update_room_bounds(room: Node3D) -> void:
	var bounds := _extract_room_bounds(room)
	if bounds.x >= bounds.y:
		RuntimeState.clear_room_bounds()
		return
	var z_bounds := _extract_room_bounds_z(room)
	RuntimeState.set_room_bounds(bounds.x, bounds.y, z_bounds.x, z_bounds.y)


func _extract_room_bounds(room: Node3D) -> Vector2:
	var left_shape := room.get_node_or_null("WallLeft/CollisionShape3D") as CollisionShape3D
	var right_shape := room.get_node_or_null("WallRight/CollisionShape3D") as CollisionShape3D
	if left_shape and right_shape:
		var left_bounds := _extract_box_bounds_x(left_shape)
		var right_bounds := _extract_box_bounds_x(right_shape)
		if left_bounds.x < left_bounds.y and right_bounds.x < right_bounds.y:
			var wall_min_x := left_bounds.y + Constants.ROOM_BOUNDS_INNER_PADDING
			var wall_max_x := right_bounds.x - Constants.ROOM_BOUNDS_INNER_PADDING
			if wall_min_x < wall_max_x:
				return Vector2(wall_min_x, wall_max_x)

	var floor_shape := room.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if floor_shape:
		var floor_bounds := _extract_box_bounds_x(floor_shape)
		if floor_bounds.x < floor_bounds.y:
			var floor_min_x := floor_bounds.x + Constants.ROOM_BOUNDS_INNER_PADDING
			var floor_max_x := floor_bounds.y - Constants.ROOM_BOUNDS_INNER_PADDING
			if floor_min_x < floor_max_x:
				return Vector2(floor_min_x, floor_max_x)

	return Vector2(1.0, -1.0)


func _extract_box_bounds_x(collision_shape: CollisionShape3D) -> Vector2:
	if collision_shape == null:
		return Vector2(1.0, -1.0)
	var box := collision_shape.shape as BoxShape3D
	if box == null:
		return Vector2(1.0, -1.0)
	var half_x := box.size.x * absf(collision_shape.global_transform.basis.get_scale().x) * 0.5
	var center_x := collision_shape.global_position.x
	return Vector2(center_x - half_x, center_x + half_x)


## Extract Z bounds from room floor collision shape.
func _extract_room_bounds_z(room: Node3D) -> Vector2:
	var floor_shape := room.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if floor_shape:
		var box := floor_shape.shape as BoxShape3D
		if box:
			var half_z := box.size.z * absf(floor_shape.global_transform.basis.get_scale().z) * 0.5
			var center_z := floor_shape.global_position.z
			var min_z := center_z - half_z + Constants.ROOM_BOUNDS_INNER_PADDING
			var max_z := center_z + half_z - Constants.ROOM_BOUNDS_INNER_PADDING
			if min_z < max_z:
				return Vector2(min_z, max_z)
	# Default Z bounds for isometric play area.
	return Vector2(-8.0, 8.0)


func _resolve_room_spawn_position(room: Node3D, desired_position: Vector3) -> Vector3:
	if room == null:
		return desired_position
	var x_bounds := _extract_room_bounds(room)
	var z_bounds := _extract_room_bounds_z(room)
	if x_bounds.x >= x_bounds.y or z_bounds.x >= z_bounds.y:
		return desired_position
	return SpawnPositionResolverScript.resolve_position(
		get_world_3d(),
		desired_position,
		x_bounds.x,
		x_bounds.y,
		z_bounds.x,
		z_bounds.y,
		PLAYER_SPAWN_RADIUS
	)


## Feed XP to the active player in real-time when an enemy dies.
func _on_enemy_died_xp(enemy: Node, _type: StringName, _pos: Vector3) -> void:
	if enemy is EnemyController:
		var ec := enemy as EnemyController
		if ec.enemy_def and ec.enemy_def.xp_reward > 0:
			player.xp_tracker.add_xp(ec.enemy_def.xp_reward)
			DamageNumberSpawner.spawn_xp(_pos, ec.enemy_def.xp_reward)


func _on_level_up(_player_index: int, new_level: int) -> void:
	# Musou-density fights level you up often; never pause mid-combat. Stat points are banked
	# for the party screen (same behaviour as battlefields).
	ToastSystem.show_toast("LEVEL UP!  Lv %d" % new_level, Color(1.0, 0.92, 0.5))


func _on_room_cleared(_room_index: int) -> void:
	if RuntimeState.stage_mode:
		return  # Stage mode doesn't use room transitions.
	if _transitioning:
		return
	if not _dungeon_manager.is_active():
		return
	# Auto-save progress after each room clear.
	SaveManager.save_game(GameState.active_save_slot)
	_do_room_transition()


func _do_room_transition() -> void:
	_transitioning = true
	var half_time := Constants.DUNGEON_ROOM_TRANSITION_TIME * 0.5
	_show_loading_message("LOADING ROOM", "Advancing deeper")

	# Fade out.
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, half_time)
	tween.parallel().tween_property(_loading_panel, "modulate:a", 1.0, 0.15)
	await tween.finished

	# Load next room and advance dungeon.
	var next_index := _dungeon_manager.get_current_room_index() + 1
	_load_room(next_index)
	_dungeon_manager.advance_to_next_room()

	# Fade in.
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, half_time)
	tween.parallel().tween_property(_loading_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	_loading_panel.visible = false

	_transitioning = false


func _on_dungeon_completed(_dungeon_id: StringName) -> void:
	# Apply XP through level-up processing for all party members.
	_apply_party_xp(_dungeon_manager.get_xp_earned())
	# Auto-save after dungeon completion (gold + flags already banked by DungeonManager).
	SaveManager.save_game(GameState.active_save_slot)
	get_tree().paused = true
	InputManager.set_context(InputManager.InputContext.MENU)
	var screen := VictoryScene.instantiate()
	add_child(screen)
	screen.display_stats(
		_dungeon_manager.get_score_tracker(),
		_dungeon_manager.get_xp_earned(),
		_dungeon_manager.get_gold_earned()
	)
	screen.continue_pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.go_to_overworld()
	)


## Process XP through level-up checks for all active party members.
func _apply_party_xp(xp_earned: int) -> void:
	PartyXPDistributor.apply(player, xp_earned)


func _on_dungeon_failed() -> void:
	# Delay before showing defeat screen.
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = true
	InputManager.set_context(InputManager.InputContext.MENU)
	var screen := DefeatScene.instantiate()
	add_child(screen)
	screen.retry_pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.go_to_overworld()
	)


func _process(delta: float) -> void:
	if _char_switch_cooldown > 0.0:
		_char_switch_cooldown -= delta
	_sync_horde_arena()
	_handle_runtime_actions()
	_check_kill_plane()
	_update_debug_label()


func _handle_runtime_actions() -> void:
	if get_tree().paused:
		return
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"pause"):
		_toggle_pause_menu()
		return
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"character_next"):
		_switch_character(1)
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"character_prev"):
		_switch_character(-1)
	if InputManager.is_action_just_pressed_for_player(player.player_index, &"technique_cycle"):
		player.cycle_technique()


## Switch active character by offset (+1 next, -1 prev). Respects cooldown.
func _switch_character(direction: int) -> void:
	if _char_switch_cooldown > 0.0:
		return
	if PartySwitcher.switch_active(player, direction):
		_char_switch_cooldown = Constants.CHARACTER_SWITCH_COOLDOWN


func _toggle_pause_menu() -> void:
	if _pause_menu != null:
		_resume_from_pause()
		return
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(PauseMenuScript)
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_resume_from_pause)
	InputManager.set_context(InputManager.InputContext.MENU)
	get_tree().paused = true


func _resume_from_pause() -> void:
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
	InputManager.set_context(InputManager.InputContext.COMBAT)
	get_tree().paused = false


## Keep the horde inside whatever bounds currently constrain the player (stage or arena lock).
func _sync_horde_arena() -> void:
	var b := RuntimeState.get_active_bounds()
	var min_x := float(b.get("min_x", -100.0))
	var min_z := float(b.get("min_z", -100.0))
	_horde.arena = Rect2(min_x, min_z, float(b.get("max_x", 100.0)) - min_x, float(b.get("max_z", 100.0)) - min_z)


func _check_kill_plane() -> void:
	if player.position.y < -10.0:
		var spawn: Node3D = null
		if RuntimeState.stage_mode and _stage_runner != null:
			player.global_position = _stage_runner.get_safe_respawn_position(player.global_position)
		elif _current_room:
			spawn = _current_room.get_node_or_null("SpawnPoints/PlayerSpawn") as Node3D
			if spawn:
				player.global_position = _resolve_room_spawn_position(_current_room, spawn.global_position)
			else:
				player.global_position = Vector3(0, 0.1, 0)
		else:
			player.position = Vector3(0, 0.1, 0)
		player.position = RuntimeBoundsPolicyScript.clamp_position(player.position, RuntimeState.get_active_bounds())
		player.velocity = Vector3.ZERO
		player.collision_layer = Constants.LAYER_PLAYER
		player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM
		_restore_player_presentation()


func _update_debug_label() -> void:
	if not player or not player.state_machine:
		return

	var info: String
	if RuntimeState.stage_mode:
		info = "Stage: %d/%d | State: %s | FPS: %d" % [
			RuntimeState.stage_encounters_completed,
			RuntimeState.stage_total_encounters,
			str(player.state_machine.current_state_name),
			Engine.get_frames_per_second()
		]
	else:
		var room_idx := _dungeon_manager.get_current_room_index() if _dungeon_manager else 0
		info = "Room: %d | State: %s | FPS: %d" % [
			room_idx + 1,
			str(player.state_machine.current_state_name),
			Engine.get_frames_per_second()
		]
	info += "\nPos: (%.1f, %.1f, %.1f) | Vel: (%.1f, %.1f)" % [
		player.position.x, player.position.y, player.position.z,
		player.velocity.x, player.velocity.y
	]
	info += "\nGold: %d (+%d)" % [GameState.gold, _dungeon_manager.get_gold_earned() if _dungeon_manager else 0]
	info += "\n[ESC/Start] Pause"
	if _hud and _hud.has_method("update_state_info"):
		_hud.update_state_info(info)


func _snap_camera_to_player() -> void:
	if camera == null or not is_instance_valid(camera):
		return
	camera.snap_to_target()
	camera.call_deferred("snap_to_target")


func _restore_player_presentation() -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.model_pivot:
		player.model_pivot.visible = true
		player.model_pivot.scale = Vector3.ONE
	if player.character_model:
		player.character_model.visible = true
		player.character_model.scale = Vector3.ONE
	player.restore_mesh()


func _strip_fullscreen_background(root: Node) -> void:
	if root == null:
		return
	var background := root.get_node_or_null("BackgroundLayer")
	if background != null:
		background.queue_free()
