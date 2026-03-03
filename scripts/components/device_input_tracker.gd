## Tracks per-player input state from device events.
## Pure logic (RefCounted) for TDD — InputManager wraps this and feeds it events.
class_name DeviceInputTracker
extends RefCounted


## Per-player pressed state: player_index -> {action -> bool}.
var _pressed: Array[Dictionary] = []

## Per-player just-pressed state (consumed once per query): player_index -> {action -> bool}.
var _just_pressed: Array[Dictionary] = []

## Per-player axis values: player_index -> {action -> float}.
var _axis_values: Array[Dictionary] = []

## Max players supported.
var _max_players: int = 4


func _init(max_players: int = 4) -> void:
	_max_players = max_players
	for i in _max_players:
		_pressed.append({})
		_just_pressed.append({})
		_axis_values.append({})


## Register that an action was pressed for a player.
func register_action_pressed(player_idx: int, action: StringName) -> void:
	if player_idx < 0 or player_idx >= _max_players:
		return
	var already_pressed: bool = _pressed[player_idx].get(action, false)
	if not already_pressed:
		_just_pressed[player_idx][action] = true
	_pressed[player_idx][action] = true


## Register that an action was released for a player.
func register_action_released(player_idx: int, action: StringName) -> void:
	if player_idx < 0 or player_idx >= _max_players:
		return
	_pressed[player_idx][action] = false


## Register an axis value for a player (e.g., joystick).
func register_axis_value(player_idx: int, action: StringName, value: float) -> void:
	if player_idx < 0 or player_idx >= _max_players:
		return
	_axis_values[player_idx][action] = value


## Check if an action is currently held down for a player.
func is_pressed(player_idx: int, action: StringName) -> bool:
	if player_idx < 0 or player_idx >= _max_players:
		return false
	var val: bool = _pressed[player_idx].get(action, false)
	return val


## Consume the just-pressed flag for a player action. Returns true once per press.
func consume_just_pressed(player_idx: int, action: StringName) -> bool:
	if player_idx < 0 or player_idx >= _max_players:
		return false
	var was_just_pressed: bool = _just_pressed[player_idx].get(action, false)
	if was_just_pressed:
		_just_pressed[player_idx][action] = false
		return true
	return false


## Get axis value computed from two opposing actions (positive - negative).
func get_axis(player_idx: int, negative_action: StringName, positive_action: StringName) -> float:
	if player_idx < 0 or player_idx >= _max_players:
		return 0.0
	var neg: float = _axis_values[player_idx].get(negative_action, 0.0)
	var pos: float = _axis_values[player_idx].get(positive_action, 0.0)
	# If using digital buttons, fall back to pressed state.
	if is_zero_approx(neg) and is_pressed(player_idx, negative_action):
		neg = 1.0
	if is_zero_approx(pos) and is_pressed(player_idx, positive_action):
		pos = 1.0
	return pos - neg


## Clear just-pressed flags at end of frame.
func end_frame() -> void:
	for i in _max_players:
		_just_pressed[i].clear()


## Get raw axis value for a single action (not computed from two).
func get_raw_axis(player_idx: int, action: StringName) -> float:
	if player_idx < 0 or player_idx >= _max_players:
		return 0.0
	var val: float = _axis_values[player_idx].get(action, 0.0)
	return val
