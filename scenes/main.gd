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
	# F4 — Toggle debug info
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		_toggle_debug_info()
	# M — Toggle mute
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		AudioManager.toggle_mute()


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
