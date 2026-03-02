## Dungeon manager — sequences rooms, manages encounter flow, handles death/victory.
## Loads rooms from a DungeonDef, triggers encounters, emits dungeon events.
class_name DungeonManager
extends Node


var _dungeon_def: DungeonDef = null
var _current_room_index: int = 0
var _is_active: bool = false
var _score_tracker: ScoreTracker = ScoreTracker.new()
var _wave_system: WaveSystem = null


func _ready() -> void:
	EventBus.enemy_wave_cleared.connect(_on_wave_cleared)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.combat_hit_landed.connect(_on_hit_landed)


## Start a dungeon run from a DungeonDef.
func start_dungeon(dungeon_def: DungeonDef, wave_system: WaveSystem) -> void:
	_dungeon_def = dungeon_def
	_wave_system = wave_system
	_current_room_index = 0
	_is_active = true
	_score_tracker.reset()
	GameState.current_dungeon_id = dungeon_def.dungeon_id
	GameState.current_room_index = 0
	EventBus.dungeon_entered.emit(dungeon_def.dungeon_id)
	EventBus.log_event(&"dungeon_entered", {"dungeon_id": dungeon_def.dungeon_id})
	_enter_room()


## Enter the current room and start its encounter.
func _enter_room() -> void:
	GameState.current_room_index = _current_room_index
	EventBus.dungeon_room_entered.emit(_current_room_index)
	EventBus.log_event(&"dungeon_room_entered", {"room_index": _current_room_index})

	# Get the encounter for this room.
	var encounter: EncounterDef = null
	if _current_room_index < _dungeon_def.room_encounters.size():
		encounter = _dungeon_def.room_encounters[_current_room_index]

	# Boss room uses boss_encounter.
	var is_boss_room := _current_room_index >= _dungeon_def.room_scenes.size() - 1
	if is_boss_room and _dungeon_def.boss_encounter:
		encounter = _dungeon_def.boss_encounter

	if encounter and _wave_system:
		# Load enemy scene — use the generic enemy scene.
		var enemy_scene := preload("res://scenes/enemies/enemy_rusher.tscn")
		_wave_system.start_encounter(encounter, enemy_scene)


func _on_wave_cleared() -> void:
	if not _is_active:
		return
	EventBus.dungeon_room_cleared.emit(_current_room_index)
	EventBus.log_event(&"dungeon_room_cleared", {"room_index": _current_room_index})

	# Check if this was the last room.
	if _current_room_index >= _dungeon_def.room_scenes.size() - 1:
		_complete_dungeon()
	# Otherwise wait for advance_to_next_room() to be called by the room loader.


## Advance to the next room. Called by dungeon_run after transition animation.
func advance_to_next_room() -> void:
	_current_room_index += 1
	_enter_room()


func _on_enemy_died(_enemy: Node, enemy_type: StringName, _position: Vector3) -> void:
	if not _is_active:
		return
	_score_tracker.record_kill(enemy_type)


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, _pos: Vector3) -> void:
	if not _is_active:
		return
	_score_tracker.record_damage(damage)


func _on_player_died(_player_index: int) -> void:
	if not _is_active:
		return
	_fail_dungeon()


func _process(delta: float) -> void:
	if _is_active:
		_score_tracker.tick(delta)


## Dungeon completed successfully.
func _complete_dungeon() -> void:
	_is_active = false
	GameState.bank_dungeon_rewards()
	EventBus.dungeon_completed.emit(_dungeon_def.dungeon_id)
	EventBus.log_event(&"dungeon_completed", {
		"dungeon_id": _dungeon_def.dungeon_id,
		"kills": _score_tracker.get_kill_count(),
		"time": _score_tracker.get_elapsed_time(),
		"score": _score_tracker.calculate_score(),
	})


## Dungeon failed — player died.
func _fail_dungeon() -> void:
	_is_active = false
	GameState.reset_dungeon()
	EventBus.dungeon_failed.emit()
	EventBus.log_event(&"dungeon_failed", {
		"dungeon_id": _dungeon_def.dungeon_id,
		"room": _current_room_index,
		"kills": _score_tracker.get_kill_count(),
		"time": _score_tracker.get_elapsed_time(),
	})


## Get the current score tracker for UI display.
func get_score_tracker() -> ScoreTracker:
	return _score_tracker


## Check if dungeon is currently active.
func is_active() -> bool:
	return _is_active


## Get current room index.
func get_current_room_index() -> int:
	return _current_room_index
