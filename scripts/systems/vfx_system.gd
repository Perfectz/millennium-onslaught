## Spawns VFX particles on combat events. Uses ObjectPool for recycling.
class_name VFXSystem
extends Node


const HitParticlesScene := preload("res://scenes/vfx/hit_particles.tscn")
const DeathParticlesScene := preload("res://scenes/vfx/death_particles.tscn")

const POOL_HIT: StringName = &"vfx_hit"
const POOL_DEATH: StringName = &"vfx_death"


func _ready() -> void:
	ObjectPool.warm_pool(HitParticlesScene, 8, POOL_HIT)
	ObjectPool.warm_pool(DeathParticlesScene, 4, POOL_DEATH)
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)


func _on_hit_landed(attacker: Node, target: Node, damage: float, pos: Vector3, attack_data: AttackDef) -> void:
	var particles: GPUParticles3D = ObjectPool.get_instance(POOL_HIT) as GPUParticles3D
	if particles == null:
		particles = HitParticlesScene.instantiate() as GPUParticles3D
		get_tree().root.add_child(particles)
		particles.finished.connect(particles.queue_free)

	var direction := Vector3(0, 1, 0)
	if attacker is Node3D and target is Node3D:
		direction = ((target as Node3D).global_position - (attacker as Node3D).global_position).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector3(0, 1, 0)

	var process_material := _ensure_unique_process_material(particles)
	var heavy_hit := damage >= Constants.HEAVY_ATTACK_DAMAGE or (attack_data and attack_data.attack_name == &"heavy")
	process_material.direction = direction
	process_material.spread = 35.0 if heavy_hit else 22.0
	process_material.initial_velocity_min = 4.0 if heavy_hit else 2.5
	process_material.initial_velocity_max = 8.0 if heavy_hit else 5.0

	particles.amount = Constants.DEATH_PARTICLE_COUNT if heavy_hit else Constants.HIT_PARTICLE_COUNT
	particles.global_position = pos
	particles.emitting = true

	if particles.has_meta(&"pool_key"):
		particles.finished.connect(func() -> void:
			particles.emitting = false
			ObjectPool.return_instance(particles)
		, CONNECT_ONE_SHOT)


func _on_kill(_attacker: Node, _target: Node, pos: Vector3) -> void:
	_spawn_particles(POOL_DEATH, DeathParticlesScene, pos)


func _spawn_particles(pool_name: StringName, fallback_scene: PackedScene, pos: Vector3) -> void:
	var particles: GPUParticles3D = ObjectPool.get_instance(pool_name) as GPUParticles3D
	if particles == null:
		# Pool exhausted — instantiate as fallback.
		particles = fallback_scene.instantiate() as GPUParticles3D
		get_tree().root.add_child(particles)
		particles.finished.connect(particles.queue_free)
	particles.global_position = pos
	particles.emitting = true
	# Return pooled particles after emission completes.
	if particles.has_meta(&"pool_key"):
		particles.finished.connect(func() -> void:
			particles.emitting = false
			ObjectPool.return_instance(particles)
		, CONNECT_ONE_SHOT)


func _ensure_unique_process_material(particles: GPUParticles3D) -> ParticleProcessMaterial:
	var process_material := particles.process_material as ParticleProcessMaterial
	if process_material == null:
		process_material = ParticleProcessMaterial.new()
		particles.process_material = process_material
		return process_material
	if not particles.has_meta(&"unique_process_material"):
		process_material = process_material.duplicate() as ParticleProcessMaterial
		particles.process_material = process_material
		particles.set_meta(&"unique_process_material", true)
	return process_material
