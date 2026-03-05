## Tracks combo step progression, input windows, and combo drops.
class_name ComboTracker
extends Node


signal combo_advanced(step: int)
signal combo_dropped()
signal combo_finished()

## Maximum steps in the combo chain.
var _max_steps: int = 3

## Current step (0 = no combo active).
var _current_step: int = 0

## Time remaining in the current input window.
var _window_timer: float = 0.0

## Whether we're currently in an input window.
var _in_window: bool = false

## Whether the combo chain is complete (final hit landed).
var _finished: bool = false


## Initialize the combo tracker with chain length.
func setup(max_steps: int) -> void:
	_max_steps = max_steps
	reset()


## Attempt to advance the combo. Returns true if successful.
func try_advance() -> bool:
	if _finished:
		return false
	if _current_step == 0:
		# Start combo.
		_current_step = 1
		_start_window()
		combo_advanced.emit(_current_step)
		return true
	if _in_window:
		_current_step += 1
		if _current_step >= _max_steps:
			_finished = true
			_in_window = false
			_window_timer = 0.0
			combo_advanced.emit(_current_step)
			combo_finished.emit()
		else:
			_start_window()
			combo_advanced.emit(_current_step)
		return true
	return false


## Open the input window (called when attack animation reaches cancel point).
func open_window() -> void:
	if _current_step > 0 and not _finished:
		_start_window()


## Process combo timing.
func process_combo(delta: float) -> void:
	if not _in_window:
		return
	_window_timer -= delta
	if _window_timer <= 0.0:
		_drop_combo()


## Reset the combo to idle.
func reset() -> void:
	_current_step = 0
	_window_timer = 0.0
	_in_window = false
	_finished = false


## Get the current combo step.
func get_current_step() -> int:
	return _current_step


## Check if combo is active.
func is_active() -> bool:
	return _current_step > 0 and not _finished


## Check if combo finished the full chain.
func is_finished() -> bool:
	return _finished


## Check if currently in an input window.
func is_in_window() -> bool:
	return _in_window


func _start_window() -> void:
	_in_window = true
	_window_timer = Constants.COMBO_INPUT_WINDOW


func _drop_combo() -> void:
	_in_window = false
	_window_timer = 0.0
	var was_active: bool = _current_step > 0
	_current_step = 0
	_finished = false
	if was_active:
		combo_dropped.emit()
