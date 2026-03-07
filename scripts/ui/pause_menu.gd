## Pause menu — resume, save, party, settings, god mode, quit.
## Single-column layout; audio controls now live in the Settings screen.
extends CanvasLayer


signal resumed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

var _resume_btn: Button
var _save_btn: Button
var _title_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	InputManager.set_context(InputManager.InputContext.MENU)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.09, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -220
	card.offset_top = -280
	card.offset_right = 220
	card.offset_bottom = 280
	UIStyleRef.apply_theme(card)
	card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.08, 0.12, 0.18, 0.96),
		Color(0.38, 0.67, 0.94, 0.96),
		16
	))
	bg.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var vbox := _build_menu(margin)

	_configure_focus_loop(vbox)
	_resume_btn.grab_focus()

	UIStyleRef.apply_screen_effects(bg, Color(0.4, 0.6, 1.0, 0.08), 15, Color(0.12, 0.35, 0.8))
	UIStyleRef.play_modal_intro(bg, card)


func _build_menu(parent: MarginContainer) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)

	var subtitle := Label.new()
	subtitle.text = "System Menu"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.88, 1.0))

	var sep := UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.25))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)

	_resume_btn = _build_button("Resume", Color(0.18, 0.52, 0.9), Color(0.77, 0.93, 1.0))
	_save_btn = _build_button("Save Game", Color(0.16, 0.55, 0.38), Color(0.65, 1.0, 0.82))
	var inventory_btn := _build_button("Inventory", Color(0.48, 0.38, 0.18), Color(0.98, 0.84, 0.48))
	var party_btn := _build_button("Party", Color(0.42, 0.32, 0.58), Color(0.78, 0.68, 1.0))
	var settings_btn := _build_button("Settings", Color(0.2, 0.48, 0.58), Color(0.55, 0.9, 0.95))
	var god_btn := _build_button("God Mode: OFF", Color(0.24, 0.44, 0.7), Color(0.72, 0.9, 1.0))
	_title_btn = _build_button("Return to Title", Color(0.48, 0.35, 0.62), Color(0.85, 0.74, 1.0))
	var quit_btn := _build_button("Quit", Color(0.56, 0.2, 0.24), Color(1.0, 0.75, 0.76))

	_resume_btn.pressed.connect(_on_resume)
	_save_btn.pressed.connect(_on_save_game)
	inventory_btn.pressed.connect(_on_open_inventory)
	party_btn.pressed.connect(_on_open_party)
	settings_btn.pressed.connect(_on_open_settings)
	god_btn.pressed.connect(func() -> void:
		GameState.god_mode = not GameState.god_mode
		god_btn.text = "God Mode: ON" if GameState.god_mode else "God Mode: OFF"
		UIStyleRef.punch(god_btn, 0.04)
	)
	_title_btn.pressed.connect(_on_return_to_title)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())

	for btn in [_resume_btn, _save_btn, inventory_btn, party_btn, settings_btn, god_btn, _title_btn, quit_btn]:
		UIStyleRef.wire_button_sounds(btn)

	vbox.add_child(title)
	vbox.add_child(subtitle)
	vbox.add_child(sep)
	vbox.add_child(spacer)
	vbox.add_child(_resume_btn)
	vbox.add_child(_save_btn)
	vbox.add_child(inventory_btn)
	vbox.add_child(party_btn)
	vbox.add_child(settings_btn)
	vbox.add_child(god_btn)
	vbox.add_child(_title_btn)
	vbox.add_child(quit_btn)
	return vbox


func _build_button(text: String, base_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyleRef.style_button(btn, base_color, border_color, 22)
	return btn


func _configure_focus_loop(vbox: VBoxContainer) -> void:
	var buttons: Array[Control] = []
	for i in range(4, vbox.get_child_count()):
		var child := vbox.get_child(i)
		if child is Button:
			buttons.append(child)
	for i in buttons.size():
		var current := buttons[i]
		var next := buttons[(i + 1) % buttons.size()]
		var prev := buttons[(i - 1 + buttons.size()) % buttons.size()]
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_top = current.get_path_to(prev)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("pause"):
		vp.set_input_as_handled()
		_on_resume()
	elif event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")


func _on_resume() -> void:
	resumed.emit()


func _on_save_game() -> void:
	var success := SaveManager.save_game(GameState.active_save_slot)
	if success:
		_save_btn.text = "Saved!"
		_save_btn.modulate = Color(0.5, 1.0, 0.7)
		AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
		if ToastSystem:
			ToastSystem.show_toast("Game saved successfully.")
	else:
		_save_btn.text = "Save Failed"
		_save_btn.modulate = Color(1.0, 0.5, 0.5)
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
	UIStyleRef.punch(_save_btn, 0.04)
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_save_btn):
			_save_btn.text = "Save Game"
			_save_btn.modulate = Color.WHITE
	)


func _on_open_party() -> void:
	visible = false
	var party_screen := PartyScreen.new()
	party_screen.closed.connect(func() -> void:
		party_screen.queue_free()
		visible = true
		_resume_btn.grab_focus()
	)
	add_child(party_screen)


func _on_open_inventory() -> void:
	visible = false
	var inventory_screen := InventoryScreen.new()
	inventory_screen.closed.connect(func() -> void:
		inventory_screen.queue_free()
		visible = true
		_resume_btn.grab_focus()
	)
	add_child(inventory_screen)


func _on_open_settings() -> void:
	visible = false
	var settings_screen := SettingsMenu.new()
	settings_screen.closed.connect(func() -> void:
		settings_screen.queue_free()
		visible = true
		_resume_btn.grab_focus()
	)
	add_child(settings_screen)


func _on_return_to_title() -> void:
	Engine.time_scale = 1.0
	if GameManager.is_paused():
		GameManager.resume_game()
	else:
		get_tree().paused = false
	GameManager.go_to_main_menu()
