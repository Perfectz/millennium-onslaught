## Floating damage number that animates upward and fades out. Pooled.
class_name DamageNumber
extends Node3D


var _label: Label3D = null
var _lifetime: float = 0.0
var _max_lifetime: float = 1.0
var _velocity: Vector3 = Vector3.ZERO
var _active: bool = false


func _ready() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 32
	add_child(_label)


func _process(delta: float) -> void:
	if not _active:
		return
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_lifetime += capped_delta
	position += _velocity * capped_delta
	_velocity.y *= 0.95  # Decelerate upward motion.
	# Fade out.
	var alpha: float = 1.0 - (_lifetime / _max_lifetime)
	if _label:
		_label.modulate.a = maxf(0.0, alpha)
	if _lifetime >= _max_lifetime:
		_deactivate()


## Show a damage number at a position.
func activate(value: float, pos: Vector3) -> void:
	_active = true
	_lifetime = 0.0
	global_position = pos
	_velocity = Vector3(randf_range(-1.0, 1.0), 3.0, 0.0)
	if _label:
		_label.text = str(int(value))
		_label.modulate.a = 1.0
	visible = true


func _deactivate() -> void:
	_active = false
	visible = false
	ObjectPool.return_instance(self)
