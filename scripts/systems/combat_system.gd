## Static combat utility. Calculates damage, applies it, and emits EventBus signals.
class_name CombatSystem
extends RefCounted


static func process_hit(
	target_health: HealthComponent,
	attack_data: AttackDef,
	attacker: Node3D,
	target: Node3D,
	defense: float = 0.0
) -> float:
	var damage := DamageCalculator.calculate(
		attack_data.base_damage,
		attack_data.damage_multiplier,
		defense
	)
	target_health.take_damage(damage)

	EventBus.combat_hit_landed.emit(attacker, target, damage, target.global_position)

	if target_health.is_dead():
		EventBus.combat_kill.emit(attacker, target, target.global_position)

	return damage
