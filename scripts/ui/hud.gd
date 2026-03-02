## Main HUD controller. Subscribes to EventBus signals and updates UI elements.
class_name HUD
extends CanvasLayer


@onready var hp_bar_fill: ColorRect = $Panel/VBox/HPBar/HPBarBG/HPBarFill
@onready var hp_label: Label = $Panel/VBox/HPBar/HPLabel
@onready var tp_bar_fill: ColorRect = $Panel/VBox/TPBar/TPBarBG/TPBarFill
@onready var tp_label: Label = $Panel/VBox/TPBar/TPLabel
@onready var combo_label: Label = $Panel/ComboCounter
@onready var state_label: Label = $Panel/StateLabel

var _hp_display: float = 1.0
var _hp_target: float = 1.0
var _combo_count: int = 0
var _combo_timer: float = 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_tp_changed.connect(_on_tp_changed)
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_combo_step.connect(_on_combo_step)
	EventBus.combat_combo_dropped.connect(_on_combo_dropped)
	combo_label.visible = false


func _process(delta: float) -> void:
	# Smooth HP bar lerp.
	if absf(_hp_display - _hp_target) > 0.001:
		_hp_display = lerpf(_hp_display, _hp_target, Constants.HUD_HP_BAR_LERP_SPEED * delta)
		_update_hp_bar_visual()

	# Combo counter fade timer.
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo_label.visible = false
			_combo_count = 0


func _on_health_changed(_player_index: int, new_hp: float, max_hp: float) -> void:
	_hp_target = clampf(new_hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	hp_label.text = "HP  %.0f / %.0f" % [new_hp, max_hp]


func _on_tp_changed(_player_index: int, new_tp: float, max_tp: float) -> void:
	var ratio := clampf(new_tp / max_tp, 0.0, 1.0) if max_tp > 0.0 else 0.0
	tp_bar_fill.size.x = 196.0 * ratio
	tp_label.text = "TP  %.0f / %.0f" % [new_tp, max_tp]


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, hit_position: Vector3) -> void:
	_combo_count += 1
	_combo_timer = Constants.HUD_COMBO_DISPLAY_TIME
	combo_label.text = "HIT %d" % _combo_count
	combo_label.visible = true
	# Spawn floating damage number.
	_spawn_damage_number(damage, hit_position)


func _on_combo_step(_player: Node, _step: int) -> void:
	pass


func _on_combo_dropped(_player: Node) -> void:
	_combo_count = 0
	_combo_timer = 0.0
	combo_label.visible = false


func _update_hp_bar_visual() -> void:
	hp_bar_fill.size.x = 196.0 * _hp_display
	if _hp_display > 0.5:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2).lerp(Color(0.9, 0.9, 0.2), (1.0 - _hp_display) * 2.0)
	else:
		hp_bar_fill.color = Color(0.9, 0.9, 0.2).lerp(Color(0.9, 0.1, 0.1), (0.5 - _hp_display) * 2.0)


func _spawn_damage_number(damage: float, world_pos: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var screen_pos := cam.unproject_position(world_pos)
	var label := Label.new()
	label.text = str(int(damage))
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	label.position = screen_pos - Vector2(20, 20)
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - Constants.HUD_DAMAGE_NUMBER_RISE_SPEED, Constants.HUD_DAMAGE_NUMBER_LIFETIME)
	tween.parallel().tween_property(label, "modulate:a", 0.0, Constants.HUD_DAMAGE_NUMBER_LIFETIME)
	tween.tween_callback(label.queue_free)


## Update debug state info (called from arena).
func update_state_info(info: String) -> void:
	if state_label:
		state_label.text = info
