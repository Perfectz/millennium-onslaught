## Victory screen — displays dungeon completion stats and score.
extends CanvasLayer


signal continue_pressed

@onready var _title_label: Label = $Panel/VBox/TitleLabel
@onready var _kills_label: Label = $Panel/VBox/KillsLabel
@onready var _time_label: Label = $Panel/VBox/TimeLabel
@onready var _combo_label: Label = $Panel/VBox/ComboLabel
@onready var _score_label: Label = $Panel/VBox/ScoreLabel
@onready var _continue_btn: Button = $Panel/VBox/ContinueButton


func _ready() -> void:
	_continue_btn.pressed.connect(func() -> void: continue_pressed.emit())
	process_mode = Node.PROCESS_MODE_ALWAYS


## Populate stats from a ScoreTracker.
func display_stats(tracker: ScoreTracker) -> void:
	_kills_label.text = "Kills: %d" % tracker.get_kill_count()
	var elapsed := tracker.get_elapsed_time()
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	_time_label.text = "Time: %d:%02d" % [minutes, seconds]
	_combo_label.text = "Max Combo: %d" % tracker.get_max_combo()
	_score_label.text = "SCORE: %d" % tracker.calculate_score()
