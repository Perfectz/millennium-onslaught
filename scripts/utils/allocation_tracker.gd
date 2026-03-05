## Debug tool to detect per-frame allocations in hot paths.
## Enable in debug builds to find and fix allocation-heavy code.
class_name AllocationTracker
extends Node


## Tracked allocation sites.
var _allocation_sites: Dictionary = {}

## Whether tracking is active.
var _active: bool = false

## Frame counter for per-frame detection.
var _frame_count: int = 0


func _process(_delta: float) -> void:
	if not _active:
		return
	_frame_count += 1


## Enable or disable tracking.
func set_active(active: bool) -> void:
	_active = active
	if not active:
		_allocation_sites.clear()
		_frame_count = 0


## Register an allocation at a named site.
## Call this where allocations happen to track frequency.
func track_allocation(site_name: StringName) -> void:
	if not _active:
		return
	if site_name not in _allocation_sites:
		_allocation_sites[site_name] = {
			"count": 0,
			"frames": [],
		}
	_allocation_sites[site_name]["count"] += 1
	var frames: Array = _allocation_sites[site_name]["frames"]
	if frames.is_empty() or frames[frames.size() - 1] != _frame_count:
		frames.append(_frame_count)


## Check if a site is allocating every frame (bad pattern).
func is_per_frame_allocator(site_name: StringName) -> bool:
	if site_name not in _allocation_sites:
		return false
	var frames: Array = _allocation_sites[site_name]["frames"]
	if frames.size() < 10:
		return false
	# Check if the last 10 frames are consecutive.
	var consecutive: int = 0
	for i: int in range(frames.size() - 1, maxi(0, frames.size() - 11), -1):
		if i > 0 and frames[i] - frames[i - 1] == 1:
			consecutive += 1
	return consecutive >= 9


## Get all sites that are allocating per-frame.
func get_per_frame_allocators() -> Array[StringName]:
	var result: Array[StringName] = []
	for site: StringName in _allocation_sites:
		if is_per_frame_allocator(site):
			result.append(site)
	return result


## Get allocation count for a site.
func get_allocation_count(site_name: StringName) -> int:
	if site_name not in _allocation_sites:
		return 0
	return _allocation_sites[site_name]["count"]


## Get a formatted report.
func get_report() -> String:
	var report: String = "=== Allocation Tracker Report ===\n"
	report += "Frames tracked: %d\n" % _frame_count
	for site: StringName in _allocation_sites:
		var data: Dictionary = _allocation_sites[site]
		var per_frame: String = "PER-FRAME" if is_per_frame_allocator(site) else "ok"
		report += "  %s: %d allocations [%s]\n" % [str(site), data["count"], per_frame]
	var offenders: Array[StringName] = get_per_frame_allocators()
	if not offenders.is_empty():
		report += "\nWARNING: %d per-frame allocators detected!\n" % offenders.size()
	return report
