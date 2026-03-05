## Spawns VFX particles and hit sparks on combat events. Uses ObjectPool for recycling.
class_name VFXSystem
extends Node


const HitParticlesScene := preload("res://scenes/vfx/hit_particles.tscn")
const DeathParticlesScene := preload("res://scenes/vfx/death_particles.tscn")
const HitSparkScene := preload("res://scenes/vfx/hit_spark.tscn")
const ImpactDecalScene := preload("res://scenes/vfx/impact_decal.tscn")

const POOL_HIT: StringName = &"vfx_hit"
const POOL_DEATH: StringName = &"vfx_death"
const POOL_SPARK: StringName = &"vfx_spark"
const POOL_DECAL: StringName = &"vfx_decal"


func _ready() -> void:
	ObjectPool.warm_pool(HitParticlesScene, 8, POOL_HIT)
	ObjectPool.warm_pool(DeathParticlesScene, 4, POOL_DEATH)
	ObjectPool.warm_pool(HitSparkScene, Constants.HIT_SPARK_POOL_SIZE, POOL_SPARK)
	ObjectPool.warm_pool(ImpactDecalScene, 6, POOL_DECAL)
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)


func _on_hit_landed(attacker: Node, target: Node, damage: float, pos: Vector3, attack_data: AttackDef) -> void:
	var element: StringName = &""
	if attack_data:
		element = attack_data.element_type
	var color := _get_element_color(element)

	# --- Hit particles ---
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
	process_material.color = color

	# Tint the draw material emission to match element.
	var draw_mat := particles.material_override as StandardMaterial3D
	if draw_mat:
		if not particles.has_meta(&"unique_draw_material"):
			draw_mat = draw_mat.duplicate() as StandardMaterial3D
			particles.material_override = draw_mat
			particles.set_meta(&"unique_draw_material", true)
		draw_mat.albedo_color = color
		draw_mat.emission = color

	particles.amount = Constants.DEATH_PARTICLE_COUNT if heavy_hit else Constants.HIT_PARTICLE_COUNT
	particles.global_position = pos
	particles.emitting = true

	if particles.has_meta(&"pool_key"):
		particles.finished.connect(func() -> void:
			particles.emitting = false
			ObjectPool.return_instance(particles)
		, CONNECT_ONE_SHOT)

	# --- Hit spark billboard ---
	_spawn_hit_spark(pos, color, heavy_hit)

	# --- Impact decal on heavy hits ---
	if heavy_hit:
		_spawn_impact_decal(pos, color)


func _on_kill(_attacker: Node, _target: Node, pos: Vector3) -> void:
	_spawn_particles(POOL_DEATH, DeathParticlesScene, pos)
	_spawn_impact_decal(pos, Color(0.3, 0.1, 0.05))


## Spawn a billboard hit spark at the impact point with scale-up + fade-out.
func _spawn_hit_spark(pos: Vector3, color: Color, heavy: bool) -> void:
	var spark: MeshInstance3D = ObjectPool.get_instance(POOL_SPARK) as MeshInstance3D
	var pooled := true
	if spark == null:
		spark = HitSparkScene.instantiate() as MeshInstance3D
		get_tree().root.add_child(spark)
		pooled = false

	spark.global_position = pos
	# Random rotation for visual variety.
	spark.rotation.z = randf() * TAU

	# Tint to element color.
	var mat := spark.material_override as StandardMaterial3D
	if mat:
		if not spark.has_meta(&"unique_spark_material"):
			mat = mat.duplicate() as StandardMaterial3D
			spark.material_override = mat
			spark.set_meta(&"unique_spark_material", true)
		mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
		mat.emission = color

	var start_scale := 1.5 if heavy else 1.0
	var end_scale := 2.5 if heavy else 1.8
	spark.scale = Vector3(start_scale, start_scale, start_scale)
	spark.visible = true

	var tween := spark.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector3(end_scale, end_scale, end_scale), Constants.HIT_SPARK_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if mat:
		tween.tween_property(mat, "albedo_color:a", 0.0, Constants.HIT_SPARK_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		spark.visible = false
		if pooled:
			ObjectPool.return_instance(spark)
		else:
			spark.queue_free()
	)


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


## Get the VFX color for an element type.
func _get_element_color(element: StringName) -> Color:
	return Constants.ELEMENT_COLORS.get(element, Constants.ELEMENT_COLORS[&""])


## Spawn a ground-level impact decal at the given position with fade-out.
func _spawn_impact_decal(pos: Vector3, color: Color) -> void:
	var decal: MeshInstance3D = ObjectPool.get_instance(POOL_DECAL) as MeshInstance3D
	var pooled := true
	if decal == null:
		decal = ImpactDecalScene.instantiate() as MeshInstance3D
		get_tree().root.add_child(decal)
		pooled = false

	decal.global_position = Vector3(pos.x, 0.02, pos.z)
	decal.rotation.y = randf() * TAU

	var mat := decal.material_override as StandardMaterial3D
	if mat:
		if not decal.has_meta(&"unique_decal_material"):
			mat = mat.duplicate() as StandardMaterial3D
			decal.material_override = mat
			decal.set_meta(&"unique_decal_material", true)
		mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
		mat.emission = color * 0.5

	decal.scale = Vector3(0.3, 1.0, 0.3)
	decal.visible = true

	var tween := decal.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(decal, "scale", Vector3(1.2, 1.0, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	if mat:
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween.tween_interval(0.8)
	tween.tween_callback(func() -> void:
		decal.visible = false
		if pooled:
			ObjectPool.return_instance(decal)
		else:
			decal.queue_free()
	)


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
