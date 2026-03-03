## Debug overlay toggled with F3 (enemy AI states) and F4 (performance stats).
## Attaches to the HUD as a CanvasLayer child. PROCESS_MODE_ALWAYS to work during pause.
class_name DebugOverlay
extends CanvasLayer


var _perf_visible: bool = false
var _ai_visible: bool = false
var _perf_label: Label = null
var _ai_labels: Dictionary = {}  # enemy instance_id -> Label3D


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_perf_label()
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F3:
		_ai_visible = not _ai_visible
		_update_ai_labels_visibility()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F4:
		_perf_visible = not _perf_visible
		_perf_label.visible = _perf_visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _perf_visible:
		_update_perf()
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
