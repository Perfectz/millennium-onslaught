## Pure elemental damage logic. No scene tree dependency — fully testable.
## Computes elemental multipliers and maps elements to status effects.
class_name ElementCalculator
extends RefCounted


## Calculate elemental damage multiplier.
## Returns ELEMENT_WEAKNESS_MULTIPLIER if target is weak, ELEMENT_RESISTANCE_MULTIPLIER if resistant, else 1.0.
static func get_multiplier(attack_element: StringName, target_weakness: StringName, target_resistance: StringName) -> float:
	if attack_element == &"":
		return 1.0
	if target_weakness == attack_element:
		return Constants.ELEMENT_WEAKNESS_MULTIPLIER
	if target_resistance == attack_element:
		return Constants.ELEMENT_RESISTANCE_MULTIPLIER
	return 1.0


## Roll whether a status effect procs based on chance (0.0 to 1.0).
static func roll_status_effect(chance: float) -> bool:
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	return randf() < chance


## Get the status effect type associated with an element.
static func get_status_for_element(element: StringName) -> StringName:
	match element:
		&"fire": return &"burn"
		&"ice": return &"freeze"
		&"lightning": return &"shock"
		&"dark": return &"bleed"
		_: return &""
