## Canonical combat hit payload shared across combat, UI, VFX, and audio.
class_name CombatHitEvent
extends RefCounted


const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION
var attacker: Node = null
var target: Node = null
var damage: float = 0.0
var hit_position: Vector3 = Vector3.ZERO
var attack_data: AttackDef = null


static func from_values(
	attacker_ref: Node,
	target_ref: Node,
	damage_amount: float,
	impact_position: Vector3,
	attack: AttackDef
) -> CombatHitEvent:
	var event := CombatHitEvent.new()
	event.attacker = attacker_ref
	event.target = target_ref
	event.damage = damage_amount
	event.hit_position = impact_position
	event.attack_data = attack
	return event


func to_debug_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"attacker_id": attacker.get_instance_id() if is_instance_valid(attacker) else -1,
		"target_id": target.get_instance_id() if is_instance_valid(target) else -1,
		"damage": damage,
		"hit_position": hit_position,
		"attack_name": attack_data.attack_name if attack_data else &"",
	}
