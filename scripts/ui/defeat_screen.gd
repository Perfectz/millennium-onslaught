## Defeat screen - shown when player dies during a dungeon run.
extends CanvasLayer


signal retry_pressed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var _overlay: ColorRect = $Overlay
@onready var _card: PanelContainer = $Panel/Card
@onready var _retry_btn: Button = $Panel/Card/Margin/VBox/RetryButton
@onready var _title_label: Label = $Panel/Card/Margin/VBox/TitleLabel


func _ready() -> void:
	UIStyleRef.apply_theme($Panel)
	_retry_btn.pressed.connect(func() -> void: retry_pressed.emit())
	UIStyleRef.wire_button_sounds(_retry_btn)
	_retry_btn.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Override .tscn styles with glass-morphism.
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.08, 0.05, 0.05, 0.55),
		Color(0.95, 0.46, 0.48, 0.25),
		6
	))
	UIStyleRef.style_button(_retry_btn, Color.BLACK, Color(0.95, 0.46, 0.48))

	# Screen FX: dark red glow + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects($Panel, Color(0.8, 0.2, 0.15, 0.1), 15, Color(0.5, 0.1, 0.1))

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
