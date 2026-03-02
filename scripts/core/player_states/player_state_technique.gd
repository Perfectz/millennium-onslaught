## Technique projectile attack state — spends TP to fire an energy bolt.
## Windup (cast) → fire projectile → recovery. Dodge-cancellable during recovery.
class_name PlayerStateTechnique
extends State


var _projectile_scene: PackedScene = null

var _timer: float = 0.0
var _elapsed: float = 0.0
var _phase: int = 0  # 0=windup, 1=fired, 2=recovery
var _attack_data: AttackDef


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController

	# Check TP — if insufficient, bail to idle immediately.
	if not player.tp_tracker.spend_tp(Constants.PLAYER_PROJECTILE_TP_COST):
		_phase = -1
		return

	_attack_data = preload("res://resources/attacks/projectile_attack.tres")
	_phase = 0
	_elapsed = 0.0
	_timer = _attack_data.windup_time
	entity.velocity.x = 0.0

	player.combo_tracker.reset()
	player.play_animation(&"attack_heavy", 2.5)
	player.flash_mesh(Color(0.3, 0.7, 1.0))

	EventBus.combat_technique_used.emit(player, &"projectile", Constants.PLAYER_PROJECTILE_TP_COST)

	if _timer <= 0.0:
		_fire_projectile()


func _fire_projectile() -> void:
	_phase = 1
	var player: PlayerController = entity as PlayerController

	# Lazy-load to avoid circular dependency with PlayerController.
	if _projectile_scene == null:
		_projectile_scene = load("res://scenes/projectiles/player_projectile.tscn")
	# Spawn projectile at player position offset by facing direction.
	var projectile: Area3D = _projectile_scene.instantiate()
	var dir := Vector3.RIGHT if player.facing_right else Vector3.LEFT
	var spawn_pos := entity.global_position + Vector3(0, 0.9, 0)
	spawn_pos.x += Constants.HITBOX_X_OFFSET * (1.0 if player.facing_right else -1.0)

	# Must add to tree before setting global_position.
	entity.get_tree().root.add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.setup(dir, Constants.PLAYER_PROJECTILE_SPEED, entity)

	player.flash_mesh(Color(1.0, 1.0, 1.0))
	_spawn_muzzle_flash(spawn_pos)

	# Immediately start recovery.
	_start_recovery()


func _start_recovery() -> void:
	_phase = 2
	_timer = _attack_data.recovery_time
	var player: PlayerController = entity as PlayerController
	player.restore_mesh()
	player.play_animation(&"idle")


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.restore_mesh()


func physics_process(delta: float) -> StringName:
	# Bail if TP was insufficient.
	if _phase == -1:
		return &"idle"

	var player: PlayerController = entity as PlayerController
	_timer -= delta
	_elapsed += delta
	player.apply_gravity(delta)
	entity.move_and_slide()

	match _phase:
		0:  # windup
			if _timer <= 0.0:
				_fire_projectile()
		2:  # recovery
			# Dodge cancel during recovery.
			if Input.is_action_just_pressed("dodge") and player.can_dodge():
				return &"dodge"
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"idle"
				return &"fall"

	return &""


## Spawn a quick burst of cyan particles at the fire point.
func _spawn_muzzle_flash(pos: Vector3) -> void:
	var flash := GPUParticles3D.new()
	flash.amount = 10
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.explosiveness = 1.0
	flash.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.spread = 45.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = Color(0.5, 0.9, 1.0, 1.0)

	var player: PlayerController = entity as PlayerController
	if player.facing_right:
		mat.direction = Vector3(1, 0, 0)
	else:
		mat.direction = Vector3(-1, 0, 0)
	flash.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.6, 0.95, 1.0, 1.0)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.4, 0.8, 1.0, 1.0)
	draw_mat.emission_energy_multiplier = 4.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 0.06
	mesh.material = draw_mat
	flash.draw_pass_1 = mesh

	flash.global_position = pos
	entity.get_tree().root.add_child(flash)
	flash.finished.connect(flash.queue_free)
