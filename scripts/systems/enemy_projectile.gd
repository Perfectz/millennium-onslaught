## Enemy projectile — moves in a direction, damages player on contact.
class_name EnemyProjectile
extends Area3D


var _direction: Vector3 = Vector3.RIGHT
var _speed: float = 10.0
var _damage: float = 8.0
var _lifetime: float = 3.0
var _timer: float = 0.0
var _attack_data: AttackDef


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_attack_data = AttackDef.new()
	_attack_data.attack_name = &"projectile"
	_attack_data.base_damage = _damage
	_attack_data.knockback_force = 2.0
	_attack_data.knockback_direction = _direction


## Configure projectile direction, speed, and damage.
func setup(direction: Vector3, speed: float, damage: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	_timer = 0.0
	_attack_data.base_damage = _damage
	_attack_data.knockback_direction = _direction


func _physics_process(delta: float) -> void:
	delta = minf(delta, Constants.DELTA_CAP)
	_timer += delta
	if _timer >= _lifetime:
		queue_free()
		return
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		# Only hit player hurtboxes (check parent isn't an enemy).
		if hurtbox.get_parent() is EnemyController:
			return
		hurtbox.receive_hit(_attack_data, self)
		queue_free()


func _on_body_entered(_body: Node3D) -> void:
	# Hit a wall — destroy.
	queue_free()
