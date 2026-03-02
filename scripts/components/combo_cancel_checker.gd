## Pure logic cancel window checker. No scene tree dependency — fully testable.
## Checks if an attack can be cancelled at a given time into a given action.
class_name ComboCancelChecker
extends RefCounted


## Check if the attack's cancel window is active at the given elapsed time.
static func can_cancel(attack: AttackDef, elapsed_time: float) -> bool:
	var total_duration := attack.windup_time + attack.active_time + attack.recovery_time
	if total_duration <= 0.0:
		return attack.cancel_window_start <= 0.0
	var progress := clampf(elapsed_time / total_duration, 0.0, 1.0)
	return progress >= attack.cancel_window_start and progress <= attack.cancel_window_end


## Check if the attack allows cancelling into the given action type.
static func can_cancel_into(attack: AttackDef, action: StringName) -> bool:
	return action in attack.cancel_into


## Combined check: is the cancel window active AND is the action type allowed?
static func check(attack: AttackDef, elapsed_time: float, action: StringName) -> bool:
	return can_cancel(attack, elapsed_time) and can_cancel_into(attack, action)
