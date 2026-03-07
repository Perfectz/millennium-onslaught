## Main menu — New Game, Continue, Quit. Controller navigatable.
extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")


func _ready() -> void:
	UIStyleRef.apply_theme(self)
	_build_ui()
	GameManager.change_phase(GameManager.Phase.MAIN_MENU)
	InputManager.set_context(InputManager.InputContext.MENU)


func _build_ui() -> void:
	# Full-screen dark background.
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Gradient overlay for depth.
	var gradient := UIStyleRef.create_gradient_bg(
		Color(0.05, 0.07, 0.16, 0.4),
		Color(0.01, 0.02, 0.05, 0.4)
	)
	bg.add_child(gradient)

	# Center card.
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -300
	card.offset_top = -240
	card.offset_right = 300
	card.offset_bottom = 240
	card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.09, 0.14, 0.95),
		Color(0.3, 0.55, 0.85, 0.8),
		18
	))
	bg.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# Title with glow pulse.
	var title := Label.new()
	title.text = "MILLENNIUM ONSLAUGHT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	UIStyleRef.start_glow_pulse(title, Color(1.12, 1.1, 1.06), Color(0.92, 0.94, 0.97), 3.0)

	var subtitle := Label.new()
	subtitle.text = "A tale of a thousand years..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.7, 0.88))
	vbox.add_child(subtitle)

	# Separator between title and buttons.
	vbox.add_child(UIStyleRef.create_separator(Color(0.3, 0.5, 0.8, 0.3)))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Buttons.
	var new_game_btn := _build_button("New Game", Color(0.15, 0.45, 0.8), Color(0.7, 0.88, 1.0))
	var continue_btn := _build_button("Continue", Color(0.18, 0.42, 0.68), Color(0.65, 0.82, 1.0))
	var quit_btn := _build_button("Quit", Color(0.5, 0.18, 0.22), Color(1.0, 0.72, 0.74))

	vbox.add_child(new_game_btn)
	vbox.add_child(continue_btn)
	vbox.add_child(quit_btn)

	# Disable Continue if no save exists.
	if not SaveManager.has_save(0):
		continue_btn.disabled = true
		continue_btn.modulate.a = 0.4

	# Focus neighbors for controller wrap.
	new_game_btn.focus_neighbor_bottom = new_game_btn.get_path_to(continue_btn)
	continue_btn.focus_neighbor_top = continue_btn.get_path_to(new_game_btn)
	continue_btn.focus_neighbor_bottom = continue_btn.get_path_to(quit_btn)
	quit_btn.focus_neighbor_top = quit_btn.get_path_to(continue_btn)
	new_game_btn.focus_neighbor_top = new_game_btn.get_path_to(quit_btn)
	quit_btn.focus_neighbor_bottom = quit_btn.get_path_to(new_game_btn)

	new_game_btn.grab_focus()

	# Connect buttons.
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	# Wire UI sounds.
	for btn in [new_game_btn, continue_btn, quit_btn]:
		UIStyleRef.wire_button_sounds(btn)

	# Screen FX: glow orb + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects(bg, Color(0.4, 0.6, 1.0, 0.15), 25, Color(0.12, 0.35, 0.8))

	UIStyleRef.play_modal_intro(bg, card)


func _build_button(text: String, base_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyleRef.style_button(btn, base_color, border_color, 24)
	return btn


func _on_new_game() -> void:
	GameState.start_new_game()
	GameManager.go_to_overworld()


func _on_continue() -> void:
	if SaveManager.load_game(0):
		GameManager.go_to_overworld()
	else:
		push_error("MainMenu: Failed to load save.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("attack_light") \
		or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept"):
		var focused := vp.gui_get_focus_owner()
		if focused is Button and not (focused as Button).disabled:
			vp.set_input_as_handled()
			(focused as Button).emit_signal("pressed")
