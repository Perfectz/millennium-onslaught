## Player projectile — energy bolt that moves forward, damages enemies on contact.
## Spawns impact particles on hit or lifetime expiry.
class_name PlayerProjectile
extends Area3D


var _direction: Vector3 = Vector3.RIGHT
var _speed: float = 18.0
var _lifetime: float = 2.5
var _timer: float = 0.0
var _attack_data: AttackDef
var _owner_ref: Node3D = null
var _destroyed: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_attack_data = AttackDef.new()
	_attack_data.attack_name = &"projectile"
	_attack_data.base_damage = Constants.PLAYER_PROJECTILE_DAMAGE
	_attack_data.knockback_force = Constants.PLAYER_PROJECTILE_KNOCKBACK
	_attack_data.knockback_direction = _direction
	_attack_data.hitstop_duration = Constants.PLAYER_PROJECTILE_HITSTOP


## Configure projectile direction, speed, and owner reference.
func setup(direction: Vector3, speed: float, owner_ref: Node3D) -> void:
	_direction = direction.normalized()
	_speed = speed
	_owner_ref = owner_ref
	_timer = 0.0
	_attack_data.knockback_direction = _direction
	# Enable collision detection after positioning.
	monitoring = true


func _physics_process(delta: float) -> void:
	if _destroyed:
		return
	delta = minf(delta, Constants.DELTA_CAP)
	_timer += delta
	if _timer >= _lifetime:
		_destroy()
		return
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area3D) -> void:
	if _destroyed:
		return
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		# Don't hit the player who fired this.
		if _owner_ref and hurtbox.get_parent() == _owner_ref:
			return
		var attacker := _owner_ref if _owner_ref else self
		hurtbox.receive_hit(_attack_data, attacker)
		_destroy()


func _destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	_spawn_impact_particles()
	queue_free()


## Spawn a one-shot burst of cyan particles at the impact point.
func _spawn_impact_particles() -> void:
	var burst := GPUParticles3D.new()
	burst.amount = 16
	burst.lifetime = 0.4
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, -5, 0)
	mat.scale_min = 0.06
	mat.scale_max = 0.2
	mat.color = Color(0.3, 0.85, 1.0, 1.0)
	burst.process_material = mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.3, 0.85, 1.0, 1.0)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.2, 0.7, 1.0, 1.0)
	draw_mat.emission_energy_multiplier = 3.0
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	mesh.material = draw_mat
	burst.draw_pass_1 = mesh

	burst.global_position = global_position
	get_tree().root.add_child(burst)
	burst.finished.connect(burst.queue_free)
