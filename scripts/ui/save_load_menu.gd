## Save/Load menu overlay — 3 save slots. Controller navigatable.
extends CanvasLayer


signal closed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

## When true, hides Save buttons — used from the title screen.
var load_only: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.08, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -360
	card.offset_top = -280
	card.offset_right = 360
	card.offset_bottom = 280
	UIStyleRef.apply_theme(card)
	card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.07, 0.1, 0.16, 0.96),
		Color(0.35, 0.6, 0.88, 0.9),
		16
	))
	bg.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "LOAD GAME" if load_only else "SAVE / LOAD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a save slot" if load_only else "Manage your adventure progress"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.7, 0.88))
	vbox.add_child(subtitle)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.25)))

	# Create slot cards.
	var save_btns: Array[Button] = []
	var load_btns: Array[Button] = []
	for slot in 3:
		var meta: Dictionary = SaveManager.load_save_metadata(slot)
		var has_data: bool = meta.get("exists", false) as bool

		# Slot card panel for visual grouping.
		var slot_panel := PanelContainer.new()
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_bg_color := Color(0.08, 0.12, 0.18, 0.7) if has_data else Color(0.06, 0.08, 0.1, 0.5)
		var slot_border := Color(0.3, 0.55, 0.8, 0.5) if has_data else Color(0.2, 0.25, 0.35, 0.3)
		slot_panel.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(slot_bg_color, slot_border, 10))
		vbox.add_child(slot_panel)

		var slot_margin := MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 14)
		slot_margin.add_theme_constant_override("margin_top", 8)
		slot_margin.add_theme_constant_override("margin_right", 14)
		slot_margin.add_theme_constant_override("margin_bottom", 8)
		slot_panel.add_child(slot_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		slot_margin.add_child(row)

		# Slot icon indicator.
		var icon_label := Label.new()
		icon_label.text = "%d" % (slot + 1)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.custom_minimum_size = Vector2(32, 0)
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.95) if has_data else Color(0.35, 0.4, 0.5))
		row.add_child(icon_label)

		var slot_label := Label.new()
		slot_label.add_theme_font_size_override("font_size", 17)
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if has_data:
			var party_names: Array = meta.get("party_names", [])
			var gold_val: int = meta.get("gold", 0) as int
			var display_text: String = ""
			if party_names.size() > 0:
				display_text = ", ".join(party_names)
			else:
				display_text = "Save data"
			display_text += "  |  %dG" % gold_val
			slot_label.text = display_text
			slot_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		else:
			slot_label.text = "Empty slot"
			slot_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
		row.add_child(slot_label)

		var save_btn := Button.new()
		save_btn.text = "Save"
		save_btn.custom_minimum_size = Vector2(90, 38)
		UIStyleRef.style_button(save_btn, Color(0.14, 0.42, 0.68), Color(0.55, 0.78, 1.0), 17)
		save_btn.pressed.connect(func() -> void:
			if SaveManager.save_game(slot):
				GameState.active_save_slot = slot
				slot_label.text = "Saved!"
				UIStyleRef.flash_label(slot_label, Color(0.5, 1.0, 0.7), 0.8)
				UIStyleRef.punch(save_btn, 0.06)
				AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
			else:
				slot_label.text = "Save failed!"
				UIStyleRef.flash_label(slot_label, Color(1.0, 0.5, 0.5), 0.8)
				AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		)
		if not load_only:
			row.add_child(save_btn)
		save_btns.append(save_btn)

		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.custom_minimum_size = Vector2(90, 38)
		UIStyleRef.style_button(load_btn, Color(0.18, 0.38, 0.55), Color(0.5, 0.72, 0.92), 17)
		if not has_data:
			load_btn.disabled = true
			load_btn.modulate.a = 0.35
		load_btn.pressed.connect(func() -> void:
			if SaveManager.load_game(slot):
				GameState.active_save_slot = slot
				closed.emit()
				get_tree().paused = false
				GameManager.go_to_overworld()
		)
		row.add_child(load_btn)
		load_btns.append(load_btn)

	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.4, 0.6, 0.2)))

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(300, 48)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyleRef.style_button(close_btn, Color(0.45, 0.18, 0.22), Color(1.0, 0.68, 0.7), 20)
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)
	# Wire UI sounds to all buttons.
	for btn_arr in [save_btns, load_btns]:
		for btn in btn_arr:
			UIStyleRef.wire_button_sounds(btn)
	UIStyleRef.wire_button_sounds(close_btn)

	# Focus grid: Save/Load columns with Close at bottom.
	if load_only:
		# Load-only: single column of Load buttons + Close.
		for i in 3:
			var l := load_btns[i]
			if i > 0:
				l.focus_neighbor_top = l.get_path_to(load_btns[i - 1])
			else:
				l.focus_neighbor_top = l.get_path_to(close_btn)
			if i < 2:
				l.focus_neighbor_bottom = l.get_path_to(load_btns[i + 1])
			else:
				l.focus_neighbor_bottom = l.get_path_to(close_btn)
		close_btn.focus_neighbor_top = close_btn.get_path_to(load_btns[2])
		close_btn.focus_neighbor_bottom = close_btn.get_path_to(load_btns[0])
		load_btns[0].grab_focus()
	else:
		for i in 3:
			var s := save_btns[i]
			var l := load_btns[i]
			# Horizontal: Save ↔ Load in same row.
			s.focus_neighbor_right = s.get_path_to(l)
			l.focus_neighbor_left = l.get_path_to(s)
			# Vertical save column.
			if i > 0:
				s.focus_neighbor_top = s.get_path_to(save_btns[i - 1])
			else:
				s.focus_neighbor_top = s.get_path_to(close_btn)
			if i < 2:
				s.focus_neighbor_bottom = s.get_path_to(save_btns[i + 1])
			else:
				s.focus_neighbor_bottom = s.get_path_to(close_btn)
			# Vertical load column.
			if i > 0:
				l.focus_neighbor_top = l.get_path_to(load_btns[i - 1])
			else:
				l.focus_neighbor_top = l.get_path_to(close_btn)
			if i < 2:
				l.focus_neighbor_bottom = l.get_path_to(load_btns[i + 1])
			else:
				l.focus_neighbor_bottom = l.get_path_to(close_btn)
		close_btn.focus_neighbor_top = close_btn.get_path_to(save_btns[2])
		close_btn.focus_neighbor_bottom = close_btn.get_path_to(save_btns[0])
		save_btns[0].grab_focus()

	# Screen FX: glow orb + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects(bg, Color(0.4, 0.55, 0.9, 0.08), 12, Color(0.12, 0.35, 0.8))

	UIStyleRef.play_modal_intro(bg, card)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_select") or event.is_action_pressed("dodge"):
		vp.set_input_as_handled()
		_on_close()
	elif event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")


func _on_close() -> void:
	closed.emit()
