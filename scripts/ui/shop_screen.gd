## Shop screen — browse and buy equipment from a town shop.
## Code-only CanvasLayer modal, same pattern as PartyScreen.
class_name ShopScreen
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _town_def: TownDef
var _shop_items: Array[EquipmentDef] = []
var _transaction: ShopTransaction = ShopTransaction.new()
var _selected_index: int = -1

var _overlay: ColorRect
var _card: PanelContainer
var _gold_label: Label
var _item_list: VBoxContainer
var _detail_panel: VBoxContainer
var _buy_btn: Button
var _equip_btn: Button
var _close_btn: Button
var _item_buttons: Array[Button] = []


func setup(town_def: TownDef) -> void:
	_town_def = town_def
	_shop_items.clear()
	for item: EquipmentDef in town_def.shop_items:
		if item != null:
			_shop_items.append(item)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full-screen overlay.
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.04, 0.08, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	UIStyleRef.apply_screen_effects(_overlay, Color(0.3, 0.7, 0.4, 0.1), 12, Color(0.15, 0.45, 0.2))

	# Main card.
	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.custom_minimum_size = Vector2(960, 540)
	_card.position = Vector2(-480, -270)
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.55),
		Color(0.3, 0.7, 0.45, 0.25),
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

	# Header row: title + gold.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)

	var title := Label.new()
	var shop_name: String = "WEAPONS SHOP"
	if _town_def:
		shop_name = _town_def.town_name.to_upper() + " SHOP"
	title.text = shop_name
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	header.add_child(_gold_label)
	_refresh_gold_label()

	main_vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.7, 0.45, 0.3)))

	# Content split: item list | detail panel.
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)

	# Left: scrollable item list.
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(340, 0)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_constant_override("separation", 4)
	list_scroll.add_child(_item_list)

	# Right: item detail.
	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_theme_constant_override("separation", 6)
	content.add_child(_detail_panel)

	# Footer: Buy, Equip, Close.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(footer)

	_buy_btn = Button.new()
	_buy_btn.text = "Buy"
	_buy_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_buy_btn, Color(0.15, 0.3, 0.18), Color(0.4, 0.85, 0.5))
	UIStyleRef.wire_button_sounds(_buy_btn)
	_buy_btn.pressed.connect(_on_buy_pressed)
	footer.add_child(_buy_btn)

	_equip_btn = Button.new()
	_equip_btn.text = "Equip"
	_equip_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_equip_btn, Color(0.15, 0.2, 0.3), Color(0.45, 0.65, 1.0))
	UIStyleRef.wire_button_sounds(_equip_btn)
	_equip_btn.pressed.connect(_on_equip_pressed)
	footer.add_child(_equip_btn)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(120, 40)
	UIStyleRef.style_button(_close_btn, Color(0.18, 0.18, 0.22), Color(0.4, 0.4, 0.5))
	UIStyleRef.wire_button_sounds(_close_btn)
	_close_btn.pressed.connect(func() -> void: closed.emit())
	footer.add_child(_close_btn)

	# Wire focus between footer buttons.
	_buy_btn.focus_neighbor_right = _buy_btn.get_path_to(_equip_btn)
	_equip_btn.focus_neighbor_left = _equip_btn.get_path_to(_buy_btn)
	_equip_btn.focus_neighbor_right = _equip_btn.get_path_to(_close_btn)
	_close_btn.focus_neighbor_left = _close_btn.get_path_to(_equip_btn)

	_populate_item_list()
	_update_footer_buttons()

	UIStyleRef.play_modal_intro(_overlay, _card)

	if not _item_buttons.is_empty():
		_item_buttons[0].grab_focus()
		_select_item(0)
	else:
		_close_btn.grab_focus()


func _populate_item_list() -> void:
	for child in _item_list.get_children():
		child.queue_free()
	_item_buttons.clear()

	for i in _shop_items.size():
		var item := _shop_items[i]
		var btn := Button.new()
		var label_text := "%s  [%s]  %dG" % [item.display_name, str(item.slot).capitalize(), item.cost]
		var quantity := GameState.get_inventory_quantity(item.equipment_id)
		if quantity > 0:
			label_text += "  (x%d)" % quantity
		btn.text = label_text
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIStyleRef.style_button(btn, Color(0.1, 0.14, 0.12), Color(0.3, 0.6, 0.4), 16)
		UIStyleRef.wire_button_sounds(btn)
		var idx := i
		btn.pressed.connect(func() -> void: _select_item(idx))
		btn.focus_entered.connect(func() -> void: _select_item(idx))
		_item_list.add_child(btn)
		_item_buttons.append(btn)

	# Wire vertical focus loop.
	for i in _item_buttons.size():
		if i > 0:
			_item_buttons[i].focus_neighbor_top = _item_buttons[i].get_path_to(_item_buttons[i - 1])
		if i < _item_buttons.size() - 1:
			_item_buttons[i].focus_neighbor_bottom = _item_buttons[i].get_path_to(_item_buttons[i + 1])

	# Wire last item button to footer.
	if not _item_buttons.is_empty():
		_item_buttons[_item_buttons.size() - 1].focus_neighbor_bottom = _item_buttons[_item_buttons.size() - 1].get_path_to(_buy_btn)
		_buy_btn.focus_neighbor_top = _buy_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])
		_equip_btn.focus_neighbor_top = _equip_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])
		_close_btn.focus_neighbor_top = _close_btn.get_path_to(_item_buttons[_item_buttons.size() - 1])


func _select_item(index: int) -> void:
	if index < 0 or index >= _shop_items.size():
		return
	_selected_index = index
	_refresh_detail()
	_update_footer_buttons()


func _refresh_detail() -> void:
	for child in _detail_panel.get_children():
		child.queue_free()

	if _selected_index < 0 or _selected_index >= _shop_items.size():
		return

	var item := _shop_items[_selected_index]
	_add_detail_label(item.display_name, Color(0.9, 0.95, 0.9), 22)
	_add_detail_label(item.description, Color(0.7, 0.78, 0.75), 15)
	_add_detail_label("", Color.WHITE, 4)  # spacer
	_add_detail_label("Slot: %s" % str(item.slot).capitalize(), Color(0.65, 0.8, 0.7), 16)
	_add_detail_label("Cost: %d Gold" % item.cost, Color(1.0, 0.92, 0.55), 17)
	if item.required_level > 1:
		_add_detail_label("Required Level: %d" % item.required_level, Color(0.85, 0.65, 0.55), 15)
	_add_detail_label("", Color.WHITE, 4)  # spacer

	# Stat bonuses.
	if not item.stat_bonuses.is_empty():
		_add_detail_label("Stat Bonuses:", Color(0.75, 0.85, 0.8), 16)
		for stat_key: String in item.stat_bonuses:
			var value: int = item.stat_bonuses[stat_key]
			var sign_str := "+" if value >= 0 else ""
			_add_detail_label("  %s %s%d" % [stat_key.capitalize(), sign_str, value], Color(0.6, 0.9, 0.65), 15)

	# Passive effects.
	if not item.passive_effects.is_empty():
		_add_detail_label("Passive Effects:", Color(0.75, 0.85, 0.8), 16)
		for effect_key: String in item.passive_effects:
			var value = item.passive_effects[effect_key]
			_add_detail_label("  %s: %s" % [effect_key.replace("_", " ").capitalize(), str(value)], Color(0.6, 0.8, 0.95), 15)

	# Ownership status.
	if _is_item_owned(item.equipment_id):
		_add_detail_label("", Color.WHITE, 4)
		_add_detail_label("OWNED", Color(0.55, 0.9, 0.6), 18)

	# Equipped status.
	var equipped_by := _get_equipped_by(item.equipment_id)
	if not equipped_by.is_empty():
		_add_detail_label("Equipped by: %s" % equipped_by, Color(0.6, 0.75, 1.0), 15)


func _add_detail_label(text: String, color: Color, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_panel.add_child(label)


func _update_footer_buttons() -> void:
	var has_selection := _selected_index >= 0 and _selected_index < _shop_items.size()
	_buy_btn.disabled = true
	_equip_btn.disabled = true

	if has_selection:
		var item := _shop_items[_selected_index]
		var owned := _is_item_owned(item.equipment_id)
		_buy_btn.disabled = owned or not _transaction.can_buy(GameState.gold, item.cost)
		_equip_btn.disabled = not owned


func _on_buy_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _shop_items.size():
		return
	var item := _shop_items[_selected_index]
	var result := _transaction.buy(GameState.gold, item.cost, item.equipment_id)
	if result["success"]:
		GameState.gold = result["new_gold"]
		GameState.add_inventory_item(InventoryManager.from_equipment_def(item))
		EventBus.town_shop_purchase.emit(item.equipment_id, item.cost)
		EventBus.rpg_gold_changed.emit(GameState.gold)
		AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
		ToastSystem.show_toast("Purchased %s!" % item.display_name, Color(0.55, 0.95, 0.6))
		_refresh_gold_label()
		_populate_item_list()
		_refresh_detail()
		_update_footer_buttons()
		if _selected_index >= 0 and _selected_index < _item_buttons.size():
			_item_buttons[_selected_index].grab_focus()
	else:
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		ToastSystem.show_toast("Not enough gold!", Color(1.0, 0.55, 0.45))


func _on_equip_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _shop_items.size():
		return
	var item := _shop_items[_selected_index]
	if not _is_item_owned(item.equipment_id):
		return

	# Equip on first active party member.
	if GameState.active_party.is_empty():
		return
	var char_id: StringName = GameState.active_party[0]
	if not GameState.equip_inventory_item(char_id, item.equipment_id):
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		ToastSystem.show_toast("No free copy available to equip.", Color(1.0, 0.55, 0.45))
		return
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	var char_name: String = Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id))
	ToastSystem.show_toast("%s equipped %s!" % [char_name, item.display_name], Color(0.55, 0.7, 1.0))
	_refresh_detail()
	_update_footer_buttons()


func _is_item_owned(item_id: StringName) -> bool:
	return GameState.has_inventory_item(item_id)


func _get_equipped_by(item_id: StringName) -> String:
	for char_id: StringName in GameState.party_roster:
		var data: Dictionary = GameState.character_data.get(char_id, {})
		var equipped: Dictionary = data.get("equipped", {})
		for slot: String in equipped:
			if StringName(equipped[slot]) == item_id:
				return Constants.CHARACTER_DISPLAY_NAMES.get(char_id, str(char_id))
	return ""


func _refresh_gold_label() -> void:
	_gold_label.text = "Gold: %d" % GameState.gold


func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		closed.emit()
