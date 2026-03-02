## Pure logic score tracking. No scene tree dependency — fully testable.
## Tracks kills (by type), elapsed time, max combo, total damage.
## Calculates a final score for dungeon completion screen.
class_name ScoreTracker
extends RefCounted


var _kills_by_type: Dictionary = {}
var _total_kills: int = 0
var _elapsed_time: float = 0.0
var _max_combo: int = 0
var _total_damage: float = 0.0

## Score formula weights.
const KILL_POINTS: int = 100
const COMBO_BONUS_MULTIPLIER: int = 50
const TIME_PENALTY_PER_SECOND: float = 0.5
const DAMAGE_BONUS_PER_100: int = 10


## Record a kill of a specific enemy type.
func record_kill(enemy_type: StringName) -> void:
	_total_kills += 1
	if enemy_type in _kills_by_type:
		_kills_by_type[enemy_type] += 1
	else:
		_kills_by_type[enemy_type] = 1


## Tick elapsed time. Call with delta each frame.
func tick(delta: float) -> void:
	_elapsed_time += delta


## Update max combo if the new value is higher.
func update_combo(combo_count: int) -> void:
	_max_combo = maxi(_max_combo, combo_count)


## Record damage dealt.
func record_damage(amount: float) -> void:
	_total_damage += amount


## Get total kill count across all types.
func get_kill_count() -> int:
	return _total_kills


## Get kills for a specific enemy type.
func get_kill_count_by_type(enemy_type: StringName) -> int:
	return _kills_by_type.get(enemy_type, 0)


## Get elapsed time in seconds.
func get_elapsed_time() -> float:
	return _elapsed_time


## Get the highest combo achieved.
func get_max_combo() -> int:
	return _max_combo


## Get total damage dealt (truncated to int).
func get_total_damage_dealt() -> int:
	return int(_total_damage)


## Calculate final score.
## Formula: (kills * KILL_POINTS) + (max_combo * COMBO_BONUS) + (damage/100 * DAMAGE_BONUS) - (time * TIME_PENALTY)
func calculate_score() -> int:
	var kill_score := _total_kills * KILL_POINTS
	var combo_score := _max_combo * COMBO_BONUS_MULTIPLIER
	var damage_score := int(_total_damage / 100.0) * DAMAGE_BONUS_PER_100
	var time_penalty := int(_elapsed_time * TIME_PENALTY_PER_SECOND)
	return maxi(kill_score + combo_score + damage_score - time_penalty, 0)


## Reset all tracking data.
func reset() -> void:
	_kills_by_type.clear()
	_total_kills = 0
	_elapsed_time = 0.0
	_max_combo = 0
	_total_damage = 0.0
