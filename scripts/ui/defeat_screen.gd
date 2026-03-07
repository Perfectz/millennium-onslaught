## Defeat screen - shown when player dies during a dungeon run.
extends CanvasLayer


signal retry_pressed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var _overlay: ColorRect = $Overlay
@onready var _panel_root: Control = $Panel
@onready var _glow: ColorRect = $Panel/Glow
@onready var _card: PanelContainer = $Panel/Card
@onready var _retry_btn: Button = $Panel/Card/Margin/VBox/RetryButton
@onready var _title_label: Label = $Panel/Card/Margin/VBox/TitleLabel
@onready var _sub_label: Label = $Panel/Card/Margin/VBox/SubLabel
@onready var _tip_label: Label = $Panel/Card/Margin/VBox/TipLabel


func _ready() -> void:
	UIStyleRef.apply_theme($Panel)
	_retry_btn.pressed.connect(func() -> void: retry_pressed.emit())
	UIStyleRef.wire_button_sounds(_retry_btn)
	UIStyleRef.add_press_feedback(_retry_btn, 0.975)
	_retry_btn.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Override .tscn styles with glass-morphism.
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.08, 0.05, 0.05, 0.82),
		Color(0.95, 0.46, 0.48, 0.4),
		10
	))
	UIStyleRef.style_button(_retry_btn, Color.BLACK, Color(0.95, 0.46, 0.48))

	# Screen FX: dark red glow + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects(_panel_root, Color(0.8, 0.2, 0.15, 0.08), 10, Color(0.5, 0.1, 0.1))
	_refresh_layout()
	get_viewport().size_changed.connect(_refresh_layout)

	_play_intro()


func _play_intro() -> void:
	UIStyleRef.play_modal_intro(_overlay, _card)

	# Red pulse on overlay — looping throb effect.
	if _overlay:
		var base_alpha := _overlay.color.a
		var pulse_tween := _overlay.create_tween()
		pulse_tween.set_loops()
		pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pulse_tween.tween_property(_overlay, "color:a", base_alpha + 0.06, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		pulse_tween.tween_property(_overlay, "color:a", base_alpha - 0.03, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Title glitch-style reveal.
	if _title_label:
		_title_label.modulate.a = 0.0
		var title_tween := _title_label.create_tween()
		title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		title_tween.tween_interval(0.15)
		# Rapid flickers.
		title_tween.tween_property(_title_label, "modulate:a", 0.7, 0.03)
		title_tween.tween_property(_title_label, "modulate:a", 0.0, 0.02)
		title_tween.tween_property(_title_label, "modulate:a", 0.5, 0.03)
		title_tween.tween_property(_title_label, "modulate:a", 0.0, 0.04)
		title_tween.tween_property(_title_label, "modulate:a", 1.0, 0.08)
		# Subtle glow pulse after reveal.
		title_tween.tween_callback(func() -> void:
			UIStyleRef.start_glow_pulse(_title_label, Color(1.1, 0.95, 0.93), Color(0.92, 0.88, 0.88), 2.5)
		)


func _refresh_layout() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var size := vp.get_visible_rect().size
	var width := clampf(size.x * 0.3, 380.0, 540.0)
	var height := clampf(size.y * 0.34, 250.0, 340.0)
	_card.offset_left = -width * 0.5
	_card.offset_top = -height * 0.5
	_card.offset_right = width * 0.5
	_card.offset_bottom = height * 0.5
	_glow.offset_left = -(width * 0.75)
	_glow.offset_top = -(height * 0.72)
	_glow.offset_right = width * 0.75
	_glow.offset_bottom = height * 0.72
	var compact := size.x < 1280.0 or size.y < 820.0
	_title_label.add_theme_font_size_override("font_size", 36 if compact else 42)
	_sub_label.add_theme_font_size_override("font_size", 15 if compact else 17)
	_tip_label.add_theme_font_size_override("font_size", 13 if compact else 14)
	_retry_btn.custom_minimum_size.y = 50 if compact else 54


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
