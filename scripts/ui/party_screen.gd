## Party/Equipment screen — shows party members, stats, and equipment.
## Code-only CanvasLayer, accessible from overworld, town, and pause menu.
class_name PartyScreen
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _overlay: ColorRect
var _card: PanelContainer
var _party_list: VBoxContainer
var _stats_panel: VBoxContainer
var _equip_panel: VBoxContainer
var _selected_char: StringName = &""


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full-screen overlay.
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.08, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	# Screen FX: glow orb + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects(_overlay, Color(0.4, 0.6, 1.0, 0.1), 15, Color(0.12, 0.35, 0.8))

	# Main card.
	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.custom_minimum_size = Vector2(900, 500)
	_card.position = Vector2(-450, -250)
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.55),
		Color(0.3, 0.55, 0.85, 0.25),
		6
	))
	add_child(_card)
	UIStyleRef.apply_theme(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_card.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	# Title.
	var title := Label.new()
	title.text = "PARTY & EQUIPMENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	main_vbox.add_child(title)

	# Content split: party list | stats | equipment.
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	# Left: Party member buttons.
	_party_list = VBoxContainer.new()
	_party_list.custom_minimum_size = Vector2(200, 0)
	_party_list.add_theme_constant_override("separation", 8)
	content.add_child(_party_list)

	# Center: Stats display.
	_stats_panel = VBoxContainer.new()
	_stats_panel.custom_minimum_size = Vector2(300, 0)
	_stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_panel.add_theme_constant_override("separation", 4)
	content.add_child(_stats_panel)

	# Right: Equipment slots.
	_equip_panel = VBoxContainer.new()
	_equip_panel.custom_minimum_size = Vector2(250, 0)
	_equip_panel.add_theme_constant_override("separation", 6)
	content.add_child(_equip_panel)

	# Close button.
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleRef.style_button(close_btn, Color(0.18, 0.18, 0.22), Color(0.4, 0.4, 0.5))
	close_btn.pressed.connect(func() -> void: closed.emit())
	main_vbox.add_child(close_btn)

	_populate_party_list()
	if not GameState.active_party.is_empty():
		_select_character(GameState.active_party[0])

	UIStyleRef.play_modal_intro(_overlay, _card)
	close_btn.grab_focus()


func _populate_party_list() -> void:
	for child in _party_list.get_children():
		child.queue_free()
	for char_id: StringName in GameState.party_roster:
		var data: Dictionary = GameState.character_data.get(char_id, {})
		var display_name: String = Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id))
		var level: int = data.get("level", 1)
		var btn := Button.new()
		btn.text = "%s  LV %d" % [display_name, level]
		btn.custom_minimum_size = Vector2(180, 36)
		UIStyleRef.style_button(btn, Color(0.14, 0.16, 0.2), Color(0.3, 0.35, 0.45), 18)
		var cid := char_id  # capture for lambda
		btn.pressed.connect(func() -> void: _select_character(cid))
		_party_list.add_child(btn)


func _select_character(char_id: StringName) -> void:
	_selected_char = char_id
	_refresh_stats()
	_refresh_equipment()


func _refresh_stats() -> void:
	for child in _stats_panel.get_children():
		child.queue_free()
	var data: Dictionary = GameState.character_data.get(_selected_char, {})
	var display_name: String = Constants.CHARACTER_DISPLAY_NAMES.get(_selected_char, str(_selected_char))
	var role: String = Constants.CHARACTER_ROLES.get(_selected_char, "")
	var level: int = data.get("level", 1)
	var stats: Dictionary = data.get("stats", {})
	var sp: int = data.get("stat_points_available", 0)

	_add_stat_label("Name: %s" % display_name, Color(0.9, 0.92, 1.0), 20)
	_add_stat_label("Role: %s" % role, Color(0.65, 0.72, 0.85), 16)
	_add_stat_label("Level: %d" % level, Color(0.75, 0.82, 0.95), 18)
	if sp > 0:
		_add_stat_label("Stat Points: %d" % sp, Color(1.0, 0.95, 0.6), 16)
	_add_stat_label("", Color.WHITE, 8)  # spacer

	var stat_entries: Array[Array] = [
		[&"strength", "STR", Color(0.95, 0.7, 0.5)],
		[&"magic", "MAG", Color(0.6, 0.7, 1.0)],
		[&"defense", "DEF", Color(0.6, 0.9, 0.6)],
		[&"agility", "AGI", Color(0.9, 0.9, 0.5)],
	]
	var alloc_buttons: Array[Button] = []
	for entry in stat_entries:
		var stat_key: StringName = entry[0]
		var stat_label_text: String = entry[1]
		var stat_color: Color = entry[2]
		var value: int = stats.get(stat_key, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_stats_panel.add_child(row)
		var label := Label.new()
		label.text = "%s: %d" % [stat_label_text, value]
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", stat_color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if sp > 0:
			var btn := Button.new()
			btn.text = "+"
			btn.custom_minimum_size = Vector2(36, 28)
			UIStyleRef.style_button(btn, Color(0.2, 0.45, 0.25), Color(0.5, 1.0, 0.6), 18)
			UIStyleRef.wire_button_sounds(btn)
			var sk := stat_key  # capture for lambda
			btn.pressed.connect(func() -> void: _allocate_stat(sk))
			row.add_child(btn)
			alloc_buttons.append(btn)
	# Wire vertical focus between allocation buttons.
	for i in alloc_buttons.size():
		if i > 0:
			alloc_buttons[i].focus_neighbor_top = alloc_buttons[i].get_path_to(alloc_buttons[i - 1])
		if i < alloc_buttons.size() - 1:
			alloc_buttons[i].focus_neighbor_bottom = alloc_buttons[i].get_path_to(alloc_buttons[i + 1])
	if not alloc_buttons.is_empty():
		alloc_buttons[0].grab_focus()


## Allocate one stat point to the given stat for the selected character.
func _allocate_stat(stat_key: StringName) -> void:
	var data: Dictionary = GameState.character_data.get(_selected_char, {})
	var sp: int = data.get("stat_points_available", 0)
	if sp <= 0:
		return
	var stats: Dictionary = data.get("stats", {})
	stats[stat_key] = stats.get(stat_key, 0) + 1
	data["stats"] = stats
	data["stat_points_available"] = sp - 1
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	_refresh_stats()
	_populate_party_list()


func _add_stat_label(text: String, color: Color, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_stats_panel.add_child(label)


func _refresh_equipment() -> void:
	for child in _equip_panel.get_children():
		child.queue_free()
	var data: Dictionary = GameState.character_data.get(_selected_char, {})
	var equipped: Dictionary = data.get("equipped", {})

	var equip_title := Label.new()
	equip_title.text = "Equipment"
	equip_title.add_theme_font_size_override("font_size", 18)
	equip_title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_equip_panel.add_child(equip_title)

	for slot: String in ["weapon", "armor", "accessory"]:
		var item_id: StringName = StringName(equipped.get(slot, ""))
		var display := slot.to_upper() + ": "
		if item_id == &"" or str(item_id).is_empty():
			display += "(empty)"
		else:
			display += str(item_id).replace("_", " ").capitalize()
		var slot_label := Label.new()
		slot_label.text = display
		slot_label.add_theme_font_size_override("font_size", 16)
		slot_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		_equip_panel.add_child(slot_label)


func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		closed.emit()
