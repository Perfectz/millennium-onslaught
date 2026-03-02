## Damage receiver area. Supports invincibility frames.
## Emits hit_received when a valid hit is received.
class_name Hurtbox
extends Area3D


signal hit_received(attack_data: AttackDef, attacker: Node3D)

var is_invincible: bool = false


## Process an incoming hit. Ignored while invincible.
func receive_hit(data: AttackDef, attacker: Node3D) -> void:
	if is_invincible:
		return
	if data == null:
		push_warning("Hurtbox: receive_hit called with null attack data.")
		return
	hit_received.emit(data, attacker)
