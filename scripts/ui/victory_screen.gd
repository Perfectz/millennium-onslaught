## Victory screen - displays dungeon completion stats and score.
extends CanvasLayer


signal continue_pressed

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var _overlay: ColorRect = $Overlay
@onready var _card: PanelContainer = $Panel/Card
@onready var _title_label: Label = $Panel/Card/Margin/VBox/TitleLabel
@onready var _rank_label: Label = $Panel/Card/Margin/VBox/RankLabel
@onready var _kills_label: Label = $Panel/Card/Margin/VBox/KillsLabel
@onready var _time_label: Label = $Panel/Card/Margin/VBox/TimeLabel
@onready var _combo_label: Label = $Panel/Card/Margin/VBox/ComboLabel
@onready var _score_label: Label = $Panel/Card/Margin/VBox/ScorePanel/ScoreLabel
@onready var _continue_btn: Button = $Panel/Card/Margin/VBox/ContinueButton


func _ready() -> void:
	UIStyleRef.apply_theme($Panel)
	_continue_btn.pressed.connect(func() -> void: continue_pressed.emit())
	UIStyleRef.wire_button_sounds(_continue_btn)
	_continue_btn.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Override .tscn styles with glass-morphism.
	_card.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
		Color(0.06, 0.08, 0.14, 0.55),
		Color(0.38, 0.8, 1.0, 0.25),
		6
	))
	var score_panel := $Panel/Card/Margin/VBox/ScorePanel as PanelContainer
	if score_panel:
		score_panel.add_theme_stylebox_override("panel", UIStyleRef.create_panel_style(
			Color(0.05, 0.07, 0.12, 0.5),
			Color(0.3, 0.6, 0.9, 0.2),
			4
		))
	UIStyleRef.style_button(_continue_btn, Color.BLACK, Color(0.38, 0.8, 1.0))

	# Screen FX: blue glow + particles + vignette + scanlines.
	UIStyleRef.apply_screen_effects($Panel, Color(1.0, 0.88, 0.5, 0.12), 20, Color(0.12, 0.35, 0.8))

	_play_intro()


func _play_intro() -> void:
	UIStyleRef.play_modal_intro(_overlay, _card)
	# Title glow pulse.
	UIStyleRef.start_glow_pulse(_title_label, Color(1.15, 1.12, 1.05), Color(0.95, 0.96, 0.98), 2.5)


## Populate stats from a ScoreTracker with count-up animations.
## Optional xp_earned and gold_earned show RPG rewards.
func display_stats(tracker: ScoreTracker, xp_earned: int = 0, gold_earned: int = 0) -> void:
	var kills := tracker.get_kill_count()
	var elapsed := tracker.get_elapsed_time()
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	var max_combo := tracker.get_max_combo()
	var score := tracker.calculate_score()
	var rank := _compute_rank(score, kills, max_combo, elapsed)

	# Animate rank reveal.
	_rank_label.text = "RANK %s" % rank
	_rank_label.add_theme_color_override("font_color", UIStyleRef.rank_color(rank))
	_rank_label.scale = Vector2(0.5, 0.5)
	_rank_label.modulate.a = 0.0
	var rank_tween := _rank_label.create_tween()
	rank_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rank_tween.tween_interval(0.3)
	rank_tween.tween_property(_rank_label, "modulate:a", 1.0, 0.2)
	rank_tween.parallel().tween_property(_rank_label, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rank_tween.tween_property(_rank_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Rank glow pulse.
	rank_tween.tween_callback(func() -> void:
		UIStyleRef.start_glow_pulse(_rank_label, Color(1.12, 1.1, 1.08), Color(0.95, 0.96, 0.97), 2.0)
	)

	# Count-up animations for stats (staggered).
	UIStyleRef.count_up(_kills_label, "Kills: %d", kills, 0.8)
	_time_label.text = "Time: %d:%02d" % [minutes, seconds]
	var combo_tween := _combo_label.create_tween()
	combo_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	combo_tween.tween_interval(0.3)
	combo_tween.tween_callback(func() -> void:
		UIStyleRef.count_up(_combo_label, "Max Combo: %d", max_combo, 0.6)
	)

	# Score count-up with delay.
	var score_tween := _score_label.create_tween()
	score_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	score_tween.tween_interval(0.6)
	score_tween.tween_callback(func() -> void:
		UIStyleRef.count_up(_score_label, "SCORE: %d", score, 1.2)
	)

	# Add XP and gold earned labels dynamically if values > 0.
	var vbox := _score_label.get_parent().get_parent()
	if xp_earned > 0 or gold_earned > 0:
		var rewards_label := Label.new()
		rewards_label.name = "RewardsLabel"
		rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_label.add_theme_font_size_override("font_size", 20)
		rewards_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
		var reward_parts: Array[String] = []
		if xp_earned > 0:
			reward_parts.append("+%d XP" % xp_earned)
		if gold_earned > 0:
			reward_parts.append("+%d Gold" % gold_earned)
		rewards_label.text = " | ".join(reward_parts)
		rewards_label.modulate.a = 0.0
		vbox.add_child(rewards_label)
		vbox.move_child(rewards_label, vbox.get_child_count() - 1)
		var reward_tween := rewards_label.create_tween()
		reward_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reward_tween.tween_interval(1.0)
		reward_tween.tween_property(rewards_label, "modulate:a", 1.0, 0.3)


func _compute_rank(score: int, kills: int, max_combo: int, elapsed_seconds: float) -> String:
	var performance := score + (kills * 250) + (max_combo * 120)
	if elapsed_seconds <= 180.0:
		performance += 1500
	elif elapsed_seconds <= 300.0:
		performance += 900
	elif elapsed_seconds <= 420.0:
		performance += 450

	if performance >= 14000:
		return "S"
	if performance >= 10000:
		return "A"
	if performance >= 7000:
		return "B"
	if performance >= 4200:
		return "C"
	return "D"


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
