## Main scene — entry point for the game.
## In MVP 0 this serves as a scaffold verification scene.
extends Node3D


@onready var debug_label: Label = $UI/DebugLabel


func _ready() -> void:
	print("[Main] Millennium Onslaught MVP 0 — Scaffold loaded successfully")
	print("[Main] Godot version: ", Engine.get_version_info().string)
	print("[Main] Viewport size: ", get_viewport().get_visible_rect().size)
	_verify_autoloads()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_F1:
			print("[Debug] F1 — Hitbox/Hurtbox overlay (not implemented until MVP 1)")
		KEY_F2:
			print("[Debug] F2 — Depth/Z display (not implemented until MVP 1)")
		KEY_F3:
			print("[Debug] F3 — AI state overlay (not implemented until MVP 2)")
		KEY_F4:
			_toggle_debug_info()
		KEY_F5:
			print("[Debug] F5 — Input display (not implemented until MVP 5)")
		KEY_F6:
			_dump_game_state()
		KEY_M:
			AudioManager.toggle_mute()


## F6 — Dump full game state JSON to console.
func _dump_game_state() -> void:
	var state := GameState.serialize_persistent()
	state["current_phase"] = GameManager.get_current_phase_name()
	state["current_dungeon"] = GameState.current_dungeon_id
	state["event_buffer_size"] = EventBus._event_ring_buffer.size()
	print("=== Game State Dump ===")
	print(JSON.stringify(state, "\t"))
	print("=== Recent Events ===")
	print(EventBus.dump_events_json())


func _verify_autoloads() -> void:
	var autoloads: Array[String] = [
		"Constants", "EventBus", "GameState", "GameManager",
		"ObjectPool", "AudioManager", "SaveManager", "InputManager"
	]
	var all_ok := true
	for autoload_name in autoloads:
		var node := get_node_or_null("/root/" + autoload_name)
		if node:
			print("[Main] ✓ ", autoload_name, " loaded")
		else:
			push_error("[Main] ✗ " + autoload_name + " NOT FOUND")
			all_ok = false

	if all_ok:
		debug_label.text = "Millennium Onslaught — MVP 0 Scaffold\nAll 8 autoloads verified OK\nResolution: %s\nPress ESC to quit" % str(get_viewport().get_visible_rect().size)
	else:
		debug_label.text = "Millennium Onslaught — MVP 0 Scaffold\nWARNING: Some autoloads failed to load!"


func _toggle_debug_info() -> void:
	var info := "=== Debug Info ===\n"
	info += "FPS: %d\n" % Engine.get_frames_per_second()
	info += "Phase: %s\n" % GameManager.get_current_phase_name()
	info += "Viewport: %s\n" % str(get_viewport().get_visible_rect().size)
	info += "Objects in tree: %d\n" % get_tree().get_node_count()
	info += "\n=== Recent Events ===\n"
	var events := EventBus.get_recent_events(5)
	for ev in events:
		info += "%s: %s\n" % [str(ev.get("event", "")), str(ev.get("payload", {}))]
	debug_label.text = info
