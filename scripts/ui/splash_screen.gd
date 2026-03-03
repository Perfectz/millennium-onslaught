## Studio splash screen shown before the title screen.
## Fades in logo text, holds, then transitions to title.
class_name SplashScreen
extends Control


const UIStyleRef = preload("res://scripts/ui/ui_style.gd")
const HOLD_TIME: float = 2.0
const FADE_IN_TIME: float = 0.8
const FADE_OUT_TIME: float = 0.6

@onready var _logo_label: Label = $CenterContainer/VBox/LogoLabel
@onready var _subtitle_label: Label = $CenterContainer/VBox/SubtitleLabel
@onready var _bg: ColorRect = $Background


func _ready() -> void:
	# Subtle glow orb + vignette for atmosphere.
	_bg.add_child(UIStyleRef.create_glow_orb(Color(0.08, 0.15, 0.4), 0.12))
	_bg.add_child(UIStyleRef.create_vignette(0.45))

	# Start invisible.
	_logo_label.modulate.a = 0.0
	_subtitle_label.modulate.a = 0.0

	# Skip on any input.
	set_process_input(true)

	_play_intro()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_skip_to_title()
	elif event is InputEventMouseButton and event.pressed:
		_skip_to_title()
	elif event is InputEventJoypadButton and event.pressed:
		_skip_to_title()


func _play_intro() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Fade in logo.
	tween.tween_property(_logo_label, "modulate:a", 1.0, FADE_IN_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Fade in subtitle with delay.
	tween.tween_property(_subtitle_label, "modulate:a", 0.6, FADE_IN_TIME * 0.6).set_ease(Tween.EASE_OUT)

	# Hold.
	tween.tween_interval(HOLD_TIME)

	# Transition to title.
	tween.tween_callback(_go_to_title)


func _skip_to_title() -> void:
	set_process_input(false)
	_go_to_title()


func _go_to_title() -> void:
	set_process_input(false)
	GameManager.change_phase(GameManager.Phase.MAIN_MENU)
	GameManager.transition_to_scene(Constants.SCENE_MAIN_MENU)
