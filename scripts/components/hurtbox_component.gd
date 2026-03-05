## Damage receiving area. Always active when the entity can be hit.
class_name HurtboxComponent
extends Area3D


signal damage_received(amount: float, attacker: Node, hit_position: Vector3)

## Reference to the owning entity's health component.
var _health: HealthComponent = null

## Whether this hurtbox is currently invincible (dodge frames, etc.).
var _invincible: bool = false

## Owner node for target identification.
var _owner_node: Node = null


func _ready() -> void:
	monitoring = false
	monitorable = true


## Set up the hurtbox with its health component and owner.
func setup(health: HealthComponent, owner_node: Node) -> void:
	_health = health
	_owner_node = owner_node


## Set invincibility state (for dodge, revive, etc.).
func set_invincible(invincible: bool) -> void:
	_invincible = invincible


## Check if currently invincible.
func is_invincible() -> bool:
	return _invincible


## Get the owner node.
func get_owner_node() -> Node:
	return _owner_node


## Receive a hit from a hitbox. Returns true if damage was applied.
func receive_hit(hitbox: HitboxComponent) -> bool:
	if _invincible:
		return false
	if _health == null:
		return false
	if _health.is_dead():
		return false
	var damage: float = hitbox.get_damage()
	var attacker: Node = hitbox.get_owner_node()
	var hit_pos: Vector3 = global_position
	_health.take_damage(damage)
	damage_received.emit(damage, attacker, hit_pos)
	return true
