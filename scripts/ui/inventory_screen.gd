## Inventory screen — browse owned items and equip them to party members.
class_name InventoryScreen
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")


var _overlay: ColorRect
var _card: PanelContainer
var _gold_label: Label
var _item_list: VBoxContainer
var _detail_panel: VBoxContainer
var _character_row: HBoxContainer
var _equip_btn: Button
var _unequip_btn: Button
var _close_btn: Button

var _item_buttons: Array[Button] = []
var _character_buttons: Array[Button] = []
var _selected_item_id: StringName = &""
var _selected_char: StringName = &""


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	EventBus.rpg_equipment_changed.connect(_on_equipment_changed)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.08, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	UIStyleRef.apply_screen_effects(_overlay, Color(0.9, 0.7, 0.25, 0.08), 14, Color(0.45, 0.28, 0.08))

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.custom_minimum_size = Vector2(1040, 560)
	_card.position = Vector2(-520, -280)
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.07, 0.09, 0.13, 0.56),
		Color(0.82, 0.65, 0.2, 0.26),
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
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.8))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	header.add_child(_gold_label)
	_refresh_gold_label()

	main_vbox.add_child(UIStyleRef.create_separator(Color(0.82, 0.65, 0.2, 0.25)))

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(360, 0)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_constant_override("separation", 4)
	list_scroll.add_child(_item_list)

	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 10)
	content.add_child(right_panel)

	var char_label := Label.new()
	char_label.text = "Equip To"
	char_label.add_theme_font_size_override("font_size", 18)
	char_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	right_panel.add_child(char_label)

	_character_row = HBoxContainer.new()
	_character_row.add_theme_constant_override("separation", 8)
	right_panel.add_child(_character_row)

	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_panel.add_theme_constant_override("separation", 6)
	right_panel.add_child(_detail_panel)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(footer)

	_equip_btn = Button.new()
	_equip_btn.text = "Equip"
	_equip_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_equip_btn, Color(0.22, 0.36, 0.18), Color(0.58, 0.95, 0.55))
	UIStyleRef.wire_button_sounds(_equip_btn)
	_equip_btn.pressed.connect(_on_equip_pressed)
	footer.add_child(_equip_btn)

	_unequip_btn = Button.new()
	_unequip_btn.text = "Unequip"
	_unequip_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_unequip_btn, Color(0.18, 0.24, 0.34), Color(0.58, 0.74, 1.0))
	UIStyleRef.wire_button_sounds(_unequip_btn)
	_unequip_btn.pressed.connect(_on_unequip_pressed)
	footer.add_child(_unequip_btn)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_close_btn, Color(0.18, 0.18, 0.22), Color(0.4, 0.4, 0.5))
	UIStyleRef.wire_button_sounds(_close_btn)
	_close_btn.pressed.connect(func() -> void: closed.emit())
	footer.add_child(_close_btn)

	_populate_character_row()
	_populate_item_list()
	_update_footer_buttons()
	UIStyleRef.play_modal_intro(_overlay, _card)

	if not _item_buttons.is_empty():
		_item_buttons[0].grab_focus()
	elif not _character_buttons.is_empty():
		_character_buttons[0].grab_focus()
	else:
		_close_btn.grab_focus()


func _populate_character_row() -> void:
	for child in _character_row.get_children():
		child.queue_free()
	_character_buttons.clear()

	var roster := GameState.party_roster
	if roster.is_empty():
		_selected_char = &""
		return

	if _selected_char == &"" or _selected_char not in roster:
		_selected_char = GameState.active_party[0] if not GameState.active_party.is_empty() else roster[0]

	for i in roster.size():
		var char_id: StringName = roster[i]
		var btn := Button.new()
		btn.text = Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id))
		btn.custom_minimum_size = Vector2(140, 36)
		var selected := char_id == _selected_char
		UIStyleRef.style_button(
			btn,
			Color(0.28, 0.26, 0.18) if selected else Color(0.12, 0.14, 0.18),
			Color(0.92, 0.78, 0.42) if selected else Color(0.36, 0.4, 0.48),
			16
		)
		UIStyleRef.wire_button_sounds(btn)
		var captured := char_id
		btn.pressed.connect(func() -> void:
			_selected_char = captured
			_populate_character_row()
			_refresh_detail()
			_update_footer_buttons()
		)
		_character_row.add_child(btn)
		_character_buttons.append(btn)

	for i in _character_buttons.size():
		if i > 0:
			_character_buttons[i].focus_neighbor_left = _character_buttons[i].get_path_to(_character_buttons[i - 1])
		if i < _character_buttons.size() - 1:
			_character_buttons[i].focus_neighbor_right = _character_buttons[i].get_path_to(_character_buttons[i + 1])


func _populate_item_list() -> void:
	for child in _item_list.get_children():
		child.queue_free()
	_item_buttons.clear()

	var items := GameState.get_inventory_items()
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Inventory is empty."
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
		_item_list.add_child(empty_label)
		_selected_item_id = &""
		_refresh_detail()
		return

	var valid_selection := false
	for entry: Dictionary in items:
		var item_id := StringName(entry.get("item_id", ""))
		if item_id == _selected_item_id:
			valid_selection = true
			break
	if not valid_selection:
		_selected_item_id = StringName(items[0].get("item_id", ""))

	for i in items.size():
		var entry: Dictionary = items[i]
		var item_id := StringName(entry.get("item_id", ""))
		var quantity := int(entry.get("quantity", 1))
		var equipped_count := GameState.get_equipped_item_count(item_id)
		var btn := Button.new()
		btn.text = "%s  [%s]  x%d" % [
			str(entry.get("display_name", "Unknown Item")),
			_item_slot_label(StringName(entry.get("slot", ""))),
			quantity
		]
		if equipped_count > 0:
			btn.text += "  (E%d)" % equipped_count
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIStyleRef.style_button(
			btn,
			Color(0.26, 0.22, 0.16) if item_id == _selected_item_id else Color(0.1, 0.12, 0.14),
			Color(0.92, 0.78, 0.42) if item_id == _selected_item_id else Color(0.4, 0.34, 0.24),
			16
		)
		UIStyleRef.wire_button_sounds(btn)
		var captured := item_id
		btn.pressed.connect(func() -> void: _select_item(captured))
		btn.focus_entered.connect(func() -> void: _select_item(captured))
		_item_list.add_child(btn)
		_item_buttons.append(btn)

	for i in _item_buttons.size():
		if i > 0:
			_item_buttons[i].focus_neighbor_top = _item_buttons[i].get_path_to(_item_buttons[i - 1])
		if i < _item_buttons.size() - 1:
			_item_buttons[i].focus_neighbor_bottom = _item_buttons[i].get_path_to(_item_buttons[i + 1])

	if not _item_buttons.is_empty():
		_item_buttons[_item_buttons.size() - 1].focus_neighbor_bottom = _item_buttons[_item_buttons.size() - 1].get_path_to(_equip_btn)
		_equip_btn.focus_neighbor_top = _equip_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])
		_unequip_btn.focus_neighbor_top = _unequip_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])
		_close_btn.focus_neighbor_top = _close_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])

	_refresh_detail()


func _select_item(item_id: StringName) -> void:
	if item_id == &"":
		return
	if item_id == _selected_item_id:
		_refresh_detail()
		_update_footer_buttons()
		return
	_selected_item_id = item_id
	_populate_item_list()
	_update_footer_buttons()


func _refresh_detail() -> void:
	for child in _detail_panel.get_children():
		child.queue_free()

	if _selected_item_id == &"":
		_add_detail_label("No item selected.", Color(0.72, 0.76, 0.82), 18)
		return

	var item := GameState.get_inventory_item(_selected_item_id)
	if item.is_empty():
		_add_detail_label("Item data unavailable.", Color(1.0, 0.6, 0.5), 18)
		return

	_add_detail_label(str(item.get("display_name", "Unknown Item")), Color(0.95, 0.96, 0.88), 22)
	_add_detail_label(str(item.get("description", "")), Color(0.72, 0.78, 0.82), 15)
	_add_detail_label("", Color.WHITE, 4)
	_add_detail_label("Slot: %s" % _item_slot_label(StringName(item.get("slot", ""))), Color(0.84, 0.78, 0.58), 16)
	_add_detail_label("Owned: %d" % int(item.get("quantity", 1)), Color(0.98, 0.92, 0.64), 16)
	_add_detail_label("Equipped Copies: %d" % GameState.get_equipped_item_count(_selected_item_id), Color(0.65, 0.78, 1.0), 16)

	var equipped_by := _get_equipped_by_names(_selected_item_id)
	if not equipped_by.is_empty():
		_add_detail_label("Equipped By: %s" % ", ".join(equipped_by), Color(0.66, 0.8, 1.0), 15)

	if _selected_char != &"":
		_add_detail_label("", Color.WHITE, 4)
		var char_name: String = str(Constants.CHARACTER_DISPLAY_NAMES.get(_selected_char, str(_selected_char)))
		_add_detail_label("Selected Character: %s" % char_name, Color(0.84, 0.9, 1.0), 16)
		var slot := StringName(item.get("slot", ""))
		var equipped_item_id := _get_equipped_item_for_selected_char(slot)
		var char_data := GameState.character_data.get(_selected_char, {}) as Dictionary
		var level := int(char_data.get("level", 1))
		var required_level := int(item.get("required_level", 1))
		if equipped_item_id == _selected_item_id:
			_add_detail_label("Status: Currently equipped", Color(0.6, 0.95, 0.65), 15)
		elif level < required_level:
			_add_detail_label("Status: Requires level %d" % required_level, Color(1.0, 0.68, 0.54), 15)
		elif GameState.can_equip_inventory_item(_selected_char, _selected_item_id):
			_add_detail_label("Status: Ready to equip", Color(0.75, 0.9, 0.7), 15)
		else:
			_add_detail_label("Status: All owned copies are already equipped", Color(1.0, 0.68, 0.54), 15)

	if not (item.get("stat_bonuses", {}) as Dictionary).is_empty():
		_add_detail_label("", Color.WHITE, 4)
		_add_detail_label("Stat Bonuses", Color(0.82, 0.88, 0.82), 16)
		for stat_key: String in item.get("stat_bonuses", {}):
			var value := int((item.get("stat_bonuses", {}) as Dictionary).get(stat_key, 0))
			var sign_str := "+" if value >= 0 else ""
			_add_detail_label("%s %s%d" % [stat_key.capitalize(), sign_str, value], Color(0.64, 0.92, 0.68), 15)

	if not (item.get("passive_effects", {}) as Dictionary).is_empty():
		_add_detail_label("", Color.WHITE, 4)
		_add_detail_label("Passive Effects", Color(0.82, 0.88, 0.82), 16)
		for effect_key: String in item.get("passive_effects", {}):
			var value = (item.get("passive_effects", {}) as Dictionary).get(effect_key)
			_add_detail_label("%s: %s" % [effect_key.replace("_", " ").capitalize(), str(value)], Color(0.65, 0.8, 0.96), 15)


func _add_detail_label(text: String, color: Color, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_detail_panel.add_child(label)


func _update_footer_buttons() -> void:
	var has_selection := _selected_item_id != &"" and _selected_char != &""
	_equip_btn.disabled = true
	_unequip_btn.disabled = true
	if not has_selection:
		return

	var item := GameState.get_inventory_item(_selected_item_id)
	var slot := StringName(item.get("slot", ""))
	var equipped_item_id := _get_equipped_item_for_selected_char(slot)
	_equip_btn.disabled = not GameState.can_equip_inventory_item(_selected_char, _selected_item_id) or equipped_item_id == _selected_item_id
	_unequip_btn.disabled = equipped_item_id != _selected_item_id


func _on_equip_pressed() -> void:
	if _selected_item_id == &"" or _selected_char == &"":
		return
	if not GameState.equip_inventory_item(_selected_char, _selected_item_id):
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		ToastSystem.show_toast("Could not equip item.", Color(1.0, 0.55, 0.45))
		return
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	ToastSystem.show_toast(
		"%s equipped %s!" % [
			Constants.CHARACTER_DISPLAY_NAMES.get(_selected_char, str(_selected_char)),
			str(GameState.get_inventory_item(_selected_item_id).get("display_name", "item"))
		],
		Color(0.55, 0.7, 1.0)
	)
	_populate_item_list()
	_refresh_detail()
	_update_footer_buttons()


func _on_unequip_pressed() -> void:
	if _selected_item_id == &"" or _selected_char == &"":
		return
	var item := GameState.get_inventory_item(_selected_item_id)
	var slot := StringName(item.get("slot", ""))
	if slot == &"" or not GameState.unequip_inventory_slot(_selected_char, slot):
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		ToastSystem.show_toast("Nothing to unequip.", Color(1.0, 0.55, 0.45))
		return
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	ToastSystem.show_toast(
		"%s unequipped %s." % [
			Constants.CHARACTER_DISPLAY_NAMES.get(_selected_char, str(_selected_char)),
			str(item.get("display_name", "item"))
		],
		Color(0.72, 0.86, 1.0)
	)
	_populate_item_list()
	_refresh_detail()
	_update_footer_buttons()


func _get_equipped_by_names(item_id: StringName) -> Array[String]:
	var names: Array[String] = []
	for char_id: StringName in GameState.party_roster:
		var data: Dictionary = GameState.character_data.get(char_id, {}) as Dictionary
		var equipped: Dictionary = data.get("equipped", {})
		for slot in equipped:
			if StringName(equipped.get(slot, "")) == item_id:
				names.append(Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id)))
				break
	return names


func _get_equipped_item_for_selected_char(slot: StringName) -> StringName:
	if _selected_char == &"" or slot == &"":
		return &""
	var data: Dictionary = GameState.character_data.get(_selected_char, {}) as Dictionary
	var equipped: Dictionary = data.get("equipped", {})
	return StringName(equipped.get(slot, ""))


func _refresh_gold_label() -> void:
	_gold_label.text = "Gold: %d" % GameState.gold


func _item_slot_label(slot: StringName) -> String:
	if slot == &"":
		return "Item"
	return str(slot).capitalize()


func _on_equipment_changed(_player_index: int, _slot: StringName, _item_id: StringName) -> void:
	if not is_inside_tree():
		return
	_populate_item_list()
	_refresh_detail()
	_update_footer_buttons()


func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("dodge") or event.is_action_pressed("pause"):
		vp.set_input_as_handled()
		closed.emit()
