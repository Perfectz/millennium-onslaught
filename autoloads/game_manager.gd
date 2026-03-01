## Orchestrates game phase transitions and scene lifecycle.
## The one place that knows "what phase are we in."
class_name GameManagerSingleton
extends Node


## Valid game phases.
enum Phase {
	MAIN_MENU,
	OVERWORLD,
	TOWN,
	DUNGEON,
	CUTSCENE,
	PAUSE,
	GAME_OVER,
}

## Map phase enum to string names for event bus compatibility.
const PHASE_NAMES: Dictionary = {
	Phase.MAIN_MENU: &"main_menu",
	Phase.OVERWORLD: &"overworld",
	Phase.TOWN: &"town",
	Phase.DUNGEON: &"dungeon",
	Phase.CUTSCENE: &"cutscene",
	Phase.PAUSE: &"pause",
	Phase.GAME_OVER: &"game_over",
}

var _current_phase: Phase = Phase.MAIN_MENU
var _previous_phase: Phase = Phase.MAIN_MENU
var _is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Transition to a new game phase.
func change_phase(new_phase: Phase) -> void:
	if new_phase == _current_phase:
		return
	_previous_phase = _current_phase
	_current_phase = new_phase
	GameState.current_phase = PHASE_NAMES[new_phase]
	EventBus.game_phase_changed.emit(
		PHASE_NAMES[new_phase],
		PHASE_NAMES[_previous_phase]
	)
	EventBus.log_event(&"game_phase_changed", {
		"new": PHASE_NAMES[new_phase],
		"old": PHASE_NAMES[_previous_phase],
	})


## Get current phase as enum.
func get_current_phase() -> Phase:
	return _current_phase


## Get current phase as StringName.
func get_current_phase_name() -> StringName:
	return PHASE_NAMES[_current_phase]


## Toggle pause state.
func toggle_pause() -> void:
	if _is_paused:
		resume_game()
	else:
		pause_game()


## Pause the game tree.
func pause_game() -> void:
	_is_paused = true
	get_tree().paused = true
	EventBus.game_paused.emit()
	EventBus.log_event(&"game_paused")


## Resume the game tree.
func resume_game() -> void:
	_is_paused = false
	get_tree().paused = false
	EventBus.game_resumed.emit()
	EventBus.log_event(&"game_resumed")


## Check if game is currently paused.
func is_paused() -> bool:
	return _is_paused


## Restart the current dungeon run.
func restart_dungeon() -> void:
	GameState.reset_dungeon()
	EventBus.game_restarted.emit()
	EventBus.log_event(&"game_restarted")
