## Manages dungeon entry/exit, room progression, and fail/complete flow.
class_name DungeonManager
extends Node


## The stage runner instance.
var _stage_runner: StageRunner = null

## Whether a dungeon run is active.
var _active: bool = false


func _ready() -> void:
	EventBus.dungeon_completed.connect(_on_dungeon_completed)
	EventBus.player_died.connect(_on_player_died)


## Enter a dungeon by ID.
func enter_dungeon(dungeon_id: StringName, stage_runner: StageRunner) -> void:
	_stage_runner = stage_runner
	_active = true
	GameState.current_dungeon_id = dungeon_id
	GameState.current_room_index = 0
	GameState.encounter_active = true
	GameManager.change_phase(GameManager.Phase.DUNGEON)
	InputManager.set_context(InputManager.InputContext.COMBAT)
	EventBus.log_event(&"dungeon_entered", {"dungeon_id": dungeon_id})


## Exit the dungeon (return to overworld).
func exit_dungeon() -> void:
	_active = false
	GameState.encounter_active = false
	GameManager.change_phase(GameManager.Phase.OVERWORLD)
	InputManager.set_context(InputManager.InputContext.OVERWORLD)
	EventBus.log_event(&"dungeon_exited", {})


## Handle dungeon failure (player death).
func fail_dungeon() -> void:
	_active = false
	GameState.reset_dungeon()
	EventBus.dungeon_failed.emit()
	EventBus.log_event(&"dungeon_failed", {})
	GameManager.change_phase(GameManager.Phase.GAME_OVER)


## Check if dungeon is active.
func is_active() -> bool:
	return _active


func _on_dungeon_completed(_dungeon_id: StringName) -> void:
	exit_dungeon()


func _on_player_died(_player_index: int) -> void:
	if not _active:
		return
	# In single player, one death = dungeon fail.
	# In co-op, check if all players are dead.
	fail_dungeon()
