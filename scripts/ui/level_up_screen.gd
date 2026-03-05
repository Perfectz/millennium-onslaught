## Level-up notification with stat allocation.
## Pops up when a character levels up during gameplay.
class_name LevelUpScreen
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _char_id: StringName = &""
var _new_level: int = 1

var _overlay: ColorRect
var _card: PanelContainer
var _stats_panel: VBoxContainer
var _points_label: Label
var _continue_btn: Button
var _alloc_buttons: Array[Button] = []


## Call before adding to tree.
func setup(char_id: StringName, new_level: int) -> void:
	_char_id = char_id
	_new_level = new_level


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full-screen overlay.
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.02, 0.06, 0.85)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	UIStyleRef.apply_screen_effects(_overlay, Color(1.0, 0.85, 0.3, 0.12), 10, Color(0.6, 0.5, 0.1))

	# Centered card.
	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.custom_minimum_size = Vector2(560, 480)
	_card.position = Vector2(-280, -240)
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.08, 0.07, 0.12, 0.55),
		Color(0.85, 0.75, 0.3, 0.3),
		6
	))
	add_child(_card)
	UIStyleRef.apply_theme(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_card.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)

	# Title.
	var title := Label.new()
	title.text = "LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	main_vbox.add_child(title)
	UIStyleRef.start_glow_pulse(title, Color(1.15, 1.1, 0.9), Color(0.95, 0.9, 0.8), 2.0)

	# Character name + level.
	var char_name: String = Constants.CHARACTER_DISPLAY_NAMES.get(_char_id, str(_char_id))
	var name_label := Label.new()
	name_label.text = "%s  →  Level %d" % [char_name, _new_level]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	main_vbox.add_child(name_label)

	main_vbox.add_child(UIStyleRef.create_separator(Color(0.85, 0.75, 0.3, 0.35)))

	# Auto stat growth display.
	var growth: Dictionary = Constants.CHARACTER_STAT_GROWTH.get(_char_id, Constants.DEFAULT_STAT_GROWTH)
	if not growth.is_empty():
		var growth_label := Label.new()
		growth_label.text = "Auto Growth:"
		growth_label.add_theme_font_size_override("font_size", 15)
		growth_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
		main_vbox.add_child(growth_label)
		var growth_row := HBoxContainer.new()
		growth_row.add_theme_constant_override("separation", 16)
		growth_row.alignment = BoxContainer.ALIGNMENT_CENTER
		main_vbox.add_child(growth_row)
		var stat_colors: Dictionary = {
			&"strength": Color(0.95, 0.7, 0.5),
			&"magic": Color(0.6, 0.7, 1.0),
			&"defense": Color(0.6, 0.9, 0.6),
			&"agility": Color(0.9, 0.9, 0.5),
		}
		for stat_key: StringName in growth:
			var val: int = growth[stat_key]
			if val > 0:
				var gl := Label.new()
				gl.text = "%s +%d" % [str(stat_key).substr(0, 3).to_upper(), val]
				gl.add_theme_font_size_override("font_size", 15)
				gl.add_theme_color_override("font_color", stat_colors.get(stat_key, Color(0.8, 0.8, 0.8)))
				growth_row.add_child(gl)

	main_vbox.add_child(UIStyleRef.create_separator(Color(0.85, 0.75, 0.3, 0.2)))

	# Stat points available.
	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_font_size_override("font_size", 17)
	_points_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	main_vbox.add_child(_points_label)

	# Stat allocation rows.
	_stats_panel = VBoxContainer.new()
	_stats_panel.add_theme_constant_override("separation", 6)
	main_vbox.add_child(_stats_panel)

	# Continue button.
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(160, 42)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleRef.style_button(_continue_btn, Color(0.2, 0.2, 0.15), Color(0.85, 0.75, 0.3))
	UIStyleRef.wire_button_sounds(_continue_btn)
	_continue_btn.pressed.connect(func() -> void: closed.emit())
	main_vbox.add_child(_continue_btn)

	_refresh_stats()
	UIStyleRef.play_modal_intro(_overlay, _card)


func _refresh_stats() -> void:
	for child in _stats_panel.get_children():
		child.queue_free()
	_alloc_buttons.clear()

	var data: Dictionary = GameState.character_data.get(_char_id, {})
	var stats: Dictionary = data.get("stats", {})
	var sp: int = data.get("stat_points_available", 0)

	_points_label.text = "Stat Points: %d" % sp

	var stat_entries: Array[Array] = [
		[&"strength", "STR", Color(0.95, 0.7, 0.5)],
		[&"magic", "MAG", Color(0.6, 0.7, 1.0)],
		[&"defense", "DEF", Color(0.6, 0.9, 0.6)],
		[&"agility", "AGI", Color(0.9, 0.9, 0.5)],
	]

	for entry in stat_entries:
		var stat_key: StringName = entry[0]
		var stat_label_text: String = entry[1]
		var stat_color: Color = entry[2]
		var value: int = stats.get(stat_key, 0)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_stats_panel.add_child(row)

		var label := Label.new()
		label.text = "%s: %d" % [stat_label_text, value]
		label.custom_minimum_size = Vector2(140, 0)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", stat_color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		if sp > 0:
			var btn := Button.new()
			btn.text = "+"
			btn.custom_minimum_size = Vector2(42, 32)
			UIStyleRef.style_button(btn, Color(0.2, 0.45, 0.25), Color(0.5, 1.0, 0.6), 20)
			UIStyleRef.wire_button_sounds(btn)
			var sk := stat_key
			btn.pressed.connect(func() -> void: _allocate_stat(sk))
			row.add_child(btn)
			_alloc_buttons.append(btn)

	# Wire vertical focus between allocation buttons.
	for i in _alloc_buttons.size():
		if i > 0:
			_alloc_buttons[i].focus_neighbor_top = _alloc_buttons[i].get_path_to(_alloc_buttons[i - 1])
		if i < _alloc_buttons.size() - 1:
			_alloc_buttons[i].focus_neighbor_bottom = _alloc_buttons[i].get_path_to(_alloc_buttons[i + 1])

	# Wire last alloc button to continue, and vice versa.
	if not _alloc_buttons.is_empty():
		_alloc_buttons[_alloc_buttons.size() - 1].focus_neighbor_bottom = _alloc_buttons[_alloc_buttons.size() - 1].get_path_to(_continue_btn)
		_continue_btn.focus_neighbor_top = _continue_btn.get_path_to(_alloc_buttons[_alloc_buttons.size() - 1])
		_alloc_buttons[0].grab_focus()
	else:
		_continue_btn.grab_focus()


func _allocate_stat(stat_key: StringName) -> void:
	var data: Dictionary = GameState.character_data.get(_char_id, {})
	var sp: int = data.get("stat_points_available", 0)
	if sp <= 0:
		return
	var stats: Dictionary = data.get("stats", {})
	stats[stat_key] = stats.get(stat_key, 0) + 1
	data["stats"] = stats
	data["stat_points_available"] = sp - 1
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	_refresh_stats()


func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		closed.emit()
		return
	if event.is_action_pressed("attack_light") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")
