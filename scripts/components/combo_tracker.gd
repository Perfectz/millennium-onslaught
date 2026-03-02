## Pure logic combo step tracking. No scene tree dependency — fully testable.
## Tracks current step in a combo chain, manages input window timing.
class_name ComboTracker
extends RefCounted


signal combo_advanced(new_step: int)
signal combo_dropped()
signal combo_finished()

var _current_step: int = 0
var _max_steps: int
var _window_timer: float = 0.0
var _window_duration: float
var _is_in_window: bool = false


func _init(max_steps: int = 3, window_duration: float = -1.0) -> void:
	_max_steps = max_steps
	_window_duration = window_duration if window_duration > 0.0 else Constants.COMBO_INPUT_WINDOW


## Advance to the next combo step. Returns the new step index.
func advance_step() -> int:
	_current_step += 1
	if _current_step >= _max_steps:
		# Combo finished — reset
		combo_finished.emit()
		reset()
		return 0
	# Start the input window for the next step
	_window_timer = _window_duration
	_is_in_window = true
	combo_advanced.emit(_current_step)
	return _current_step


## Tick the combo window timer. Call every frame with delta.
func tick(delta: float) -> void:
	if not _is_in_window:
		return
	_window_timer -= delta
	if _window_timer <= 0.0:
		# Window expired — drop the combo
		_is_in_window = false
		combo_dropped.emit()
		reset()


## Get the current combo step (0-indexed).
func get_current_step() -> int:
	return _current_step


## Check if the combo input window is currently active.
func is_in_window() -> bool:
	return _is_in_window


## Reset the combo tracker to step 0.
func reset() -> void:
	_current_step = 0
	_window_timer = 0.0
	_is_in_window = false
