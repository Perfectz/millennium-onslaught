## Local analytics collection — tracks play session statistics.
class_name AnalyticsService
extends Node


## Current session data.
var _session_start: int = 0
var _session_events: Array[Dictionary] = []

## Aggregate stats for current session.
var _stats: Dictionary = {
	"play_time_seconds": 0.0,
	"total_kills": 0,
	"total_deaths": 0,
	"total_damage_dealt": 0.0,
	"total_damage_taken": 0.0,
	"dungeons_entered": 0,
	"dungeons_completed": 0,
	"dungeons_failed": 0,
	"gold_earned": 0,
	"gold_spent": 0,
	"items_collected": 0,
	"highest_combo": 0,
}

## Whether a session is active.
var _active: bool = false


func _ready() -> void:
	_connect_events()


func _process(delta: float) -> void:
	if _active:
		_stats["play_time_seconds"] += delta


## Start a new analytics session.
func start_session() -> void:
	_session_start = Time.get_ticks_msec()
	_session_events.clear()
	_reset_stats()
	_active = true
	_record_event("session_started", {})


## End the current session.
func end_session() -> void:
	_active = false
	_record_event("session_ended", _stats.duplicate())


## Record a named event with optional data.
func record_event(event_name: String, data: Dictionary = {}) -> void:
	_record_event(event_name, data)


## Get current session stats.
func get_stats() -> Dictionary:
	return _stats.duplicate()


## Get all session events.
func get_events() -> Array[Dictionary]:
	return _session_events.duplicate()


## Get a formatted session summary.
func get_summary() -> String:
	var summary: String = "=== Session Summary ===\n"
	summary += "Play time: %.0f seconds\n" % _stats["play_time_seconds"]
	summary += "Kills: %d\n" % _stats["total_kills"]
	summary += "Deaths: %d\n" % _stats["total_deaths"]
	summary += "Damage dealt: %.0f\n" % _stats["total_damage_dealt"]
	summary += "Damage taken: %.0f\n" % _stats["total_damage_taken"]
	summary += "Dungeons: %d entered, %d completed, %d failed\n" % [
		_stats["dungeons_entered"],
		_stats["dungeons_completed"],
		_stats["dungeons_failed"]
	]
	summary += "Gold: %d earned, %d spent\n" % [_stats["gold_earned"], _stats["gold_spent"]]
	summary += "Highest combo: %d\n" % _stats["highest_combo"]
	summary += "Events recorded: %d\n" % _session_events.size()
	return summary


## Serialize session data for persistence.
func serialize_session() -> Dictionary:
	return {
		"stats": _stats.duplicate(),
		"events": _session_events.duplicate(),
		"session_start": _session_start,
	}


func _connect_events() -> void:
	EventBus.combat_hit_landed.connect(_on_hit)
	EventBus.combat_kill.connect(_on_kill)
	EventBus.player_died.connect(_on_player_died)
	EventBus.dungeon_entered.connect(_on_dungeon_entered)
	EventBus.dungeon_completed.connect(_on_dungeon_completed)
	EventBus.dungeon_failed.connect(_on_dungeon_failed)
	EventBus.combat_combo_step.connect(_on_combo_step)


func _record_event(event_name: String, data: Dictionary) -> void:
	_session_events.append({
		"event": event_name,
		"time": Time.get_ticks_msec() - _session_start,
		"data": data,
	})


func _reset_stats() -> void:
	for key: String in _stats:
		if _stats[key] is int:
			_stats[key] = 0
		elif _stats[key] is float:
			_stats[key] = 0.0


func _on_hit(_attacker: Node, _target: Node, damage: float, _pos: Vector3) -> void:
	_stats["total_damage_dealt"] += damage


func _on_kill(_attacker: Node, _target: Node, _pos: Vector3) -> void:
	_stats["total_kills"] += 1


func _on_player_died(_idx: int) -> void:
	_stats["total_deaths"] += 1


func _on_dungeon_entered(_id: StringName) -> void:
	_stats["dungeons_entered"] += 1


func _on_dungeon_completed(_id: StringName) -> void:
	_stats["dungeons_completed"] += 1


func _on_dungeon_failed() -> void:
	_stats["dungeons_failed"] += 1


func _on_combo_step(_player: Node, step: int) -> void:
	if step > _stats["highest_combo"]:
		_stats["highest_combo"] = step
