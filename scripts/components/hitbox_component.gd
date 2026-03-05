## Attack collision area. Active when an attack is in progress.
class_name HitboxComponent
extends Area3D


signal hit_detected(hurtbox: HurtboxComponent)

## Damage value for the current attack.
var _damage: float = 0.0

## Knockback force for the current attack.
var _knockback: float = 0.0

## Whether this hitbox is currently active.
var _active: bool = false

## Track what we've already hit this swing to prevent multi-hit.
var _hit_targets: Array[int] = []

## Owner reference for attacker identification.
var _owner_node: Node = null


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


## Activate the hitbox for an attack.
func activate(damage: float, knockback: float, owner_node: Node) -> void:
	_damage = damage
	_knockback = knockback
	_owner_node = owner_node
	_active = true
	_hit_targets.clear()
	monitoring = true


## Deactivate the hitbox.
func deactivate() -> void:
	_active = false
	monitoring = false
	_hit_targets.clear()


## Get the current damage value.
func get_damage() -> float:
	return _damage


## Get the knockback force.
func get_knockback() -> float:
	return _knockback


## Get the attacking node.
func get_owner_node() -> Node:
	return _owner_node


func _on_area_entered(area: Area3D) -> void:
	if not _active:
		return
	if area is HurtboxComponent:
		var hurtbox: HurtboxComponent = area as HurtboxComponent
		var target_id: int = hurtbox.get_instance_id()
		if target_id in _hit_targets:
			return
		# Z-depth tolerance check for belt-scroller.
		var z_diff: float = absf(global_position.z - hurtbox.global_position.z)
		if z_diff > Constants.Z_HIT_TOLERANCE:
			return
		_hit_targets.append(target_id)
		hit_detected.emit(hurtbox)
