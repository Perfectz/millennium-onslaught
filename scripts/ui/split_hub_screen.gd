## Base hub screen with 40/60 split layout, floating info card, and dialogue bar.
class_name SplitHubScreen
extends Control


signal selection_changed(index: int, entry: Dictionary)
signal entry_activated(index: int, entry: Dictionary)

const HighTechThemeRef = preload("res://scripts/ui/high_tech_theme.gd")
const PatternPlaceholderRef = preload("res://scripts/ui/pattern_placeholder.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _config: Dictionary = {}
var _entries: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _selected_index: int = -1
var _pause_menu: CanvasLayer = null

var _context_placeholder = null
var _context_video: VideoStreamPlayer = null
var _story_placeholder = null
var _story_video: VideoStreamPlayer = null
var _portrait_placeholder = null
var _portrait_texture: TextureRect = null

var _info_panel: PanelContainer
var _info_header_label: Label
var _info_title_label: Label
var _info_level_label: Label
var _info_description_label: Label
var _info_accent_bar: ColorRect

var _dialogue_panel: PanelContainer
var _dialogue_name_label: Label
var _dialogue_text_label: Label
var _dialogue_style: StyleBoxFlat

var _entry_transition_tween: Tween = null
var _active_accent: Color = Color(0.37, 0.92, 1.0, 1.0)

var _dialogue_thread: Array = []
var _dialogue_thread_index: int = 0
var _dialogue_timer: Timer = null
var _dialogue_cycle_tween: Tween = null


func configure(config: Dictionary) -> void:
	_config = config.duplicate(true)


func _ready() -> void:
	if _config.is_empty():
		push_error("SplitHubScreen: configure() must be called before _ready().")
		return

	HighTechThemeRef.apply_theme(self)
	_entries = _extract_entries(_config)
	_build_ui()
	_select_index(clampi(int(_config.get("initial_index", 0)), 0, maxi(_entries.size() - 1, 0)))
	_restore_focus.call_deferred()


func _process(_delta: float) -> void:
	if _pause_menu != null:
		return
	if _buttons.is_empty():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if vp.gui_get_focus_owner() == null:
		_restore_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return

	if event.is_action_pressed("pause"):
		vp.set_input_as_handled()
		_toggle_pause_menu()
		return

	if event.is_action_pressed("move_down"):
		vp.set_input_as_handled()
		_step_selection(1)
		return

	if event.is_action_pressed("move_up"):
		vp.set_input_as_handled()
		_step_selection(-1)
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		_on_cancel_requested()
		return

	if event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		vp.set_input_as_handled()
		_activate_current_entry()


func _on_entry_activated(_entry: Dictionary) -> void:
	pass


func _on_cancel_requested() -> void:
	pass


# ─── UI Construction ──────────────────────────────────────────────


func _build_ui() -> void:
	# === Layer 0: Animated background ===
	var background := PatternPlaceholderRef.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.set_content(
		str(_config.get("screen_background_title", "BACKGROUND FEED")),
		str(_config.get("screen_background_subtitle", "NO IMAGE ATTACHED"))
	)
	background.set_palette(
		Color(0.05, 0.07, 0.11, 1.0),
		Color(0.2, 0.45, 0.7, 1.0)
	)
	add_child(background)

	# === Layer 1: Nebula gradient overlay ===
	background.add_child(
		HighTechThemeRef.create_background_gradient(
			Color(0.03, 0.06, 0.1, 0.68),
			Color(0.01, 0.02, 0.04, 0.82)
		)
	)

	# === Layer 2: Ambient glow orb ===
	var glow := UIStyleRef.create_glow_orb(
		Color(_default_accent().r * 0.6, _default_accent().g * 0.6, _default_accent().b * 0.6),
		0.14
	)
	add_child(glow)

	# === Layer 3: Floating particles ===
	var particle_color := Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.12)
	add_child(UIStyleRef.create_particle_field(Vector2(1920, 1080), particle_color, 18))

	# === Layer 4: Content frame (inset from edges) ===
	var content_frame := Control.new()
	content_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_frame.offset_left = 32
	content_frame.offset_top = 28
	content_frame.offset_right = -32
	content_frame.offset_bottom = -24
	add_child(content_frame)

	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 20)
	content_frame.add_child(split)

	# Left column: 38% (slightly narrower for tighter list)
	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 3.8
	left_column.add_theme_constant_override("separation", 14)
	split.add_child(left_column)

	# Right column: 62%
	var right_column := Control.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.size_flags_stretch_ratio = 6.2
	split.add_child(right_column)

	_build_left_column(left_column)
	_build_right_column(right_column)

	# === Layer 5: Post-processing overlays ===
	add_child(UIStyleRef.create_vignette(0.35))
	if GameState.scanlines_enabled:
		add_child(UIStyleRef.create_scanlines(0.018))


func _build_left_column(left_column: VBoxContainer) -> void:
	# --- Navigation list panel ---
	var list_panel := PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_stretch_ratio = 5.5
	list_panel.add_theme_stylebox_override("panel",
		HighTechThemeRef.create_glass_panel_style(_default_accent(), 0.28, 0.7))
	left_column.add_child(list_panel)

	var list_margin := MarginContainer.new()
	list_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_margin.add_theme_constant_override("margin_left", 16)
	list_margin.add_theme_constant_override("margin_top", 14)
	list_margin.add_theme_constant_override("margin_right", 16)
	list_margin.add_theme_constant_override("margin_bottom", 14)
	list_panel.add_child(list_margin)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	list_margin.add_child(list_vbox)

	# Header row with accent dot
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	list_vbox.add_child(header_row)

	var header_dot := ColorRect.new()
	header_dot.custom_minimum_size = Vector2(4, 4)
	header_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_dot.color = Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.8)
	header_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(header_dot)

	var location_header := Label.new()
	location_header.text = str(_config.get("left_header", "LOCATIONS")).to_upper()
	location_header.add_theme_font_size_override("font_size", 13)
	location_header.add_theme_color_override("font_color", Color(
		_default_accent().r * 0.85 + 0.15,
		_default_accent().g * 0.85 + 0.15,
		_default_accent().b * 0.85 + 0.15))
	header_row.add_child(location_header)

	list_vbox.add_child(HighTechThemeRef.create_separator(
		Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.4), 1.0))

	# Scrollable button list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_vbox.add_child(scroll)

	var button_list := VBoxContainer.new()
	button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_list.add_theme_constant_override("separation", 6)
	scroll.add_child(button_list)

	for i in _entries.size():
		var entry := _entries[i]
		var accent := _entry_accent(entry)
		var button := Button.new()
		button.text = str(entry.get("menu_label", "UNKNOWN"))
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		HighTechThemeRef.style_nav_button(button, accent, 19)
		HighTechThemeRef.wire_focus_pop(button, 1.03)
		button.focus_entered.connect(_on_list_button_focused.bind(i))
		button.mouse_entered.connect(_on_list_button_hovered.bind(button))
		button.pressed.connect(_on_list_button_pressed.bind(i))
		UIStyleRef.wire_button_sounds(button)
		UIStyleRef.add_press_feedback(button, 0.97)
		button_list.add_child(button)
		_buttons.append(button)

	_wire_list_focus()

	# Optional back button (enabled via config "back_button_label").
	var back_label: String = str(_config.get("back_button_label", ""))
	if not back_label.is_empty():
		list_vbox.add_child(HighTechThemeRef.create_separator(
			Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.25), 1.0))
		var back_btn := Button.new()
		back_btn.text = back_label
		back_btn.custom_minimum_size = Vector2(0, 46)
		back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		HighTechThemeRef.style_nav_button(back_btn, Color(0.85, 0.55, 0.55), 17)
		HighTechThemeRef.wire_focus_pop(back_btn, 1.02)
		UIStyleRef.wire_button_sounds(back_btn)
		UIStyleRef.add_press_feedback(back_btn, 0.97)
		back_btn.pressed.connect(_on_cancel_requested)
		list_vbox.add_child(back_btn)
		# Wire focus between last entry button and back button.
		if not _buttons.is_empty():
			var last := _buttons[_buttons.size() - 1]
			last.focus_neighbor_bottom = last.get_path_to(back_btn)
			back_btn.focus_neighbor_top = back_btn.get_path_to(last)
			_buttons[0].focus_neighbor_top = _buttons[0].get_path_to(back_btn)
			back_btn.focus_neighbor_bottom = back_btn.get_path_to(_buttons[0])

	UIStyleRef.stagger_entrance(_buttons as Array, 0.05, Vector2(-24, 0))

	# --- Map video panel (lower-left, own bounding box) ---
	var map_panel := PanelContainer.new()
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 4.5
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.clip_contents = true
	map_panel.add_theme_stylebox_override("panel",
		HighTechThemeRef.create_glass_panel_style(_default_accent(), 0.32, 0.8))
	left_column.add_child(map_panel)

	var map_margin := MarginContainer.new()
	map_margin.add_theme_constant_override("margin_left", 12)
	map_margin.add_theme_constant_override("margin_top", 10)
	map_margin.add_theme_constant_override("margin_right", 12)
	map_margin.add_theme_constant_override("margin_bottom", 10)
	map_panel.add_child(map_margin)

	var map_vbox := VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 8)
	map_margin.add_child(map_vbox)

	# Header row with accent dot
	var map_header_row := HBoxContainer.new()
	map_header_row.add_theme_constant_override("separation", 6)
	map_vbox.add_child(map_header_row)

	var map_dot := ColorRect.new()
	map_dot.custom_minimum_size = Vector2(4, 4)
	map_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	map_dot.color = Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.8)
	map_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_header_row.add_child(map_dot)

	var map_header_label := Label.new()
	map_header_label.text = "MOTAVIA MAP"
	map_header_label.add_theme_font_size_override("font_size", 11)
	map_header_label.add_theme_color_override("font_color", Color(
		_default_accent().r * 0.85 + 0.15,
		_default_accent().g * 0.85 + 0.15,
		_default_accent().b * 0.85 + 0.15, 0.8))
	map_header_row.add_child(map_header_label)

	map_vbox.add_child(HighTechThemeRef.create_separator(
		Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.3), 1.0))

	# Video in 16:9 aspect, filling remaining space in the box
	var map_aspect := AspectRatioContainer.new()
	map_aspect.ratio = 16.0 / 9.0
	map_aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	map_aspect.clip_contents = true
	map_vbox.add_child(map_aspect)

	_context_video = VideoStreamPlayer.new()
	_context_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_context_video.expand = true
	_context_video.loop = true
	_context_video.visible = false
	map_aspect.add_child(_context_video)

	_context_placeholder = PatternPlaceholderRef.new()
	_context_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_aspect.add_child(_context_placeholder)


func _build_right_column(right_column: Control) -> void:
	# Vertical stack: unified info+video panel (expands) + dialogue panel (fixed height).
	var right_vbox := VBoxContainer.new()
	right_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_vbox.add_theme_constant_override("separation", 10)
	right_column.add_child(right_vbox)

	# --- Unified info + video panel (expands to fill) ---
	_info_panel = PanelContainer.new()
	_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_panel.add_theme_stylebox_override("panel",
		HighTechThemeRef.create_glass_panel_style(_default_accent(), 0.28, 0.7))
	right_vbox.add_child(_info_panel)

	var unified_margin := MarginContainer.new()
	unified_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	unified_margin.add_theme_constant_override("margin_left", 18)
	unified_margin.add_theme_constant_override("margin_top", 14)
	unified_margin.add_theme_constant_override("margin_right", 18)
	unified_margin.add_theme_constant_override("margin_bottom", 14)
	_info_panel.add_child(unified_margin)

	var unified_vbox := VBoxContainer.new()
	unified_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	unified_vbox.add_theme_constant_override("separation", 8)
	unified_margin.add_child(unified_vbox)

	# Header row with accent dot
	var info_header_row := HBoxContainer.new()
	info_header_row.add_theme_constant_override("separation", 6)
	unified_vbox.add_child(info_header_row)

	var info_dot := ColorRect.new()
	info_dot.custom_minimum_size = Vector2(4, 4)
	info_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_dot.color = Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.8)
	info_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_header_row.add_child(info_dot)

	_info_header_label = Label.new()
	_info_header_label.text = str(_config.get("info_header", "MISSION BRIEF")).to_upper()
	_info_header_label.add_theme_font_size_override("font_size", 12)
	_info_header_label.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	info_header_row.add_child(_info_header_label)

	unified_vbox.add_child(HighTechThemeRef.create_separator(
		Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.4), 1.0))

	# Title
	_info_title_label = Label.new()
	_info_title_label.add_theme_font_size_override("font_size", 26)
	_info_title_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	_info_title_label.add_theme_constant_override("outline_size", 2)
	_info_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	_info_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unified_vbox.add_child(_info_title_label)

	# Accent underline
	_info_accent_bar = ColorRect.new()
	_info_accent_bar.custom_minimum_size = Vector2(60, 2)
	_info_accent_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_info_accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_accent_bar.color = _default_accent()
	unified_vbox.add_child(_info_accent_bar)

	# Level / type label
	_info_level_label = Label.new()
	_info_level_label.add_theme_font_size_override("font_size", 14)
	_info_level_label.add_theme_color_override("font_color", Color(0.5, 0.82, 0.95))
	unified_vbox.add_child(_info_level_label)

	# Description (2-liner)
	_info_description_label = Label.new()
	_info_description_label.add_theme_font_size_override("font_size", 16)
	_info_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_description_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.9))
	_info_description_label.add_theme_constant_override("line_spacing", 4)
	unified_vbox.add_child(_info_description_label)

	# Story video (16:9 aspect, fills remaining vertical space)
	var story_aspect := AspectRatioContainer.new()
	story_aspect.ratio = 16.0 / 9.0
	story_aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_aspect.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	unified_vbox.add_child(story_aspect)

	_story_video = VideoStreamPlayer.new()
	_story_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_video.expand = true
	_story_video.loop = true
	_story_video.visible = false
	story_aspect.add_child(_story_video)

	_story_placeholder = PatternPlaceholderRef.new()
	_story_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_aspect.add_child(_story_placeholder)

	# --- Dialogue panel (fixed height at bottom) ---
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_panel.custom_minimum_size = Vector2(0, 150)
	_dialogue_style = HighTechThemeRef.create_glass_panel_style(_default_accent(), 0.44, 0.88)
	_dialogue_style.border_width_left = 3
	_dialogue_panel.add_theme_stylebox_override("panel", _dialogue_style)
	right_vbox.add_child(_dialogue_panel)

	var dialogue_margin := MarginContainer.new()
	dialogue_margin.add_theme_constant_override("margin_left", 16)
	dialogue_margin.add_theme_constant_override("margin_top", 12)
	dialogue_margin.add_theme_constant_override("margin_right", 16)
	dialogue_margin.add_theme_constant_override("margin_bottom", 12)
	_dialogue_panel.add_child(dialogue_margin)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	dialogue_margin.add_child(row)

	# Portrait with accent frame
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(120, 120)
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel",
		HighTechThemeRef.create_glass_panel_style(_default_accent(), 0.2, 0.65))
	row.add_child(portrait_frame)

	var portrait_aspect := AspectRatioContainer.new()
	portrait_aspect.ratio = 1.0
	portrait_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	portrait_aspect.clip_contents = true
	portrait_frame.add_child(portrait_aspect)

	_portrait_placeholder = PatternPlaceholderRef.new()
	_portrait_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_aspect.add_child(_portrait_placeholder)

	_portrait_texture = TextureRect.new()
	_portrait_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_texture.visible = false
	portrait_aspect.add_child(_portrait_texture)

	# Text column
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)

	# Dialogue header
	var comms_header := Label.new()
	comms_header.text = str(_config.get("dialogue_header", "COMMS"))
	comms_header.add_theme_font_size_override("font_size", 11)
	comms_header.add_theme_color_override("font_color", Color(
		_default_accent().r * 0.7 + 0.3,
		_default_accent().g * 0.7 + 0.3,
		_default_accent().b * 0.7 + 0.3, 0.7))
	text_col.add_child(comms_header)

	text_col.add_child(HighTechThemeRef.create_separator(
		Color(_default_accent().r, _default_accent().g, _default_accent().b, 0.3), 1.0))

	# Speaker name
	_dialogue_name_label = Label.new()
	_dialogue_name_label.add_theme_font_size_override("font_size", 19)
	_dialogue_name_label.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	_dialogue_name_label.add_theme_constant_override("outline_size", 1)
	_dialogue_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	text_col.add_child(_dialogue_name_label)

	# Dialogue text
	_dialogue_text_label = Label.new()
	_dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text_label.add_theme_font_size_override("font_size", 16)
	_dialogue_text_label.add_theme_color_override("font_color", Color(0.75, 0.84, 0.92))
	_dialogue_text_label.add_theme_constant_override("line_spacing", 3)
	text_col.add_child(_dialogue_text_label)

	# Hint text at very bottom of screen
	var hint := Label.new()
	hint.anchor_left = 0.0
	hint.anchor_top = 1.0
	hint.anchor_right = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -16
	hint.offset_bottom = -2
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = str(_config.get("hint_text", "UP/DOWN: SELECT  |  ENTER: CONFIRM  |  START: PAUSE"))
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.42, 0.56, 0.68))
	add_child(hint)


# ─── Data & Selection ─────────────────────────────────────────────


func _extract_entries(config: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw_entries: Variant = config.get("entries", [])
	if raw_entries is Array:
		for item in raw_entries:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result


func _wire_list_focus() -> void:
	if _buttons.is_empty():
		return
	for i in _buttons.size():
		var previous := (i - 1 + _buttons.size()) % _buttons.size()
		var next := (i + 1) % _buttons.size()
		_buttons[i].focus_neighbor_top = _buttons[i].get_path_to(_buttons[previous])
		_buttons[i].focus_neighbor_bottom = _buttons[i].get_path_to(_buttons[next])
		_buttons[i].focus_neighbor_left = _buttons[i].get_path_to(_buttons[i])
		_buttons[i].focus_neighbor_right = _buttons[i].get_path_to(_buttons[i])


func _on_list_button_focused(index: int) -> void:
	_select_index(index)


func _on_list_button_hovered(button: Button) -> void:
	button.grab_focus()


func _on_list_button_pressed(index: int) -> void:
	_select_index(index)
	_activate_current_entry()


func _step_selection(direction: int) -> void:
	if _entries.is_empty():
		return
	var next_index := _selected_index
	if next_index < 0:
		next_index = 0
	else:
		next_index = wrapi(next_index + direction, 0, _entries.size())
	_select_index(next_index)
	_restore_focus()


func _restore_focus() -> void:
	if _selected_index < 0 or _selected_index >= _buttons.size():
		return
	_buttons[_selected_index].grab_focus()


func _select_index(index: int) -> void:
	if _entries.is_empty() or index < 0 or index >= _entries.size():
		return
	_selected_index = index
	_apply_entry(_entries[index])
	_update_button_state()
	selection_changed.emit(index, _entries[index])


func _update_button_state() -> void:
	for i in _buttons.size():
		var button := _buttons[i]
		var is_selected := i == _selected_index
		if is_selected:
			button.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
			button.self_modulate = Color(1.12, 1.14, 1.16)
		else:
			button.add_theme_color_override("font_color", Color(0.65, 0.75, 0.84))
			button.self_modulate = Color(0.85, 0.88, 0.9)


# ─── Entry Transitions ────────────────────────────────────────────


func _apply_entry(entry: Dictionary) -> void:
	var accent := _entry_accent(entry)
	_active_accent = accent
	var title := str(entry.get("title", "UNKNOWN"))
	var level_suggestion := str(entry.get("level", "N/A"))
	var description := str(entry.get("description", "No description."))
	var speaker_name := str(entry.get("speaker", "Operator"))
	var dialogue_line := str(entry.get("dialogue", ""))

	if _entry_transition_tween and _entry_transition_tween.is_valid():
		_entry_transition_tween.kill()

	var fade_targets: Array[Control] = [
		_info_title_label, _info_level_label, _info_description_label,
		_dialogue_name_label, _dialogue_text_label,
	]

	_entry_transition_tween = create_tween()
	_entry_transition_tween.set_trans(Tween.TRANS_QUAD)
	_entry_transition_tween.set_ease(Tween.EASE_OUT)

	# Phase 1: Fade out text + portrait + slide info accent bar
	for ctrl in fade_targets:
		_entry_transition_tween.parallel().tween_property(ctrl, "modulate:a", 0.0, 0.07)
	_entry_transition_tween.parallel().tween_property(_portrait_texture, "modulate:a", 0.0, 0.07)
	_entry_transition_tween.parallel().tween_property(
		_info_accent_bar, "custom_minimum_size:x", 0.0, 0.07)

	# Phase 2: Update content at the midpoint
	_entry_transition_tween.tween_callback(func() -> void:
		_info_title_label.text = title.to_upper()
		_info_level_label.text = level_suggestion.to_upper()
		_info_description_label.text = description
		_dialogue_name_label.text = speaker_name
		_dialogue_text_label.text = dialogue_line

		# Update accent colors on dynamic elements
		_info_accent_bar.color = accent
		if _dialogue_style:
			_dialogue_style.border_color = Color(accent.r, accent.g, accent.b, _dialogue_style.border_color.a)

		# Map video (lower-left)
		_apply_video_or_placeholder(
			str(entry.get("map_video", "")),
			_context_video, _context_placeholder,
			str(entry.get("context_title", "CONTEXT PANEL")),
			str(entry.get("context_subtitle", "NO VISUAL ATTACHED")),
			Color(0.06, 0.09, 0.15, 0.82), accent
		)

		# Story video (large right area)
		_apply_video_or_placeholder(
			str(entry.get("story_video", "")),
			_story_video, _story_placeholder,
			str(entry.get("story_title", "STORY CUE")),
			str(entry.get("story_subtitle", "VISUAL PLACEHOLDER")),
			Color(0.08, 0.08, 0.14, 0.8),
			Color(accent.r, accent.g, accent.b, 1.0)
		)

		_apply_portrait(
			str(entry.get("portrait_image", "")),
			str(entry.get("portrait_code", "NO PORTRAIT")),
			accent, true
		)

		# Start dialogue thread cycling if present
		_start_dialogue_thread(entry, accent)
	)

	# Phase 3: Fade in text + portrait + extend accent bar
	for ctrl in fade_targets:
		_entry_transition_tween.parallel().tween_property(ctrl, "modulate:a", 1.0, 0.12)
	_entry_transition_tween.parallel().tween_property(_portrait_texture, "modulate:a", 1.0, 0.12)
	_entry_transition_tween.parallel().tween_property(
		_info_accent_bar, "custom_minimum_size:x", 60.0, 0.18).set_trans(Tween.TRANS_QUAD)


func _activate_current_entry() -> void:
	if _selected_index < 0 or _selected_index >= _entries.size():
		return
	var entry := _entries[_selected_index]
	entry_activated.emit(_selected_index, entry)
	_on_entry_activated(entry)


func _entry_accent(entry: Dictionary) -> Color:
	var accent_variant: Variant = entry.get("accent", _default_accent())
	if accent_variant is Color:
		return accent_variant
	return _default_accent()


func _default_accent() -> Color:
	var accent_variant: Variant = _config.get("default_accent", Color(0.37, 0.92, 1.0, 1.0))
	if accent_variant is Color:
		return accent_variant
	return Color(0.37, 0.92, 1.0, 1.0)


# ─── Dialogue Thread Cycling ──────────────────────────────────────


## Start looping through a dialogue_thread array, or stop if none exists.
func _start_dialogue_thread(entry: Dictionary, accent: Color) -> void:
	# Stop any existing cycle
	if _dialogue_timer and _dialogue_timer.is_inside_tree():
		_dialogue_timer.stop()
		_dialogue_timer.queue_free()
		_dialogue_timer = null
	if _dialogue_cycle_tween and _dialogue_cycle_tween.is_valid():
		_dialogue_cycle_tween.kill()

	var thread_raw: Variant = entry.get("dialogue_thread", [])
	_dialogue_thread = []
	if thread_raw is Array:
		for item in thread_raw:
			if item is Dictionary:
				_dialogue_thread.append(item)

	if _dialogue_thread.size() < 2:
		_dialogue_thread = []
		return

	_dialogue_thread_index = 0

	_dialogue_timer = Timer.new()
	_dialogue_timer.wait_time = 5.0
	_dialogue_timer.one_shot = false
	_dialogue_timer.timeout.connect(_advance_dialogue_thread.bind(accent))
	add_child(_dialogue_timer)
	_dialogue_timer.start()


## Advance to the next line in the dialogue thread with a fade transition.
func _advance_dialogue_thread(accent: Color) -> void:
	if _dialogue_thread.is_empty():
		return
	_dialogue_thread_index = (_dialogue_thread_index + 1) % _dialogue_thread.size()
	var line: Dictionary = _dialogue_thread[_dialogue_thread_index]
	var next_speaker := str(line.get("speaker", "???"))
	var next_text := str(line.get("dialogue", ""))
	var next_portrait := str(line.get("portrait_code", "NO PORTRAIT"))
	var next_portrait_image := str(line.get("portrait_image", ""))

	if _dialogue_cycle_tween and _dialogue_cycle_tween.is_valid():
		_dialogue_cycle_tween.kill()

	_dialogue_cycle_tween = create_tween()
	_dialogue_cycle_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out text + portrait
	_dialogue_cycle_tween.parallel().tween_property(_dialogue_name_label, "modulate:a", 0.0, 0.15)
	_dialogue_cycle_tween.parallel().tween_property(_dialogue_text_label, "modulate:a", 0.0, 0.15)
	_dialogue_cycle_tween.parallel().tween_property(_portrait_texture, "modulate:a", 0.0, 0.15)

	# Swap content (portrait starts at alpha 0, faded in below)
	_dialogue_cycle_tween.tween_callback(func() -> void:
		_dialogue_name_label.text = next_speaker
		_dialogue_text_label.text = next_text
		_apply_portrait(next_portrait_image, next_portrait, accent, true)
	)

	# Fade in text + portrait
	_dialogue_cycle_tween.parallel().tween_property(_dialogue_name_label, "modulate:a", 1.0, 0.2)
	_dialogue_cycle_tween.parallel().tween_property(_dialogue_text_label, "modulate:a", 1.0, 0.2)
	_dialogue_cycle_tween.parallel().tween_property(_portrait_texture, "modulate:a", 1.0, 0.2)


## Load a portrait image or fall back to the pattern placeholder.
func _apply_portrait(image_path: String, portrait_code: String, accent: Color, fade_start: bool = false) -> void:
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		var tex: Texture2D = load(image_path)
		if tex:
			_portrait_texture.texture = tex
			_portrait_texture.visible = true
			_portrait_texture.modulate = Color(1, 1, 1, 0.0 if fade_start else 1.0)
			_portrait_placeholder.visible = false
			return
	# Fallback to pattern placeholder
	_portrait_texture.visible = false
	_portrait_placeholder.visible = true
	_portrait_placeholder.set_content("PORTRAIT", portrait_code)
	_portrait_placeholder.set_palette(
		Color(0.06, 0.08, 0.14, 0.9),
		Color(accent.r, accent.g, accent.b, 1.0)
	)


# ─── Video Helpers ────────────────────────────────────────────────


## Swap between video playback and pattern placeholder fallback.
func _apply_video_or_placeholder(
	video_path: String,
	video_player: VideoStreamPlayer,
	placeholder: Control,
	fallback_title: String,
	fallback_subtitle: String,
	bg_color: Color,
	accent_color: Color
) -> void:
	if not video_path.is_empty() and ResourceLoader.exists(video_path):
		var stream: VideoStream = load(video_path)
		if stream:
			video_player.stream = stream
			video_player.visible = true
			video_player.play()
			placeholder.visible = false
			return
	# Fallback to pattern placeholder
	video_player.stop()
	video_player.visible = false
	placeholder.visible = true
	placeholder.set_content(fallback_title, fallback_subtitle)
	placeholder.set_palette(bg_color, accent_color)


# ─── Pause Menu ───────────────────────────────────────────────────


func _toggle_pause_menu() -> void:
	if _pause_menu != null:
		_resume_from_pause()
		return
	visible = false
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(PauseMenuScript)
	add_child(_pause_menu)
	_pause_menu.resumed.connect(_resume_from_pause)
	get_tree().paused = true


func _resume_from_pause() -> void:
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
	visible = true
	get_tree().paused = false
	_restore_focus()
