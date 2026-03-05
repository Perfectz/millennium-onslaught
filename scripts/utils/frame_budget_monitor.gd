## Tracks per-system frame time and warns when budget is exceeded.
## Attach to any node to start monitoring. Results visible in debug overlay (F4).
class_name FrameBudgetMonitor
extends Node


## Maximum time budget per system per frame (milliseconds).
const BUDGET_WARNING_MS: float = 4.0

## Maximum total frame time before warning (milliseconds).
const TOTAL_BUDGET_MS: float = 16.67  # 60fps target.

## Per-system timing records.
var _system_timers: Dictionary = {}

## Current frame's system times.
var _current_frame_times: Dictionary = {}

## Rolling average window.
var _history: Array[Dictionary] = []
const HISTORY_SIZE: int = 60

## Whether monitoring is active.
var _active: bool = false

## Accumulated warnings.
var _warnings: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if not _active:
		return
	_record_frame()
	_current_frame_times.clear()


## Enable or disable monitoring.
func set_active(active: bool) -> void:
	_active = active
	if not active:
		_history.clear()
		_current_frame_times.clear()
		_warnings.clear()


## Start timing a named system.
func begin_system(system_name: StringName) -> void:
	if not _active:
		return
	_system_timers[system_name] = Time.get_ticks_usec()


## End timing a named system.
func end_system(system_name: StringName) -> void:
	if not _active:
		return
	if system_name not in _system_timers:
		return
	var start: int = _system_timers[system_name]
	var elapsed_us: int = Time.get_ticks_usec() - start
	var elapsed_ms: float = float(elapsed_us) / 1000.0
	_current_frame_times[system_name] = elapsed_ms
	if elapsed_ms > BUDGET_WARNING_MS:
		var warning: String = "BUDGET: %s took %.2fms (limit: %.2fms)" % [
			str(system_name), elapsed_ms, BUDGET_WARNING_MS
		]
		_warnings.append(warning)
		push_warning(warning)


## Get the latest frame's system times.
func get_last_frame_times() -> Dictionary:
	if _history.is_empty():
		return {}
	return _history[_history.size() - 1]


## Get average time for a system over the history window.
func get_average_time(system_name: StringName) -> float:
	var total: float = 0.0
	var count: int = 0
	for frame: Dictionary in _history:
		if system_name in frame:
			total += frame[system_name]
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)


## Get all recent warnings.
func get_warnings() -> Array[String]:
	return _warnings


## Clear accumulated warnings.
func clear_warnings() -> void:
	_warnings.clear()


## Get a formatted report string.
func get_report() -> String:
	var report: String = "=== Frame Budget Report ===\n"
	var all_systems: Dictionary = {}
	for frame: Dictionary in _history:
		for sys: StringName in frame:
			if sys not in all_systems:
				all_systems[sys] = 0.0
	for sys: StringName in all_systems:
		var avg: float = get_average_time(sys)
		var status: String = "OK" if avg < BUDGET_WARNING_MS else "OVER"
		report += "  %s: %.2fms avg [%s]\n" % [str(sys), avg, status]
	report += "  Warnings: %d\n" % _warnings.size()
	return report


func _record_frame() -> void:
	if _current_frame_times.is_empty():
		return
	_history.append(_current_frame_times.duplicate())
	if _history.size() > HISTORY_SIZE:
		_history.pop_front()
