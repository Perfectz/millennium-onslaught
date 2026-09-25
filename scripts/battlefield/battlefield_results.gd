## Post-battle results: rank letter, KOs, officers, time, and rewards. Works while paused.
class_name BattlefieldResults
extends CanvasLayer


signal continue_pressed()

const RANK_COLORS: Dictionary = {
	"S": Color(1.0, 0.85, 0.3),
	"A": Color(0.55, 0.9, 1.0),
	"B": Color(0.6, 1.0, 0.6),
	"C": Color(0.9, 0.9, 0.9),
	"D": Color(0.7, 0.7, 0.7),
}

var _button: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS


## Fill in and show the results for a finished battle.
func show_results(title: String, tally: BattleTally, seconds: float, xp: int, gold: int) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -230
	panel.offset_bottom = 230
	var style := BattlefieldHUD._flat(Color(0.03, 0.05, 0.09, 0.95), Color(1.0, 0.78, 0.25, 0.8))
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	_add_label(vbox, "VICTORY", 44, Color(1.0, 0.9, 0.55))
	_add_label(vbox, title, 18, Color(0.7, 0.85, 1.0))
	var rank := tally.get_rank()
	_add_label(vbox, "RANK  %s" % rank, 56, RANK_COLORS.get(rank, Color.WHITE))
	var minutes := int(seconds) / 60
	var secs := int(seconds) % 60
	for line: String in [
		"KOs  ·  %d" % tally.get_ko_count(),
		"Officers defeated  ·  %d" % tally.get_officer_ko_count(),
		"Time  ·  %d:%02d" % [minutes, secs],
		"EXP  ·  +%d" % xp,
		"Meseta  ·  +%d" % gold,
	]:
		_add_label(vbox, line, 20, Color(0.92, 0.95, 1.0))
	_button = Button.new()
	_button.text = "Continue"
	_button.custom_minimum_size = Vector2(200, 44)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(func() -> void: continue_pressed.emit())
	vbox.add_child(_button)
	_button.call_deferred("grab_focus")


func _add_label(parent: Control, text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
