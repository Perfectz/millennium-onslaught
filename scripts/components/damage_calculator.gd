## Pure damage calculation. No scene tree dependency — fully testable.
## Calculates final damage from base, multiplier, and defense.
class_name DamageCalculator
extends RefCounted


## Calculate final damage: (base * multiplier) - defense, minimum 1 chip damage.
## Returns 0 only if base damage is 0.
static func calculate(base_damage: float, multiplier: float = 1.0, defense: float = 0.0) -> float:
	if base_damage <= 0.0:
		return 0.0
	var raw := base_damage * multiplier
	var final_damage := maxf(raw - defense, 1.0)
	return final_damage


## Calculate damage with full RPG stat integration.
## Applies attacker stat scaling, elemental multiplier, and damage-taken multiplier.
static func calculate_full(
	base_damage: float,
	multiplier: float,
	attacker_stat: int,
	stat_scale: float,
	defense: float,
	element_multiplier: float = 1.0,
	damage_taken_multiplier: float = 1.0,
) -> float:
	if base_damage <= 0.0:
		return 0.0
	var stat_bonus := attacker_stat * stat_scale
	var raw := (base_damage + stat_bonus) * multiplier * element_multiplier * damage_taken_multiplier
	return maxf(raw - defense, 1.0)
