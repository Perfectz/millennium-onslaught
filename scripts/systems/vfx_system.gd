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


func _on_hit_landed(_attacker: Node, _target: Node, _damage: float, pos: Vector3) -> void:
	_spawn_particles(POOL_HIT, HitParticlesScene, pos)


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
