## Debug overlay toggled through InputMap debug actions (default F3-F10).
## Attaches to the HUD as a CanvasLayer child. PROCESS_MODE_ALWAYS to work during pause.
class_name DebugOverlay
extends CanvasLayer

const DebugBundleCaptureScript := preload("res://scripts/tools/debug_bundle_capture.gd")


var _perf_visible: bool = false
var _ai_visible: bool = false
var _input_visible: bool = false
var _events_visible: bool = false
var _perf_label: Label = null
var _input_label: Label = null
var _events_label: Label = null
var _ai_labels: Dictionary = {}  # enemy instance_id -> Label3D


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_perf_label()
	_build_input_label()
	_build_events_label()
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle_ai", false, true):
		_ai_visible = not _ai_visible
		_update_ai_labels_visibility()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle_perf", false, true):
		_perf_visible = not _perf_visible
		_perf_label.visible = _perf_visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle_input", false, true):
		_input_visible = not _input_visible
		_input_label.visible = _input_visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle_events", false, true):
		_events_visible = not _events_visible
		_events_label.visible = _events_visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_restart_dungeon", false, true):
		_restart_current_dungeon()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_capture_bundle", false, true):
		_capture_debug_bundle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_validate_stage", false, true):
		_validate_current_stage()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _perf_visible:
		_update_perf()
	if _input_visible:
		_update_input()
	if _events_visible:
		_update_events()
	if _ai_visible:
		_update_ai()


func _build_perf_label() -> void:
	_perf_label = Label.new()
	_perf_label.name = "PerfLabel"
	_perf_label.anchor_left = 1.0
	_perf_label.anchor_right = 1.0
	_perf_label.anchor_top = 0.0
	_perf_label.anchor_bottom = 0.0
	_perf_label.offset_left = -280.0
	_perf_label.offset_right = -8.0
	_perf_label.offset_top = 8.0
	_perf_label.offset_bottom = 120.0
	_perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_perf_label.add_theme_font_size_override("font_size", 14)
	_perf_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	_perf_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_perf_label.add_theme_constant_override("outline_size", 3)
	_perf_label.visible = false
	add_child(_perf_label)


func _build_input_label() -> void:
	_input_label = Label.new()
	_input_label.name = "InputLabel"
	_input_label.anchor_left = 1.0
	_input_label.anchor_right = 1.0
	_input_label.anchor_top = 0.0
	_input_label.anchor_bottom = 0.0
	_input_label.offset_left = -420.0
	_input_label.offset_right = -8.0
	_input_label.offset_top = 132.0
	_input_label.offset_bottom = 336.0
	_input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_input_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_input_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_input_label.add_theme_font_size_override("font_size", 13)
	_input_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	_input_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_input_label.add_theme_constant_override("outline_size", 3)
	_input_label.visible = false
	add_child(_input_label)


func _build_events_label() -> void:
	_events_label = Label.new()
	_events_label.name = "EventsLabel"
	_events_label.anchor_left = 0.0
	_events_label.anchor_right = 0.0
	_events_label.anchor_top = 1.0
	_events_label.anchor_bottom = 1.0
	_events_label.offset_left = 12.0
	_events_label.offset_right = 520.0
	_events_label.offset_top = -196.0
	_events_label.offset_bottom = -12.0
	_events_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_events_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_events_label.add_theme_font_size_override("font_size", 12)
	_events_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.7))
	_events_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_events_label.add_theme_constant_override("outline_size", 3)
	_events_label.visible = false
	add_child(_events_label)


func _update_perf() -> void:
	var fps := Engine.get_frames_per_second()
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)

	_perf_label.text = "FPS: %d\nDraw Calls: %d\nPrimitives: %d\nObjects: %d\nNodes: %d\nOrphans: %d\nMemory: %.1f MB" % [
		fps, draw_calls, primitives, objects, nodes, orphans, mem_static
	]


func _update_input() -> void:
	var snapshot := InputManager.get_debug_snapshot()
	var lines: Array[String] = []
	lines.append("INPUT  |  Context: %s" % snapshot.get("context", "unknown"))
	for device_info: Dictionary in snapshot.get("devices", []):
		lines.append("Device %s -> P%d  %s" % [
			str(device_info.get("device", "?")),
			int(device_info.get("player", -1)),
			String(device_info.get("name", "")),
		])
	for player_info: Dictionary in snapshot.get("players", []):
		var pressed: Array = player_info.get("pressed", [])
		var axes: Dictionary = player_info.get("axes", {})
		var axis_parts: Array[String] = []
		for action in axes:
			axis_parts.append("%s:%s" % [String(action), String.num(float(axes[action]), 2)])
		axis_parts.sort()
		lines.append("P%d Pressed: %s" % [
			int(player_info.get("player", -1)),
			_join_strings(pressed, ", ") if not pressed.is_empty() else "-",
		])
		lines.append("P%d Axes: %s" % [
			int(player_info.get("player", -1)),
			_join_strings(axis_parts, ", ") if not axis_parts.is_empty() else "-",
		])
	_input_label.text = _join_strings(lines, "\n")


func _update_events() -> void:
	var recent_events := EventBus.get_recent_events(8)
	var lines: Array[String] = ["EVENT LOG"]
	for entry in recent_events:
		var event_name := String(entry.get("event", "unknown"))
		var payload: Dictionary = entry.get("payload", {})
		var payload_summary := _summarize_event_payload(payload)
		lines.append("%s%s%s" % [
			_get_event_prefix(event_name, entry),
			event_name,
			"  |  %s" % payload_summary if payload_summary != "" else "",
		])
	_events_label.text = _join_strings(lines, "\n")


func _on_enemy_spawned(enemy: Node, _enemy_type: StringName) -> void:
	if not is_instance_valid(enemy):
		return
	var lbl := Label3D.new()
	lbl.name = "AIStateLabel"
	lbl.text = "idle"
	lbl.font_size = 48
	lbl.outline_size = 8
	lbl.modulate = Color(1.0, 0.7, 0.2)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 10
	lbl.position = Vector3(0, 2.8, 0)
	lbl.visible = _ai_visible
	enemy.add_child(lbl)
	_ai_labels[enemy.get_instance_id()] = lbl


func _on_enemy_died(enemy: Node, _enemy_type: StringName, _position: Vector3) -> void:
	_ai_labels.erase(enemy.get_instance_id())


func _update_ai() -> void:
	var stale_keys: Array = []
	for key: int in _ai_labels:
		var lbl: Label3D = _ai_labels[key]
		if not is_instance_valid(lbl):
			stale_keys.append(key)
			continue
		var enemy := lbl.get_parent()
		if not is_instance_valid(enemy) or not enemy.has_node("StateMachine"):
			stale_keys.append(key)
			continue
		var sm: StateMachine = enemy.get_node("StateMachine")
		lbl.text = str(sm.current_state_name)
	for key: int in stale_keys:
		_ai_labels.erase(key)


func _update_ai_labels_visibility() -> void:
	for key: int in _ai_labels:
		var lbl: Label3D = _ai_labels[key]
		if is_instance_valid(lbl):
			lbl.visible = _ai_visible


func _summarize_event_payload(payload: Variant) -> String:
	if not (payload is Dictionary):
		return ""
	var parts: Array[String] = []
	for key in payload:
		parts.append("%s=%s" % [String(key), _stringify_payload_value(payload[key])])
		if parts.size() >= 3:
			break
	return _join_strings(parts, ", ")


func _stringify_payload_value(value: Variant) -> String:
	if value is StringName:
		return String(value)
	if value is Vector3:
		var v := value as Vector3
		return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]
	if value is float:
		return String.num(float(value), 2)
	return str(value)


func _get_event_prefix(event_name: String, entry: Dictionary) -> String:
	if event_name == "event_bus_unknown_signal":
		return "[UNKNOWN] "
	if bool(entry.get("unmatched", false)):
		return "[NO LISTENERS] "
	return ""


func _restart_current_dungeon() -> void:
	var dungeon_id := RuntimeState.current_dungeon_id
	if dungeon_id == &"":
		dungeon_id = GameState.pending_dungeon_id
	if dungeon_id == &"":
		return
	ToastSystem.show_toast("RESTARTING DUNGEON", Color(0.95, 0.82, 0.45))
	GameManager.go_to_dungeon(dungeon_id)


func _capture_debug_bundle() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var bundle_capture := DebugBundleCaptureScript.new()
	var saved_path := bundle_capture.write_bundle(scene_root, &"manual")
	if saved_path == "":
		ToastSystem.show_toast("BUNDLE CAPTURE FAILED", Color(1.0, 0.55, 0.55))
		return
	ToastSystem.show_toast("BUNDLE SAVED", Color(0.72, 0.95, 1.0))
	EventBus.log_event(&"debug_bundle_captured", {"path": saved_path})


func _validate_current_stage() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var stage_runner := scene_root.find_child("StageRunner", true, false)
	if stage_runner == null or not stage_runner.has_method("get_stage_def"):
		ToastSystem.show_toast("NO ACTIVE STAGE", Color(1.0, 0.7, 0.45))
		return
	var stage_def := stage_runner.get_stage_def() as StageDef
	var audit := StageValidator.audit_stage(stage_def)
	var errors: Array[String] = audit.get("errors", [])
	var warnings: Array[String] = audit.get("warnings", [])
	StageValidator.validate_and_print(stage_def)
	if errors.is_empty():
		var message := "STAGE VALID"
		if not warnings.is_empty():
			message = "STAGE VALID (+ WARNINGS)"
		ToastSystem.show_toast(message, Color(0.75, 1.0, 0.78))
	else:
		ToastSystem.show_toast("STAGE INVALID", Color(1.0, 0.58, 0.58))
	EventBus.log_event(&"debug_stage_validated", {
		"stage_id": stage_def.stage_id if stage_def != null else &"",
		"errors": errors.size(),
		"warnings": warnings.size(),
	})


func _join_strings(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(String(value))
	return separator.join(parts)
