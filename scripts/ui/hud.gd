## HUD overlay showing health bar, TP bar, and combo counter.
class_name HUD
extends CanvasLayer


@onready var health_bar: ProgressBar = $HealthBar
@onready var tp_bar: ProgressBar = $TPBar
@onready var combo_label: Label = $ComboLabel
@onready var combo_counter: Label = $ComboCounter

var _combo_count: int = 0
var _combo_fade_timer: float = 0.0

const COMBO_FADE_TIME: float = 2.0


func _ready() -> void:
	layer = 10  # Render on top of everything.
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_tp_changed.connect(_on_tp_changed)
	EventBus.combat_combo_step.connect(_on_combo_step)
	EventBus.combat_combo_dropped.connect(_on_combo_dropped)
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	_hide_combo()


func _process(delta: float) -> void:
	if _combo_fade_timer > 0.0:
		_combo_fade_timer -= delta
		if _combo_fade_timer <= 0.0:
			_hide_combo()


## Update health bar display.
func update_health(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current


## Update TP bar display.
func update_tp(current: float, maximum: float) -> void:
	if tp_bar:
		tp_bar.max_value = maximum
		tp_bar.value = current


## Show combo counter.
func show_combo(count: int) -> void:
	_combo_count = count
	if combo_counter:
		combo_counter.text = str(count)
		combo_counter.visible = true
	if combo_label:
		combo_label.visible = true
	_combo_fade_timer = COMBO_FADE_TIME


func _hide_combo() -> void:
	_combo_count = 0
	if combo_counter:
		combo_counter.visible = false
	if combo_label:
		combo_label.visible = false


func _on_health_changed(player_index: int, new_hp: float, max_hp: float) -> void:
	if player_index == 0:
		update_health(new_hp, max_hp)


func _on_tp_changed(player_index: int, new_tp: float, max_tp: float) -> void:
	if player_index == 0:
		update_tp(new_tp, max_tp)


func _on_combo_step(_player: Node, step: int) -> void:
	show_combo(step)


func _on_combo_dropped(_player: Node) -> void:
	_combo_fade_timer = 0.5


func _on_hit_landed(_attacker: Node, _target: Node, _damage: float, _pos: Vector3) -> void:
	_combo_count += 1
	show_combo(_combo_count)
