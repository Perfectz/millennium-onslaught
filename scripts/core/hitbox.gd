## Attack collision area with belt-depth (Z) tolerance.
## Enable with AttackDef data, auto-tracks which targets were already hit.
class_name Hitbox
extends Area3D


var attack_data: AttackDef = null
var _hit_targets: Array[Area3D] = []
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	disable()


## Activate the hitbox with attack data. Positions shape based on facing.
func enable(data: AttackDef, face_right: bool = true) -> void:
	attack_data = data
	_hit_targets.clear()
	_collision_shape.position.x = Constants.HITBOX_X_OFFSET if face_right else -Constants.HITBOX_X_OFFSET
	_collision_shape.disabled = false
	monitoring = true


## Deactivate the hitbox and clear tracked targets.
func disable() -> void:
	_collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	attack_data = null
	_hit_targets.clear()


func _on_area_entered(area: Area3D) -> void:
	if attack_data == null:
		return
	if not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox in _hit_targets:
		return
	if not _z_check(hurtbox):
		return
	_hit_targets.append(hurtbox)
	hurtbox.receive_hit(attack_data, get_parent())


## Check if the hit target is within belt-depth tolerance.
func _z_check(hurtbox: Hurtbox) -> bool:
	var z_diff := absf(global_position.z - hurtbox.global_position.z)
	return z_diff <= Constants.Z_HIT_TOLERANCE
