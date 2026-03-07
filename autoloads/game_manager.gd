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
var _transitioner: SceneTransitioner


var _touch_controls: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_transitioner = SceneTransitioner.new()
	_transitioner.name = "SceneTransitioner"
	add_child(_transitioner)
	_init_touch_controls()


## Spawn touch controls on mobile platforms.
func _init_touch_controls() -> void:
	if not InputManager.is_mobile():
		return
	var TouchControlsScene := load("res://scripts/ui/touch_controls.gd")
	_touch_controls = CanvasLayer.new()
	_touch_controls.set_script(TouchControlsScene)
	_touch_controls.name = "TouchControls"
	add_child(_touch_controls)


## Transition to a new game phase.
func change_phase(new_phase: Phase) -> void:
	if new_phase == _current_phase:
		return
	_previous_phase = _current_phase
	_current_phase = new_phase
	RuntimeState.current_phase = PHASE_NAMES[new_phase]
	EventBus.emit_checked(&"game_phase_changed", [
		PHASE_NAMES[new_phase],
		PHASE_NAMES[_previous_phase],
	], {
		"new_phase": PHASE_NAMES[new_phase],
		"old_phase": PHASE_NAMES[_previous_phase],
	}, true)


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
	EventBus.emit_checked(&"game_paused", [], {}, true)


## Resume the game tree.
func resume_game() -> void:
	_is_paused = false
	get_tree().paused = false
	EventBus.emit_checked(&"game_resumed", [], {}, true)


## Check if game is currently paused.
func is_paused() -> bool:
	return _is_paused


## Restart the current dungeon run.
func restart_dungeon() -> void:
	RuntimeState.reset_dungeon()
	EventBus.emit_checked(&"game_restarted", [], {}, true)


## Request a scene transition with fade effect.
func transition_to_scene(scene_path: String) -> void:
	_transitioner.transition_to(scene_path)


## Navigate to the overworld map.
func go_to_overworld() -> void:
	change_phase(Phase.OVERWORLD)
	transition_to_scene(Constants.SCENE_OVERWORLD)


## Navigate to a town by town_id.
func go_to_town(town_id: StringName) -> void:
	GameState.pending_town_id = town_id
	change_phase(Phase.TOWN)
	transition_to_scene(Constants.SCENE_TOWN)


## Navigate to character select before entering a dungeon.
func go_to_character_select(dungeon_id: StringName) -> void:
	GameState.pending_dungeon_id = dungeon_id
	transition_to_scene(Constants.SCENE_CHARACTER_SELECT)


## Navigate to a dungeon by dungeon_id.
func go_to_dungeon(dungeon_id: StringName) -> void:
	GameState.pending_dungeon_id = dungeon_id
	change_phase(Phase.DUNGEON)
	transition_to_scene(Constants.SCENE_DUNGEON)


## Navigate to a cutscene with scene data, next destination, and optional music track.
func go_to_cutscene(scenes: Array, next_destination: StringName = &"overworld", music: StringName = &"") -> void:
	GameState.pending_cutscene_data = scenes
	GameState.pending_cutscene_next = next_destination
	GameState.pending_cutscene_music = music
	change_phase(Phase.CUTSCENE)
	transition_to_scene(Constants.SCENE_CUTSCENE)


## Navigate to the main menu.
func go_to_main_menu() -> void:
	change_phase(Phase.MAIN_MENU)
	transition_to_scene(Constants.SCENE_MAIN_MENU)
