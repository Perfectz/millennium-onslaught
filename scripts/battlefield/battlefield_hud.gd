## Battlefield overlay on top of the standard HUD: KO counter, morale, Combination gauge,
## base status, officer banners, and a live minimap. Built in code; listens on EventBus and
## polls the run (via `bind`) a few times per second for minimap data.
class_name BattlefieldHUD
extends CanvasLayer


const PANEL_BG := Color(0.03, 0.05, 0.09, 0.78)
const PANEL_BORDER := Color(0.38, 0.62, 0.95, 0.7)
const GAUGE_COLOR := Color(1.0, 0.78, 0.25)
const GAUGE_READY_COLOR := Color(1.0, 0.95, 0.55)
const MINIMAP_SIZE: float = 230.0
const MINIMAP_REFRESH: float = 0.1
const BANNER_TIME: float = 2.6

var _ko_label: Label
var _ko_pop: float = 0.0
var _morale_bar: ProgressBar
var _gauge_bar: ProgressBar
var _gauge_label: Label
var _gauge_ready: bool = false
var _bases_box: VBoxContainer
var _banner: Label
var _banner_timer: float = 0.0
var _minimap: BattlefieldMinimap
var _time: float = 0.0
var _refresh_timer: float = 0.0
var _run: Node = null


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_ko_counter(root)
	_build_gauge(root)
	_build_bases_panel(root)
	_build_banner(root)
	_minimap = BattlefieldMinimap.new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.anchor_top = 1.0
	_minimap.anchor_bottom = 1.0
	_minimap.offset_left = -MINIMAP_SIZE - 24.0
	_minimap.offset_right = -24.0
	_minimap.offset_top = -MINIMAP_SIZE - 24.0
	_minimap.offset_bottom = -24.0
	root.add_child(_minimap)
	EventBus.battlefield_ko_count_changed.connect(_on_ko_changed)
	EventBus.battlefield_morale_changed.connect(_on_morale_changed)
	EventBus.player_combination_changed.connect(_on_gauge_changed)
	EventBus.battlefield_officer_spawned.connect(func(_o: Node, n: String) -> void: show_banner("%s has taken the field!" % n, Color(1.0, 0.6, 0.35)))
	EventBus.battlefield_officer_defeated.connect(func(_o: Node, n: String) -> void: show_banner("%s defeated!" % n, Color(1.0, 0.9, 0.5)))
	EventBus.battlefield_base_captured.connect(func(_id: StringName, n: String) -> void: show_banner("%s captured!" % n, BattlefieldBaseMarker.ALLY_COLOR.lightened(0.3)))
	EventBus.battlefield_ko_milestone.connect(func(c: int) -> void: show_banner("%d KO!" % c, GAUGE_READY_COLOR))


## Give the HUD a run to poll for bases/minimap (BattlefieldRun).
func bind(run: Node) -> void:
	_run = run
	_minimap.bind(run)
	_refresh_bases()


## Big centre-screen callout (officer defeated, base captured...).
func show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(1.25, 1.25)
	_banner_timer = BANNER_TIME


func _process(delta: float) -> void:
	_time += delta
	if _ko_pop > 0.0:
		_ko_pop = maxf(_ko_pop - delta * 4.0, 0.0)
		_ko_label.scale = Vector2.ONE * (1.0 + _ko_pop * 0.25)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		_banner.scale = _banner.scale.lerp(Vector2.ONE, minf(delta * 10.0, 1.0))
		_banner.modulate.a = clampf(_banner_timer / 0.5, 0.0, 1.0)
	if _gauge_ready:
		var glow := 0.75 + 0.25 * sin(_time * 8.0)
		_gauge_bar.modulate = Color(1.0, 1.0, 1.0) * (1.0 + glow * 0.4)
		_gauge_label.modulate.a = glow
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = MINIMAP_REFRESH
		_minimap.queue_redraw()
		_refresh_bases()


func _on_ko_changed(count: int) -> void:
	_ko_label.text = "%d KO" % count
	_ko_pop = 1.0


func _on_morale_changed(morale: float) -> void:
	_morale_bar.value = morale


func _on_gauge_changed(player_index: int, value: float, max_value: float) -> void:
	if player_index != 0:
		return
	_gauge_bar.max_value = max_value
	_gauge_bar.value = value
	_gauge_ready = value >= max_value
	if _gauge_ready:
		_gauge_label.text = "COMBINATION READY  —  [F] / SELECT"
		_gauge_label.add_theme_color_override("font_color", GAUGE_READY_COLOR)
	else:
		_gauge_label.text = "COMBINATION"
		_gauge_label.add_theme_color_override("font_color", GAUGE_COLOR)
		_gauge_label.modulate.a = 1.0
		_gauge_bar.modulate = Color.WHITE


func _refresh_bases() -> void:
	if _run == null or not _run.has_method("get_base_status"):
		return
	var status: Array = _run.get_base_status()
	while _bases_box.get_child_count() < status.size():
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 15)
		_bases_box.add_child(row)
	for i in status.size():
		var s: Dictionary = status[i]
		var row := _bases_box.get_child(i) as Label
		var ally: bool = s["side"] == BattlefieldControl.Side.ALLY
		row.text = "%s  %s" % ["◆" if ally else "◇", s["name"]]
		if not ally:
			row.text += "   ·  %d guards" % int(s["remaining"])
		row.add_theme_color_override("font_color", BattlefieldBaseMarker.ALLY_COLOR.lightened(0.35) if ally else BattlefieldBaseMarker.ENEMY_COLOR.lightened(0.35))


func _build_ko_counter(root: Control) -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -170.0
	box.offset_right = 170.0
	box.offset_top = 56.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	_ko_label = Label.new()
	_ko_label.text = "0 KO"
	_ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ko_label.add_theme_font_size_override("font_size", 40)
	_ko_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	_ko_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	_ko_label.add_theme_constant_override("outline_size", 8)
	_ko_label.pivot_offset = Vector2(170.0, 24.0)
	box.add_child(_ko_label)
	var morale_row := HBoxContainer.new()
	morale_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(morale_row)
	var enemy_tag := Label.new()
	enemy_tag.text = "HIVES"
	enemy_tag.add_theme_font_size_override("font_size", 12)
	enemy_tag.add_theme_color_override("font_color", BattlefieldBaseMarker.ENEMY_COLOR.lightened(0.3))
	morale_row.add_child(enemy_tag)
	_morale_bar = ProgressBar.new()
	_morale_bar.min_value = Constants.MORALE_MIN
	_morale_bar.max_value = Constants.MORALE_MAX
	_morale_bar.value = 0.0
	_morale_bar.show_percentage = false
	_morale_bar.custom_minimum_size = Vector2(200, 10)
	_morale_bar.add_theme_stylebox_override("background", _flat(BattlefieldBaseMarker.ENEMY_COLOR.darkened(0.2)))
	_morale_bar.add_theme_stylebox_override("fill", _flat(BattlefieldBaseMarker.ALLY_COLOR))
	morale_row.add_child(_morale_bar)
	var ally_tag := Label.new()
	ally_tag.text = "HUNTERS"
	ally_tag.add_theme_font_size_override("font_size", 12)
	ally_tag.add_theme_color_override("font_color", BattlefieldBaseMarker.ALLY_COLOR.lightened(0.3))
	morale_row.add_child(ally_tag)


func _build_gauge(root: Control) -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -240.0
	box.offset_right = 240.0
	box.offset_top = -92.0
	box.offset_bottom = -40.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	_gauge_label = Label.new()
	_gauge_label.text = "COMBINATION"
	_gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gauge_label.add_theme_font_size_override("font_size", 15)
	_gauge_label.add_theme_color_override("font_color", GAUGE_COLOR)
	_gauge_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_gauge_label.add_theme_constant_override("outline_size", 5)
	box.add_child(_gauge_label)
	_gauge_bar = ProgressBar.new()
	_gauge_bar.max_value = Constants.COMBINATION_GAUGE_MAX
	_gauge_bar.show_percentage = false
	_gauge_bar.custom_minimum_size = Vector2(480, 16)
	_gauge_bar.add_theme_stylebox_override("background", _flat(Color(0.08, 0.06, 0.02, 0.85), PANEL_BORDER))
	_gauge_bar.add_theme_stylebox_override("fill", _flat(GAUGE_COLOR))
	box.add_child(_gauge_bar)


func _build_bases_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -300.0
	panel.offset_right = -24.0
	panel.offset_top = 64.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _flat(PANEL_BG, PANEL_BORDER)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "BATTLE LINES"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.58, 0.8, 1.0))
	vbox.add_child(header)
	_bases_box = VBoxContainer.new()
	vbox.add_child(_bases_box)


func _build_banner(root: Control) -> void:
	_banner = Label.new()
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.3
	_banner.anchor_bottom = 0.3
	_banner.offset_top = -30.0
	_banner.offset_bottom = 30.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0))
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0.0
	_banner.pivot_offset = Vector2(960.0, 30.0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_banner)


static func _flat(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	if border.a > 0.0:
		s.border_color = border
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
	return s
