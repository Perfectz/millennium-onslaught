## Technique projectile attack state — spends TP to fire an energy bolt.
## Windup (cast) → fire projectile → recovery. Dodge-cancellable during recovery.
## Supports CharacterDef techniques with element, particle color, and TP cost.
class_name PlayerStateTechnique
extends State


var _projectile_scene: PackedScene = null

var _timer: float = 0.0
var _elapsed: float = 0.0
var _phase: int = 0  # 0=windup, 1=fired, 2=recovery
var _attack_data: AttackDef
var _technique: TechniqueDef


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController

	# Resolve active technique from CharacterDef or use fallback.
	_technique = player.get_active_technique()
	var tp_cost: float
	if _technique:
		tp_cost = _technique.tp_cost
	else:
		tp_cost = Constants.PLAYER_PROJECTILE_TP_COST

	print("[Technique] enter: tech=%s tp=%.1f cost=%.1f" % [
		str(_technique.technique_id) if _technique else "null",
		player.tp_tracker.get_current_tp(),
		tp_cost,
	])

	# Check TP — if insufficient, bail to idle immediately with user feedback.
	if not player.tp_tracker.spend_tp(tp_cost):
		if ToastSystem:
			ToastSystem.show_toast("Not enough TP!", Color(1.0, 0.45, 0.35))
		_phase = -1
		return

	# Build attack data from technique or fallback to generic projectile.
	if _technique:
		_attack_data = AttackDef.new()
		_attack_data.base_damage = _technique.base_damage
		_attack_data.damage_multiplier = 1.0
		_attack_data.element_type = _technique.element_type
		_attack_data.status_effect_chance = _technique.status_effect_chance
		_attack_data.status_effect_duration = _technique.status_effect_duration
		_attack_data.windup_time = 0.15
		_attack_data.active_time = 0.1
		_attack_data.recovery_time = 0.3
		_attack_data.knockback_force = _technique.knockback_force
		_attack_data.knockback_direction = Vector3(1, 0.2, 0)
	else:
		_attack_data = preload("res://resources/attacks/projectile_attack.tres").duplicate()

	_phase = 0
	_elapsed = 0.0
	_timer = _attack_data.windup_time
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0

	player.combo_tracker.reset()
	var anim_name: StringName = &"attack_heavy"
	if _technique and _technique.animation_name != &"":
		anim_name = _technique.animation_name
	player.play_animation(anim_name, 2.5)

	# Flash with technique's particle color or default cyan.
	var flash_color := Color(0.3, 0.7, 1.0)
	if _technique and _technique.particle_color != Color.BLACK:
		flash_color = _technique.particle_color
	player.flash_mesh(flash_color)

	var tech_name: StringName = &"projectile"
	if _technique:
		tech_name = _technique.technique_id
	EventBus.combat_technique_used.emit(player, tech_name, tp_cost)

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
	var dir := player.facing_direction
	var spawn_pos := entity.global_position + Vector3(0, 0.9, 0)
	spawn_pos.x += Constants.HITBOX_X_OFFSET * player.facing_direction.x
	spawn_pos.z += Constants.HITBOX_X_OFFSET * player.facing_direction.z

	# Must add to tree before setting global_position.
	entity.get_tree().root.add_child(projectile)
	projectile.global_position = spawn_pos
	var proj_speed: float = Constants.PLAYER_PROJECTILE_SPEED
	if _technique and _technique.projectile_speed > 0.0:
		proj_speed = _technique.projectile_speed
	projectile.setup(dir, proj_speed, entity)

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
	player.clamp_to_bounds()

	match _phase:
		0:  # windup
			if _timer <= 0.0:
				_fire_projectile()
		2:  # recovery
			# Dodge cancel during recovery.
			if player.intent_buffer.consume(&"dodge") and player.can_dodge():
				return &"dodge"
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"idle"
				return &"fall"

	return &""


## Spawn a quick burst of particles at the fire point (colored by technique).
func _spawn_muzzle_flash(pos: Vector3) -> void:
	var particle_col := Color(0.5, 0.9, 1.0, 1.0)
	if _technique and _technique.particle_color != Color.BLACK:
		particle_col = _technique.particle_color
	var flash := GPUParticles3D.new()
	flash.amount = 10
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.spread = 45.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = particle_col

	var player: PlayerController = entity as PlayerController
	mat.direction = player.facing_direction
	flash.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = particle_col
	draw_mat.emission_enabled = true
	draw_mat.emission = particle_col
	draw_mat.emission_energy_multiplier = 4.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 0.06
	mesh.material = draw_mat
	flash.draw_pass_1 = mesh

	entity.get_tree().root.add_child(flash)
	flash.global_position = pos
	flash.emitting = true
	flash.finished.connect(flash.queue_free)
