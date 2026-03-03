## Static combat utility. Calculates damage, applies it, and emits EventBus signals.
class_name CombatSystem
extends RefCounted


## Process a hit with optional RPG stat integration.
## Backward compatible — extra params default to neutral values.
static func process_hit(
	target_health: HealthComponent,
	attack_data: AttackDef,
	attacker: Node3D,
	target: Node3D,
	defense: float = 0.0,
	attacker_stat: int = 0,
	stat_scale: float = 0.0,
	element_multiplier: float = 1.0,
	damage_taken_multiplier: float = 1.0,
) -> float:
	var damage: float
	if attacker_stat > 0 or element_multiplier != 1.0 or damage_taken_multiplier != 1.0:
		damage = DamageCalculator.calculate_full(
			attack_data.base_damage,
			attack_data.damage_multiplier,
			attacker_stat,
			stat_scale,
			defense,
			element_multiplier,
			damage_taken_multiplier,
		)
	else:
		damage = DamageCalculator.calculate(
			attack_data.base_damage,
			attack_data.damage_multiplier,
			defense
		)
	target_health.take_damage(damage)

	EventBus.combat_hit_landed.emit(attacker, target, damage, target.global_position, attack_data)

	if target_health.is_dead():
		EventBus.combat_kill.emit(attacker, target, target.global_position)

	return damage


## Roll and apply elemental status effect from an attack if applicable.
static func apply_status_if_applicable(
	attack_data: AttackDef,
	target: Node3D,
	target_effects: StatusEffectTracker,
) -> void:
	if attack_data.element_type == &"":
		return
	if attack_data.status_effect_chance <= 0.0:
		return
	if not ElementCalculator.roll_status_effect(attack_data.status_effect_chance):
		return
	var effect := ElementCalculator.get_status_for_element(attack_data.element_type)
	if effect == &"":
		return
	target_effects.apply_effect(effect, attack_data.status_effect_duration)
	EventBus.rpg_status_effect_applied.emit(target, effect, attack_data.status_effect_duration)
