## Pure status effect tracking. No scene tree dependency — fully testable.
## Manages active status effects, their durations, and gameplay modifiers.
class_name StatusEffectTracker
extends RefCounted


signal effect_applied(effect_type: StringName, duration: float)
signal effect_expired(effect_type: StringName)

## Active effects: effect_type -> remaining_duration
var _effects: Dictionary = {}

## Stored values for buff effects: effect_type -> numeric value (e.g., defense bonus).
var _effect_values: Dictionary = {}


## Apply a status effect with a duration. Refreshes duration if already active.
## Optional value stores a numeric amount (used for buffs like defense_up).
func apply_effect(effect_type: StringName, duration: float, value: float = 0.0) -> void:
	_effects[effect_type] = duration
	if value != 0.0:
		_effect_values[effect_type] = value
	effect_applied.emit(effect_type, duration)


## Remove a status effect immediately.
func remove_effect(effect_type: StringName) -> void:
	_effects.erase(effect_type)
	_effect_values.erase(effect_type)


## Check if an effect is currently active.
func has_effect(effect_type: StringName) -> bool:
	return effect_type in _effects


## Tick all active effects. Returns total burn damage dealt this tick.
func tick(delta: float) -> float:
	var burn_damage: float = 0.0
	var expired: Array[StringName] = []
	for effect_type: StringName in _effects:
		_effects[effect_type] -= delta
		if _effects[effect_type] <= 0.0:
			expired.append(effect_type)
		elif effect_type == &"burn":
			burn_damage += Constants.BURN_DAMAGE_PER_SECOND * delta
	for effect_type: StringName in expired:
		_effects.erase(effect_type)
		_effect_values.erase(effect_type)
		effect_expired.emit(effect_type)
	return burn_damage


## Get movement speed multiplier (reduced by freeze).
func get_speed_multiplier() -> float:
	if has_effect(&"freeze"):
		return Constants.FREEZE_SPEED_REDUCTION
	return 1.0


## Get incoming damage multiplier (increased by bleed).
func get_damage_taken_multiplier() -> float:
	if has_effect(&"bleed"):
		return Constants.BLEED_DAMAGE_MULTIPLIER
	return 1.0


## Get defense bonus from active defense_up buff. Returns 0.0 if not active.
func get_defense_bonus() -> float:
	if has_effect(&"defense_up"):
		return _effect_values.get(&"defense_up", 0.0)
	return 0.0


## Clear all active effects without emitting signals.
func clear_all() -> void:
	_effects.clear()
	_effect_values.clear()
