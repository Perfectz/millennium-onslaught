extends Node3D


const EnemyScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const RusherDef := preload("res://resources/enemies/rusher_def.tres")
const RangedDef := preload("res://resources/enemies/ranged_def.tres")
const ShieldDef := preload("res://resources/enemies/shield_def.tres")

## Maps spawn point names to enemy definitions for variety.
const SPAWN_DEFS: Dictionary = {
	"EnemySpawn1": RusherDef,
	"EnemySpawn2": RangedDef,
	"EnemySpawn3": ShieldDef,
}

@onready var player: PlayerController = $Player

var _enemies: Array[EnemyController] = []
var _hud: Node = null


func _ready() -> void:
	_setup_juice_systems()
	_setup_hud()
	_spawn_enemies()


func _setup_juice_systems() -> void:
	var hitstop := HitstopSystem.new()
	hitstop.name = "HitstopSystem"
	add_child(hitstop)

	var shake := CameraShakeSystem.new()
	shake.name = "CameraShakeSystem"
	shake.camera = $Camera3D
	add_child(shake)

	var vfx := VFXSystem.new()
	vfx.name = "VFXSystem"
	add_child(vfx)


func _setup_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _process(_delta: float) -> void:
	_update_debug_label()
	_check_kill_plane()

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# R to restart arena.
	if Input.is_key_pressed(KEY_R):
		_restart_arena()


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

	# Remove old enemies.
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()

	# Reset player.
	player.position = Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	player.health.reset()
	player.tp_tracker.reset()
	player.collision_layer = Constants.LAYER_PLAYER
	player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM
	player.hurtbox.is_invincible = false
	player.model_pivot.scale = Vector3(1, 1, 1)
	player.character_model.scale = Vector3(1, 1, 1)
	player.restore_mesh()
	player.state_machine.transition_to(&"idle")

	# Spawn fresh enemies.
	_spawn_enemies()


func _check_kill_plane() -> void:
	if player.position.y < -10.0:
		player.position = Vector3(0, 0.1, 0)
		player.velocity = Vector3.ZERO
		player.collision_layer = Constants.LAYER_PLAYER
		player.collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM


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
