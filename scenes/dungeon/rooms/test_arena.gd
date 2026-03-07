extends Node3D


const EnemyScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const RusherDef := preload("res://resources/enemies/rusher_def.tres")
const RangedDef := preload("res://resources/enemies/ranged_def.tres")
const ShieldDef := preload("res://resources/enemies/shield_def.tres")
const RuntimeBoundsPolicyScript := preload("res://scripts/components/runtime_bounds_policy.gd")

## Maps spawn point names to enemy definitions for variety.
const SPAWN_DEFS: Dictionary = {
	"EnemySpawn1": RusherDef,
	"EnemySpawn2": RangedDef,
	"EnemySpawn3": ShieldDef,
}

@onready var player: PlayerController = $Player

var _enemies: Array[EnemyController] = []
var _hud: Node = null
var _pause_menu: CanvasLayer = null


func _ready() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	print("[TestArena] _ready — scene loaded, player TP=%.0f" % player.tp_tracker.get_current_tp())
	_setup_juice_systems()
	_setup_hud()
	_update_room_bounds()
	_spawn_enemies()


func _setup_juice_systems() -> void:
	var hitstop := HitstopSystem.new()
	hitstop.name = "HitstopSystem"
	add_child(hitstop)

	var vfx := VFXSystem.new()
	vfx.name = "VFXSystem"
	add_child(vfx)


func _setup_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _input(event: InputEvent) -> void:
	# Temporary: log ALL joypad button presses to diagnose mapping.
	if event is InputEventJoypadButton and event.pressed:
		var btn := event as InputEventJoypadButton
		print("[RAW] JoypadButton index=%d device=%d" % [btn.button_index, btn.device])
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if absf(motion.axis_value) > 0.5:
			print("[RAW] JoypadAxis axis=%d value=%.2f device=%d" % [motion.axis, motion.axis_value, motion.device])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_update_debug_label()
	_check_kill_plane()

	# R to restart arena.
	if Input.is_key_pressed(KEY_R) and not get_tree().paused:
		_restart_arena()


func _toggle_pause_menu() -> void:
	if _pause_menu != null:
		_resume_from_pause()
		return
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(PauseMenuScript)
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_resume_from_pause)
	get_tree().paused = true


func _resume_from_pause() -> void:
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
	get_tree().paused = false
	InputManager.set_context(InputManager.InputContext.COMBAT)


func _spawn_enemies() -> void:
	var spawns := $SpawnPoints
	for child in spawns.get_children():
		if child.name.begins_with("EnemySpawn"):
			var enemy := EnemyScene.instantiate() as EnemyController
			add_child(enemy)
			enemy.global_position = child.global_position

			# Configure from EnemyDef based on spawn point name.
			var def: EnemyDef = SPAWN_DEFS.get(child.name, RusherDef)
			enemy.configure(def, player)
			_enemies.append(enemy)


func _restart_arena() -> void:
	Engine.time_scale = 1.0
	InputManager.set_context(InputManager.InputContext.COMBAT)

	# Remove old enemies.
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()

	# Reset player.
	player.position = Vector3(0, 0.1, 0)
	player.position = RuntimeBoundsPolicyScript.clamp_position(player.position, RuntimeState.get_active_bounds())
	player.velocity = Vector3.ZERO
	player.health.reset()
	player.tp_tracker.set_current_tp(Constants.TP_MAX)
	player.collision_layer = Constants.LAYER_PLAYER
	player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM
	player.hurtbox.is_invincible = false
	player.model_pivot.scale = Vector3(1, 1, 1)
	player.character_model.scale = Vector3(1, 1, 1)
	player.restore_mesh()
	player.state_machine.transition_to(&"idle")

	# Spawn fresh enemies.
	_spawn_enemies()


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		InputManager.set_context(InputManager.InputContext.MENU)


func _check_kill_plane() -> void:
	if player.position.y < -10.0:
		player.position = Vector3(0, 0.1, 0)
		player.position = RuntimeBoundsPolicyScript.clamp_position(player.position, RuntimeState.get_active_bounds())
		player.velocity = Vector3.ZERO
		player.collision_layer = Constants.LAYER_PLAYER
		player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM


func _update_room_bounds() -> void:
	var bounds := _extract_room_bounds()
	if bounds.x >= bounds.y:
		RuntimeState.clear_room_bounds()
		return
	RuntimeState.set_room_bounds(bounds.x, bounds.y)


func _extract_room_bounds() -> Vector2:
	var left_shape := get_node_or_null("WallLeft/CollisionShape3D") as CollisionShape3D
	var right_shape := get_node_or_null("WallRight/CollisionShape3D") as CollisionShape3D
	if left_shape and right_shape:
		var left_bounds := _extract_box_bounds_x(left_shape)
		var right_bounds := _extract_box_bounds_x(right_shape)
		if left_bounds.x < left_bounds.y and right_bounds.x < right_bounds.y:
			var wall_min_x := left_bounds.y + Constants.ROOM_BOUNDS_INNER_PADDING
			var wall_max_x := right_bounds.x - Constants.ROOM_BOUNDS_INNER_PADDING
			if wall_min_x < wall_max_x:
				return Vector2(wall_min_x, wall_max_x)

	var floor_shape := get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
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


func _update_debug_label() -> void:
	if not player or not player.state_machine:
		return

	var alive := 0
	for enemy in _enemies:
		if is_instance_valid(enemy) and not enemy.health.is_dead():
			alive += 1

	var info := "State: %s | Enemies: %d | FPS: %d" % [
		str(player.state_machine.current_state_name),
		alive,
		Engine.get_frames_per_second()
	]
	info += "\nPos: (%.1f, %.1f, %.1f) | Vel: (%.1f, %.1f)" % [
		player.position.x, player.position.y, player.position.z,
		player.velocity.x, player.velocity.y
	]
	info += "\n[W+J] Launcher  [R] Restart  [ESC] Quit"
	if _hud and _hud.has_method("update_state_info"):
		_hud.update_state_info(info)
