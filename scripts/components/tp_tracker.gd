## Technique Points tracker. Manages TP pool — regen over time, gain on events, spend on techniques.
class_name TPTracker
extends RefCounted


signal tp_changed(current_tp: float, max_tp: float)
signal tp_spent(amount: float)

var _max_tp: float = Constants.TP_MAX
var _current_tp: float = 0.0


## Get current TP.
func get_current_tp() -> float:
	return _current_tp


## Get max TP.
func get_max_tp() -> float:
	return _max_tp


## Add TP (clamped to max). Ignores non-positive values.
func add_tp(amount: float) -> void:
	if amount <= 0.0:
		return
	_current_tp = minf(_current_tp + amount, _max_tp)
	tp_changed.emit(_current_tp, _max_tp)


## Spend TP. Returns true if successful, false if insufficient.
func spend_tp(amount: float) -> bool:
	if amount <= 0.0:
		return false
	if _current_tp < amount:
		return false
	_current_tp -= amount
	tp_spent.emit(amount)
	tp_changed.emit(_current_tp, _max_tp)
	return true


## Regen TP over time. Call with physics delta.
func tick_regen(delta: float) -> void:
	if _current_tp >= _max_tp:
		return
	_current_tp = minf(_current_tp + Constants.TP_REGEN_RATE * delta, _max_tp)
	tp_changed.emit(_current_tp, _max_tp)


## Reset TP to zero.
func reset() -> void:
	_current_tp = 0.0
	tp_changed.emit(_current_tp, _max_tp)
