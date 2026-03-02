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
