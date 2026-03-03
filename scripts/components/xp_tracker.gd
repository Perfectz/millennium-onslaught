## Pure XP and leveling logic. No scene tree dependency — fully testable.
## Tracks XP accumulation, level thresholds, and stat point awards.
class_name XPTracker
extends RefCounted


signal xp_gained(amount: int, total: int)
signal level_up(new_level: int, stat_points_awarded: int)

var _xp: int = 0
var _level: int = 1


## Add XP. Returns total stat points awarded from any level-ups triggered.
func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	_xp += amount
	xp_gained.emit(amount, _xp)
	var total_points: int = 0
	while _xp >= get_xp_for_next_level():
		_xp -= get_xp_for_next_level()
		_level += 1
		total_points += Constants.STAT_POINTS_PER_LEVEL
		level_up.emit(_level, Constants.STAT_POINTS_PER_LEVEL)
	return total_points


## Get accumulated XP toward next level.
func get_xp() -> int:
	return _xp


## Get current level.
func get_level() -> int:
	return _level


## Get XP required to reach the next level from current level.
func get_xp_for_next_level() -> int:
	return int(floorf(Constants.LEVEL_XP_BASE * pow(Constants.LEVEL_XP_GROWTH_RATE, _level - 1)))


## Get progress ratio (0.0 to 1.0) toward next level.
func get_xp_progress() -> float:
	var threshold := get_xp_for_next_level()
	if threshold <= 0:
		return 0.0
	return float(_xp) / float(threshold)


## Process any pending level-ups at current XP/level. Used for non-active party members.
func check_level_ups() -> int:
	var total_points: int = 0
	while _xp >= get_xp_for_next_level():
		_xp -= get_xp_for_next_level()
		_level += 1
		total_points += Constants.STAT_POINTS_PER_LEVEL
	return total_points


## Restore state from save data.
func set_state(xp: int, level: int) -> void:
	_xp = xp
	_level = level
