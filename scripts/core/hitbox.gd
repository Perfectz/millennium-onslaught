## Attack collision area with radial offset based on facing angle.
## Enable with AttackDef data, auto-tracks which targets were already hit.
class_name Hitbox
extends Area3D


var attack_data: AttackDef = null
var _hit_targets: Array[Hurtbox] = []
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	disable()


## Activate the hitbox with attack data. Positions shape radially based on facing angle.
func enable(data: AttackDef, facing_angle: float = 0.0) -> void:
	attack_data = data
	_hit_targets.clear()
	_collision_shape.position.x = cos(facing_angle) * Constants.HITBOX_OFFSET_DISTANCE
	_collision_shape.position.z = -sin(facing_angle) * Constants.HITBOX_OFFSET_DISTANCE
	_collision_shape.disabled = false
	monitoring = true
	call_deferred("_process_overlap_hits")


## Deactivate the hitbox and clear tracked targets.
func disable() -> void:
	_collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	attack_data = null
	_hit_targets.clear()


func _on_area_entered(area: Area3D) -> void:
	_try_apply_hit(area)


func _physics_process(_delta: float) -> void:
	if attack_data == null or not monitoring:
		return
	_process_overlap_hits()


func _process_overlap_hits() -> void:
	if attack_data == null or not monitoring:
		return
	for area in get_overlapping_areas():
		_try_apply_hit(area)


func _try_apply_hit(area: Area3D) -> void:
	if attack_data == null:
		return
	if not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox in _hit_targets:
		return
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	_hit_targets.append(hurtbox)
	hurtbox.receive_hit(attack_data, parent)
