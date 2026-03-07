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

## Per-player pressed sources: player_index -> {action -> {source_id -> true}}.
var _pressed_sources: Array[Dictionary] = []

## Per-player axis sources: player_index -> {action -> {source_id -> float}}.
var _axis_sources: Array[Dictionary] = []

## Max players supported.
var _max_players: int = 4


func _init(max_players: int = 4) -> void:
	_max_players = max_players
	for i in _max_players:
		_pressed.append({})
		_just_pressed.append({})
		_axis_values.append({})
		_pressed_sources.append({})
		_axis_sources.append({})


## Register that an action was pressed for a player.
func register_action_pressed(player_idx: int, action: StringName, source_id: int = 0) -> void:
	if not _is_valid_player(player_idx):
		return
	var already_pressed: bool = _pressed[player_idx].get(action, false)
	var action_sources: Dictionary = _pressed_sources[player_idx].get(action, {})
	action_sources[source_id] = true
	_pressed_sources[player_idx][action] = action_sources
	if not already_pressed:
		_just_pressed[player_idx][action] = true
	_pressed[player_idx][action] = true


## Register that an action was released for a player.
func register_action_released(player_idx: int, action: StringName, source_id: int = 0) -> void:
	if not _is_valid_player(player_idx):
		return
	var action_sources: Dictionary = _pressed_sources[player_idx].get(action, {})
	if action_sources.has(source_id):
		action_sources.erase(source_id)
	if action_sources.is_empty():
		_pressed_sources[player_idx].erase(action)
		_pressed[player_idx].erase(action)
		_just_pressed[player_idx].erase(action)
		return
	_pressed_sources[player_idx][action] = action_sources
	_pressed[player_idx][action] = true


## Register an axis value for a player (e.g., joystick).
func register_axis_value(player_idx: int, action: StringName, value: float, source_id: int = 0) -> void:
	if not _is_valid_player(player_idx):
		return
	var clamped_value := clampf(value, 0.0, 1.0)
	var action_sources: Dictionary = _axis_sources[player_idx].get(action, {})
	if is_zero_approx(clamped_value):
		action_sources.erase(source_id)
	else:
		action_sources[source_id] = clamped_value
	if action_sources.is_empty():
		_axis_sources[player_idx].erase(action)
		_axis_values[player_idx].erase(action)
		return
	_axis_sources[player_idx][action] = action_sources
	_axis_values[player_idx][action] = _get_max_axis_value(action_sources)


## Check if an action is currently held down for a player.
func is_pressed(player_idx: int, action: StringName) -> bool:
	if not _is_valid_player(player_idx):
		return false
	var val: bool = _pressed[player_idx].get(action, false)
	return val


## Consume the just-pressed flag for a player action. Returns true once per press.
func consume_just_pressed(player_idx: int, action: StringName) -> bool:
	if not _is_valid_player(player_idx):
		return false
	var was_just_pressed: bool = _just_pressed[player_idx].get(action, false)
	if was_just_pressed:
		_just_pressed[player_idx][action] = false
		return true
	return false


## Get axis value computed from two opposing actions (positive - negative).
func get_axis(player_idx: int, negative_action: StringName, positive_action: StringName) -> float:
	if not _is_valid_player(player_idx):
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
	clear_just_pressed()


## Clear just-pressed flags for one player or all players.
func clear_just_pressed(player_idx: int = -1) -> void:
	if player_idx < 0:
		for i in _max_players:
			_just_pressed[i].clear()
		return
	if not _is_valid_player(player_idx):
		return
	_just_pressed[player_idx].clear()


## Clear all tracked state for all players.
func clear_all_state() -> void:
	for i in _max_players:
		clear_player_state(i)


## Get raw axis value for a single action (not computed from two).
func get_raw_axis(player_idx: int, action: StringName) -> float:
	if not _is_valid_player(player_idx):
		return 0.0
	var val: float = _axis_values[player_idx].get(action, 0.0)
	return val


## Snapshot all currently held actions for debugging overlays.
func get_pressed_actions(player_idx: int) -> Array[String]:
	var actions: Array[String] = []
	if not _is_valid_player(player_idx):
		return actions
	for action in _pressed[player_idx]:
		if _pressed[player_idx].get(action, false):
			actions.append(String(action))
	actions.sort()
	return actions


## Snapshot raw analog values for debugging overlays.
func get_axis_snapshot(player_idx: int) -> Dictionary:
	if not _is_valid_player(player_idx):
		return {}
	return _axis_values[player_idx].duplicate(true)


## Clear all tracked input state for a player (used on device disconnect / reassignment).
func clear_player_state(player_idx: int) -> void:
	if not _is_valid_player(player_idx):
		return
	_pressed[player_idx].clear()
	_just_pressed[player_idx].clear()
	_axis_values[player_idx].clear()
	_pressed_sources[player_idx].clear()
	_axis_sources[player_idx].clear()


## Clear only one source contribution from a player while preserving other sources.
func clear_device_state(player_idx: int, source_id: int) -> void:
	if not _is_valid_player(player_idx):
		return

	var pressed_actions: Array = _pressed_sources[player_idx].keys()
	for action in pressed_actions:
		var action_sources: Dictionary = _pressed_sources[player_idx].get(action, {})
		if not action_sources.has(source_id):
			continue
		action_sources.erase(source_id)
		if action_sources.is_empty():
			_pressed_sources[player_idx].erase(action)
			_pressed[player_idx].erase(action)
			_just_pressed[player_idx].erase(action)
		else:
			_pressed_sources[player_idx][action] = action_sources
			_pressed[player_idx][action] = true

	var axis_actions: Array = _axis_sources[player_idx].keys()
	for action in axis_actions:
		var axis_sources: Dictionary = _axis_sources[player_idx].get(action, {})
		if not axis_sources.has(source_id):
			continue
		axis_sources.erase(source_id)
		if axis_sources.is_empty():
			_axis_sources[player_idx].erase(action)
			_axis_values[player_idx].erase(action)
		else:
			_axis_sources[player_idx][action] = axis_sources
			_axis_values[player_idx][action] = _get_max_axis_value(axis_sources)


func _is_valid_player(player_idx: int) -> bool:
	return player_idx >= 0 and player_idx < _max_players


func _get_max_axis_value(action_sources: Dictionary) -> float:
	var max_value := 0.0
	for source_id in action_sources:
		max_value = maxf(max_value, float(action_sources[source_id]))
	return max_value
