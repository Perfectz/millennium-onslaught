## Dungeon manager — sequences rooms, manages encounter flow, handles death/victory.
## Loads rooms from a DungeonDef, triggers encounters, emits dungeon events.
class_name DungeonManager
extends Node


var _dungeon_def: DungeonDef = null
var _current_room_index: int = 0
var _is_active: bool = false
var _score_tracker: ScoreTracker = ScoreTracker.new()
var _wave_system: WaveSystem = null
var _dungeon_gold: int = 0
var _dungeon_xp: int = 0


func _ready() -> void:
	EventBus.enemy_wave_cleared.connect(_on_wave_cleared)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.combat_hit_event.connect(_on_hit_event)


## Start a dungeon run from a DungeonDef.
func start_dungeon(dungeon_def: DungeonDef, wave_system: WaveSystem) -> void:
	_dungeon_def = dungeon_def
	_wave_system = wave_system
	_current_room_index = 0
	_is_active = true
	_score_tracker.reset()
	_dungeon_gold = 0
	_dungeon_xp = 0
	RuntimeState.current_dungeon_id = dungeon_def.dungeon_id
	RuntimeState.current_room_index = 0
	EventBus.emit_checked(&"dungeon_entered", [dungeon_def.dungeon_id], {
		"dungeon_id": dungeon_def.dungeon_id,
	})
	# In stage mode, StageRunner handles encounters. Skip room entry.
	if not RuntimeState.stage_mode:
		_enter_room()


## Enter the current room and start its encounter.
func _enter_room() -> void:
	RuntimeState.current_room_index = _current_room_index
	EventBus.emit_checked(&"dungeon_room_entered", [_current_room_index], {
		"room_index": _current_room_index,
	})

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

	if RuntimeState.stage_mode:
		# Stage mode: StageRunner handles forward bounds. DungeonManager tracks completion.
		RuntimeState.stage_encounters_completed += 1
		EventBus.emit_checked(&"stage_encounter_cleared", [
			RuntimeState.stage_encounters_completed - 1,
		], {
			"encounter_index": RuntimeState.stage_encounters_completed - 1,
		})
		if RuntimeState.stage_encounters_completed >= RuntimeState.stage_total_encounters:
			_complete_dungeon()
	else:
		# Room mode: existing logic.
		EventBus.emit_checked(&"dungeon_room_cleared", [_current_room_index], {
			"room_index": _current_room_index,
		})
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
	if _enemy is EnemyController:
		var ec := _enemy as EnemyController
		if ec.enemy_def:
			# Accumulate gold from enemy drops.
			_dungeon_gold += ec.enemy_def.gold_reward
			# Award XP to active party members.
			_dungeon_xp += ec.enemy_def.xp_reward
			# Roll equipment drops from enemy's drop table.
			if not ec.enemy_def.drop_table.is_empty():
				var drops := DropRoller.roll_drops(ec.enemy_def.drop_table)
				for item_id: StringName in drops:
					RuntimeState.dungeon_drops.append({"item_id": item_id})
					EventBus.emit_checked(&"rpg_item_dropped", [_position, item_id], {
						"position": _position,
						"item_id": item_id,
					})


func _on_hit_event(event: CombatHitEvent) -> void:
	if not _is_active:
		return
	_score_tracker.record_damage(event.damage)


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
	# Bank accumulated gold.
	GameState.gold += _dungeon_gold
	EventBus.emit_checked(&"rpg_gold_changed", [GameState.gold], {"new_total": GameState.gold})
	# Award XP to all active party members via GameState.
	for char_id: StringName in GameState.active_party:
		if char_id in GameState.character_data:
			GameState.character_data[char_id]["xp"] = GameState.character_data[char_id].get("xp", 0) + _dungeon_xp
	# Set story flag for this dungeon.
	GameState.story_flags[_dungeon_def.dungeon_id + "_complete"] = true
	EventBus.emit_checked(&"dungeon_completed", [_dungeon_def.dungeon_id], {
		"dungeon_id": _dungeon_def.dungeon_id,
		"kills": _score_tracker.get_kill_count(),
		"time": _score_tracker.get_elapsed_time(),
		"score": _score_tracker.calculate_score(),
		"gold_earned": _dungeon_gold,
		"xp_earned": _dungeon_xp,
	})


## Dungeon failed — player died.
func _fail_dungeon() -> void:
	_is_active = false
	RuntimeState.reset_dungeon()
	EventBus.emit_checked(&"dungeon_failed", [], {
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


## Get gold earned this run.
func get_gold_earned() -> int:
	return _dungeon_gold


## Get XP earned this run.
func get_xp_earned() -> int:
	return _dungeon_xp
