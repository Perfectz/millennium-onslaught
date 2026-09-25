## Musou-style meter (themed on PSIV Combinations). Fills from hits, KOs and damage taken.
class_name CombinationGauge
extends RefCounted


signal changed(value: float, max_value: float)

var _value: float = 0.0
var _max: float = Constants.COMBINATION_GAUGE_MAX


## Add gauge. Non-positive amounts are ignored; clamps to max.
func add(amount: float) -> void:
	if amount <= 0.0:
		return
	var next := minf(_value + amount, _max)
	if is_equal_approx(next, _value):
		return
	_value = next
	changed.emit(_value, _max)


## Gauge gained when one of the player's attacks connects.
func register_hit() -> void:
	add(Constants.COMBINATION_GAIN_PER_HIT)


## Gauge gained per enemy knocked out.
func register_ko() -> void:
	add(Constants.COMBINATION_GAIN_PER_KO)


## Taking damage builds the gauge, so a losing fight can still turn.
func register_damage_taken(damage: float) -> void:
	add(damage * Constants.COMBINATION_GAIN_ON_DAMAGE_TAKEN_RATIO)


## Spend a full gauge. Returns false (and spends nothing) when not full.
func try_consume() -> bool:
	if not is_full():
		return false
	_value = 0.0
	changed.emit(_value, _max)
	return true


## True when the gauge can be spent.
func is_full() -> bool:
	return _value >= _max


## Current gauge value.
func get_value() -> float:
	return _value


## Gauge fill as 0..1.
func get_ratio() -> float:
	return _value / _max if _max > 0.0 else 0.0
