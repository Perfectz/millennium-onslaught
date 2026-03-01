## Device-to-player mapping, context switching, and input remapping.
class_name InputManagerSingleton
extends Node


## Input contexts determine what buttons do in each game phase.
enum InputContext {
	COMBAT,
	MENU,
	OVERWORLD,
	DIALOGUE,
}

## Device-to-player mapping. Key: device_id, Value: player_index.
var _device_to_player: Dictionary = {}

## Current input context.
var _current_context: InputContext = InputContext.MENU

## Maximum players supported.
const MAX_PLAYERS: int = 4


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Player 1 defaults to keyboard (device -1 in Godot represents keyboard).
	_device_to_player[-1] = 0
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


## Switch the active input context.
func set_context(context: InputContext) -> void:
	_current_context = context
	var context_names: Dictionary = {
		InputContext.COMBAT: &"combat",
		InputContext.MENU: &"menu",
		InputContext.OVERWORLD: &"overworld",
		InputContext.DIALOGUE: &"dialogue",
	}
	EventBus.input_context_changed.emit(context_names[context])
	EventBus.log_event(&"input_context_changed", {"context": context_names[context]})


## Get the current input context.
func get_context() -> InputContext:
	return _current_context


## Get the player index for a given device.
func get_player_for_device(device_id: int) -> int:
	return _device_to_player.get(device_id, -1)


## Assign a device to a player index.
func assign_device_to_player(device_id: int, player_index: int) -> void:
	_device_to_player[device_id] = player_index


## Get number of connected players.
func get_connected_player_count() -> int:
	return _device_to_player.size()


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		# Auto-assign to next available player slot.
		var next_slot := _find_next_available_slot()
		if next_slot >= 0:
			_device_to_player[device_id] = next_slot
			EventBus.input_device_connected.emit(device_id)
			EventBus.log_event(&"input_device_connected", {
				"device": device_id,
				"player": next_slot,
			})
	else:
		if device_id in _device_to_player:
			_device_to_player.erase(device_id)
			EventBus.input_device_disconnected.emit(device_id)
			EventBus.log_event(&"input_device_disconnected", {"device": device_id})


func _find_next_available_slot() -> int:
	for i in MAX_PLAYERS:
		if i not in _device_to_player.values():
			return i
	return -1
