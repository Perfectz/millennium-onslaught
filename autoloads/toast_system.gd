## Queued toast notification system. Shows brief messages that auto-dismiss.
## E.g. "+50 Gold", "Level Up!", "New Area Unlocked".
class_name ToastSystemSingleton
extends Node


const MAX_VISIBLE: int = 4
const TOAST_LIFETIME: float = 2.5
const TOAST_FADE_TIME: float = 0.4
const TOAST_SLIDE_OFFSET: float = 40.0
const TOAST_SPACING: float = 8.0
const TOAST_MARGIN_RIGHT: float = 24.0
const TOAST_MARGIN_TOP: float = 100.0

var _canvas: CanvasLayer
var _container: VBoxContainer
var _queue: Array[Dictionary] = []
var _active_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_connect_events()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "ToastCanvas"
	_canvas.layer = 95
	_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas)

	# Anchor container to top-right
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(anchor)

	_container = VBoxContainer.new()
	_container.name = "ToastContainer"
	_container.set_anchor_and_offset(SIDE_RIGHT, 1.0, -TOAST_MARGIN_RIGHT)
	_container.set_anchor_and_offset(SIDE_TOP, 0.0, TOAST_MARGIN_TOP)
	_container.set_anchor_and_offset(SIDE_LEFT, 1.0, -350.0)
	_container.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 500.0)
	_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_container.add_theme_constant_override("separation", int(TOAST_SPACING))
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(_container)


func _connect_events() -> void:
	EventBus.rpg_gold_changed.connect(func(new_total: int) -> void:
		show_toast("Gold: %d" % new_total, Color(1.0, 0.85, 0.3))
	)
	EventBus.rpg_level_up.connect(func(_pi: int, new_level: int) -> void:
		show_toast("Level Up! Lv.%d" % new_level, Color(0.4, 1.0, 0.6))
	)
	EventBus.overworld_node_unlocked.connect(func(node_id: StringName) -> void:
		show_toast("Area Unlocked: %s" % str(node_id).capitalize(), Color(0.5, 0.8, 1.0))
	)
	EventBus.rpg_skill_unlocked.connect(func(_pi: int, skill_id: StringName) -> void:
		show_toast("Skill Learned: %s" % str(skill_id).capitalize(), Color(0.9, 0.6, 1.0))
	)
	EventBus.save_completed.connect(func(slot: int) -> void:
		show_toast("Game Saved (Slot %d)" % slot, Color(0.7, 0.9, 0.7))
	)
	EventBus.dungeon_room_cleared.connect(func(_ri: int) -> void:
		show_toast("Room Cleared!", Color(0.7, 0.95, 1.0))
	)


## Show a toast notification with text and optional accent color.
func show_toast(text: String, color: Color = Color(0.8, 0.9, 1.0)) -> void:
	if _active_count >= MAX_VISIBLE:
		_queue.append({"text": text, "color": color})
		return
	_spawn_toast(text, color)


func _spawn_toast(text: String, color: Color) -> void:
	_active_count += 1

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.85)
	style.border_color = Color(color.r, color.g, color.b, 0.5)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(label)

	_container.add_child(panel)

	# Slide in from right + fade in
	panel.position.x += TOAST_SLIDE_OFFSET
	var intro := panel.create_tween()
	intro.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(panel, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Auto-dismiss after lifetime
	var timer := get_tree().create_timer(TOAST_LIFETIME, true, false, true)
	timer.timeout.connect(func() -> void: _dismiss_toast(panel))


func _dismiss_toast(panel: PanelContainer) -> void:
	if not is_instance_valid(panel):
		_active_count = maxi(_active_count - 1, 0)
		_flush_queue()
		return

	var outro := panel.create_tween()
	outro.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.tween_property(panel, "modulate:a", 0.0, TOAST_FADE_TIME).set_ease(Tween.EASE_IN)
	outro.parallel().tween_property(panel, "position:x", TOAST_SLIDE_OFFSET, TOAST_FADE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outro.tween_callback(func() -> void:
		panel.queue_free()
		_active_count = maxi(_active_count - 1, 0)
		_flush_queue()
	)


func _flush_queue() -> void:
	while not _queue.is_empty() and _active_count < MAX_VISIBLE:
		var item: Dictionary = _queue.pop_front()
		_spawn_toast(item["text"], item["color"])
