## Spell casting state — triggered by dedicated spell buttons (LB/RT/LT).
## Supports 3 spell types: heal, projectile (fireball DOT), AOE burst.
## Windup → execute → recovery. Dodge-cancellable during recovery.
extends State


var _projectile_scene: PackedScene = preload("res://scenes/projectiles/player_projectile.tscn")

var _timer: float = 0.0
var _phase: int = 0  # 0=windup, 1=execute, 2=recovery, -1=bail
var _attack_data: AttackDef
var _technique: TechniqueDef


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController

	# Resolve the spell queued by a button press.
	_technique = player.get_pending_spell()
	if not _technique:
		_phase = -1
		return

	# Check TP — bail if insufficient.
	if not player.tp_tracker.spend_tp(_technique.tp_cost):
		if ToastSystem:
			ToastSystem.show_toast("Not enough TP!", Color(1.0, 0.45, 0.35))
		_phase = -1
		return

	# Build attack data from technique for offensive spells.
	_attack_data = AttackDef.new()
	_attack_data.base_damage = _technique.base_damage
	_attack_data.damage_multiplier = 1.0
	_attack_data.element_type = _technique.element_type
	_attack_data.status_effect_chance = _technique.status_effect_chance
	_attack_data.status_effect_duration = _technique.status_effect_duration
	_attack_data.windup_time = Constants.SPELL_WINDUP_TIME
	_attack_data.active_time = 0.1
	_attack_data.recovery_time = Constants.SPELL_RECOVERY_TIME
	_attack_data.knockback_force = _technique.knockback_force
	_attack_data.knockback_direction = Vector3(1, 0.2, 0)

	_phase = 0
	_timer = Constants.SPELL_WINDUP_TIME
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0

	player.combo_tracker.reset()
	var anim_name: StringName = &"attack_heavy"
	if _technique.animation_name != &"":
		anim_name = _technique.animation_name
	player.play_animation(anim_name, 2.5)

	# Flash with spell's particle color.
	player.flash_mesh(_technique.particle_color)

	EventBus.combat_spell_cast.emit(player, _technique.technique_id, _technique.tp_cost)

	if _timer <= 0.0:
		_execute_spell()


func physics_process(delta: float) -> StringName:
	if _phase == -1:
		return &"idle"

	var player: PlayerController = entity as PlayerController
	_timer -= delta
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

	match _phase:
		0:  # windup
			if _timer <= 0.0:
				_execute_spell()
		2:  # recovery — dodge-cancellable
			if player.intent_buffer.consume(&"dodge") and player.can_dodge():
				return &"dodge"
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"idle"
				return &"fall"

	return &""


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.restore_mesh()


## Dispatch to the correct spell handler based on spell_type.
func _execute_spell() -> void:
	_phase = 1
	match _technique.spell_type:
		TechniqueDef.SpellType.PROJECTILE:
			_cast_projectile()
		TechniqueDef.SpellType.HEAL:
			_cast_heal()
		TechniqueDef.SpellType.AOE_BURST:
			_cast_aoe_burst()
		TechniqueDef.SpellType.BUFF:
			_cast_buff()
	_start_recovery()


func _cast_projectile() -> void:
	var player: PlayerController = entity as PlayerController

	var projectile: Area3D = _projectile_scene.instantiate()
	var dir := player.facing_direction
	var spawn_pos := entity.global_position + Vector3(0, 0.9, 0)
	spawn_pos.x += Constants.HITBOX_X_OFFSET * player.facing_direction.x
	spawn_pos.z += Constants.HITBOX_X_OFFSET * player.facing_direction.z

	entity.get_tree().root.add_child(projectile)
	projectile.global_position = spawn_pos
	var proj_speed: float = _technique.projectile_speed if _technique.projectile_speed > 0.0 else Constants.PLAYER_PROJECTILE_SPEED
	projectile.setup(dir, proj_speed, entity)

	player.flash_mesh(Color(1.0, 1.0, 1.0))
	_spawn_cast_particles(spawn_pos, _technique.particle_color)


func _cast_heal() -> void:
	var player: PlayerController = entity as PlayerController
	var heal_amount := _technique.heal_amount
	if heal_amount <= 0.0:
		heal_amount = Constants.SPELL_HEAL_AMOUNT
	player.health.heal(heal_amount)

	EventBus.combat_spell_heal.emit(player, heal_amount)
	if ToastSystem:
		ToastSystem.show_toast("+" + str(int(heal_amount)) + " HP", Color(0.2, 1.0, 0.4))

	player.flash_mesh(Color(0.3, 1.0, 0.5))
	_spawn_heal_particles()


func _cast_aoe_burst() -> void:
	var player: PlayerController = entity as PlayerController
	var radius: float = _technique.aoe_radius
	if radius <= 0.0:
		radius = Constants.SPELL_BURST_RADIUS

	# Create a temporary Area3D with sphere collision to detect enemies in range.
	var aoe := Area3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	var col := CollisionShape3D.new()
	col.shape = shape
	aoe.add_child(col)
	# Monitor enemy hurtboxes (layer 7 = LAYER_ENEMY_HURTBOX = 64).
	aoe.collision_mask = Constants.LAYER_ENEMY_HURTBOX
	aoe.collision_layer = 0
	aoe.monitoring = true

	entity.get_tree().root.add_child(aoe)
	aoe.global_position = entity.global_position + Vector3(0, 0.9, 0)

	# Force physics update to detect overlaps this frame.
	aoe.force_update_transform()
	await entity.get_tree().physics_frame

	var hit_targets: Array[Node3D] = []
	for area: Area3D in aoe.get_overlapping_areas():
		if area is Hurtbox:
			var hurtbox := area as Hurtbox
			var target := hurtbox.get_parent()
			if target != entity and target not in hit_targets:
				hurtbox.receive_hit(_attack_data, entity)
				hit_targets.append(target)

	aoe.queue_free()

	player.flash_mesh(Color(1.0, 1.0, 1.0))
	_spawn_burst_particles(radius)


func _cast_buff() -> void:
	var player: PlayerController = entity as PlayerController
	var buff_amount := _technique.buff_amount
	if buff_amount <= 0.0:
		buff_amount = Constants.SPELL_BARRIER_DEFENSE_BONUS
	var duration := _technique.buff_duration
	if duration <= 0.0:
		duration = Constants.SPELL_BARRIER_DURATION

	player.status_effects.apply_effect(&"defense_up", duration, buff_amount)

	EventBus.combat_spell_buff.emit(player, _technique.buff_stat, buff_amount, duration)
	if ToastSystem:
		ToastSystem.show_toast("Defense +" + str(int(buff_amount)) + " (" + str(int(duration)) + "s)", Color(0.3, 0.6, 1.0))

	player.flash_mesh(Color(0.4, 0.7, 1.0))
	_spawn_shield_particles()


func _start_recovery() -> void:
	_phase = 2
	_timer = Constants.SPELL_RECOVERY_TIME
	var player: PlayerController = entity as PlayerController
	player.restore_mesh()
	player.play_animation(&"idle")


## Spawn directional cast particles (for projectile spells).
func _spawn_cast_particles(pos: Vector3, color: Color) -> void:
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
	mat.color = color
	var player: PlayerController = entity as PlayerController
	mat.direction = player.facing_direction
	flash.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
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


## Spawn upward-rising green heal particles around the caster.
func _spawn_heal_particles() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 16
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.8
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 2, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.2, 1.0, 0.4, 0.8)
	mat.direction = Vector3(0, 1, 0)
	particles.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.2, 1.0, 0.4, 0.8)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.2, 1.0, 0.4)
	draw_mat.emission_energy_multiplier = 3.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	mesh.material = draw_mat
	particles.draw_pass_1 = mesh

	entity.get_tree().root.add_child(particles)
	particles.global_position = entity.global_position + Vector3(0, 0.5, 0)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Spawn expanding ring of particles for AOE burst.
func _spawn_burst_particles(radius: float) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 24
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 2.0
	mat.initial_velocity_max = radius * 3.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = _technique.particle_color
	mat.direction = Vector3(0, 0, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.3
	particles.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = _technique.particle_color
	draw_mat.emission_enabled = true
	draw_mat.emission = _technique.particle_color
	draw_mat.emission_energy_multiplier = 4.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.material = draw_mat
	particles.draw_pass_1 = mesh

	entity.get_tree().root.add_child(particles)
	particles.global_position = entity.global_position + Vector3(0, 0.9, 0)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Spawn swirling blue shield particles for defense buff.
func _spawn_shield_particles() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.6
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 1.5, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.3, 0.6, 1.0, 0.8)
	mat.direction = Vector3(0, 1, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.8
	particles.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.3, 0.6, 1.0, 0.8)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.3, 0.6, 1.0)
	draw_mat.emission_energy_multiplier = 3.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 0.06
	mesh.material = draw_mat
	particles.draw_pass_1 = mesh

	entity.get_tree().root.add_child(particles)
	particles.global_position = entity.global_position + Vector3(0, 0.5, 0)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
