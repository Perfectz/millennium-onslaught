## Environmental throwable object — player can pick up and throw at enemies.
## When thrown, becomes a projectile that deals damage on impact.
class_name ThrowableObject
extends StaticBody3D


## Visual mesh for the throwable.
@export var mesh_instance: MeshInstance3D = null

## Whether this throwable has already been picked up.
var _picked_up: bool = false

## The player who threw this (for projectile ownership).
var _thrower: Node3D = null


func _ready() -> void:
	collision_layer = Constants.LAYER_ENVIRONMENT
	collision_mask = 0
	# Create a simple box mesh if none assigned.
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.6, 0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.4, 0.2)
		mesh_instance.mesh = box
		mesh_instance.set_surface_override_material(0, mat)
		add_child(mesh_instance)
	# Create collision shape.
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)


## Check if the player is within interact range.
func is_in_range(player_pos: Vector3) -> bool:
	var my_pos := global_position if is_inside_tree() else position
	return my_pos.distance_to(player_pos) <= Constants.THROWABLE_INTERACT_RANGE


## Check if this throwable has been picked up.
func is_picked_up() -> bool:
	return _picked_up


## Throw this object in the given direction. Converts to a projectile.
func throw_towards(direction: float, thrower: Node3D) -> void:
	if _picked_up:
		return
	_picked_up = true
	_thrower = thrower

	# Convert to kinematic projectile behavior.
	# Spawn a projectile-like Area3D at this position, then free the static body.
	var projectile := ThrowableProjectile.new()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.thrower = thrower
	get_parent().add_child(projectile)

	queue_free()


## ThrowableProjectile — kinematic projectile spawned when a throwable is thrown.
class ThrowableProjectile extends Area3D:
	var direction: float = 1.0
	var thrower: Node3D = null
	var _lifetime: float = 0.0
	var _mesh: MeshInstance3D = null
	var _has_hit: bool = false

	func _ready() -> void:
		collision_layer = Constants.LAYER_PLAYER_HITBOX
		collision_mask = Constants.LAYER_ENEMY_HURTBOX
		monitoring = true
		monitorable = false

		# Visual.
		_mesh = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.6, 0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.4, 0.2)
		_mesh.mesh = box
		_mesh.set_surface_override_material(0, mat)
		add_child(_mesh)

		# Collision shape.
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.6, 0.6, 0.6)
		var col := CollisionShape3D.new()
		col.shape = shape
		add_child(col)

		area_entered.connect(_on_area_entered)

	func _physics_process(delta: float) -> void:
		if _has_hit:
			return
		position.x += direction * Constants.THROWABLE_SPEED * delta
		_lifetime += delta
		if _lifetime >= Constants.THROWABLE_LIFETIME:
			queue_free()

	func _on_area_entered(area: Area3D) -> void:
		if _has_hit:
			return
		if area is Hurtbox:
			_has_hit = true
			var hurtbox := area as Hurtbox
			var attack_data := {
				"damage": Constants.THROWABLE_DAMAGE,
				"knockback": Vector3(direction * Constants.THROWABLE_KNOCKBACK, 2.0, 0.0),
				"hitstop_duration": Constants.THROWABLE_HITSTOP,
				"attack_type": &"throwable",
			}
			hurtbox.hit_received.emit(attack_data, thrower)
			queue_free()
