## Records and replays input events for bug reproduction.
class_name ReplayCapture
extends Node


## Recorded input frame.
class InputFrame extends RefCounted:
	var frame_number: int = 0
	var actions_pressed: Array[StringName] = []
	var actions_released: Array[StringName] = []


## Recording state.
var _recording: bool = false
var _replaying: bool = false
var _frames: Array[InputFrame] = []
var _current_frame: int = 0
var _replay_frame: int = 0

## Actions to track.
var _tracked_actions: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"jump", &"attack_light", &"attack_heavy", &"dodge", &"technique",
]


func _process(_delta: float) -> void:
	if _recording:
		_record_frame()
	elif _replaying:
		_replay_current_frame()


## Start recording inputs.
func start_recording() -> void:
	_frames.clear()
	_current_frame = 0
	_recording = true
	_replaying = false
	print("[ReplayCapture] Recording started")


## Stop recording.
func stop_recording() -> void:
	_recording = false
	print("[ReplayCapture] Recording stopped. %d frames captured." % _frames.size())


## Start replaying recorded inputs.
func start_replay() -> void:
	if _frames.is_empty():
		push_warning("ReplayCapture: No frames to replay")
		return
	_replay_frame = 0
	_replaying = true
	_recording = false
	print("[ReplayCapture] Replay started. %d frames." % _frames.size())


## Stop replaying.
func stop_replay() -> void:
	_replaying = false
	print("[ReplayCapture] Replay stopped at frame %d" % _replay_frame)


## Check if recording.
func is_recording() -> bool:
	return _recording


## Check if replaying.
func is_replaying() -> bool:
	return _replaying


## Get recorded frame count.
func get_frame_count() -> int:
	return _frames.size()


## Serialize recorded inputs for saving.
func serialize() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for frame: InputFrame in _frames:
		data.append({
			"frame": frame.frame_number,
			"pressed": frame.actions_pressed.duplicate(),
			"released": frame.actions_released.duplicate(),
		})
	return data


## Load recorded inputs from serialized data.
func deserialize(data: Array[Dictionary]) -> void:
	_frames.clear()
	for d: Dictionary in data:
		var frame := InputFrame.new()
		frame.frame_number = d.get("frame", 0)
		frame.actions_pressed.assign(d.get("pressed", []))
		frame.actions_released.assign(d.get("released", []))
		_frames.append(frame)


func _record_frame() -> void:
	var frame := InputFrame.new()
	frame.frame_number = _current_frame
	for action: StringName in _tracked_actions:
		if Input.is_action_just_pressed(action):
			frame.actions_pressed.append(action)
		if Input.is_action_just_released(action):
			frame.actions_released.append(action)
	# Only store frames with input.
	if not frame.actions_pressed.is_empty() or not frame.actions_released.is_empty():
		_frames.append(frame)
	_current_frame += 1


func _replay_current_frame() -> void:
	if _replay_frame >= _frames.size():
		stop_replay()
		return
	var frame: InputFrame = _frames[_replay_frame]
	if frame.frame_number == _current_frame:
		for action: StringName in frame.actions_pressed:
			Input.action_press(action)
		for action: StringName in frame.actions_released:
			Input.action_release(action)
		_replay_frame += 1
	_current_frame += 1
