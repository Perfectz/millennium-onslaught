## Canonical combat kill payload emitted when a hit finishes an entity.
class_name CombatKillEvent
extends RefCounted


const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION
var attacker: Node = null
var target: Node = null
var kill_position: Vector3 = Vector3.ZERO
var damage: float = 0.0
var attack_data: AttackDef = null


static func from_values(
	attacker_ref: Node,
	target_ref: Node,
	impact_position: Vector3,
	damage_amount: float,
	attack: AttackDef
) -> CombatKillEvent:
	var event := CombatKillEvent.new()
	event.attacker = attacker_ref
	event.target = target_ref
	event.kill_position = impact_position
	event.damage = damage_amount
	event.attack_data = attack
	return event


func to_debug_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"attacker_id": attacker.get_instance_id() if is_instance_valid(attacker) else -1,
		"target_id": target.get_instance_id() if is_instance_valid(target) else -1,
		"kill_position": kill_position,
		"damage": damage,
		"attack_name": attack_data.attack_name if attack_data else &"",
	}
