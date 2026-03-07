## Pure helpers for player parry/block response, damage context, and knockback.
class_name PlayerHitPolicy
extends RefCounted


static func build_damage_context(derived_stats: Dictionary, damage_taken_multiplier: float) -> Dictionary:
	return {
		"defense": StatCalculator.defense_value(StatCalculator.get_stat(derived_stats, &"defense")),
		"damage_taken_multiplier": damage_taken_multiplier,
	}


static func resolve_hit_response(
	attack_data: AttackDef,
	attacker_position: Vector3,
	target_position: Vector3,
	facing_direction: Vector3,
	parry_active: bool,
	blocking: bool,
	block_damage_reduction: float,
	block_knockback_scale: float,
	knockback_z_dampen: float
) -> Dictionary:
	if parry_active:
		return {
			"outcome": &"parry",
			"blocked": false,
			"resolved_attack": attack_data,
			"knockback_velocity": Vector3.ZERO,
		}

	var resolved_attack := attack_data
	if blocking:
		resolved_attack = attack_data.duplicate(true) as AttackDef
		resolved_attack.damage_multiplier *= maxf(1.0 - block_damage_reduction, 0.0)
		resolved_attack.knockback_force *= maxf(block_knockback_scale, 0.0)

	var push_dir := target_position - attacker_position
	push_dir.y = 0.0
	if push_dir.length_squared() < 0.001:
		push_dir = -facing_direction
	push_dir = push_dir.normalized()

	var kb_force := resolved_attack.knockback_force
	return {
		"outcome": &"blocked" if blocking else &"hit",
		"blocked": blocking,
		"resolved_attack": resolved_attack,
		"knockback_velocity": Vector3(
			push_dir.x * kb_force,
			0.0,
			push_dir.z * kb_force * knockback_z_dampen
		),
	}
