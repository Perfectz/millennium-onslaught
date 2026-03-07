## Camera shake effect. Applies random offset to camera on combat impacts.
## Uses real time (ticks) to work during hitstop.
class_name CameraShakeSystem
extends Node


var camera: Camera3D = null
var _intensity: float = 0.0
var _duration: float = 0.0
var _timer: float = 0.0
var _prev_ticks: int = 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_prev_ticks = Time.get_ticks_usec()
	EventBus.combat_hit_event.connect(_on_hit_event)
	EventBus.combat_kill_event.connect(_on_kill_event)


func _process(_delta: float) -> void:
	if camera == null:
		return

	var now := Time.get_ticks_usec()
	var real_delta := (now - _prev_ticks) / 1_000_000.0
	_prev_ticks = now

	if _timer > 0.0:
		_timer -= real_delta
		var t := clampf(_timer / _duration, 0.0, 1.0)
		var current := _intensity * t
		camera.h_offset = randf_range(-current, current)
		camera.v_offset = randf_range(-current, current)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func shake(intensity: float, duration: float) -> void:
	_intensity = maxf(_intensity, intensity)
	_duration = duration
	_timer = duration


func _on_hit_event(event: CombatHitEvent) -> void:
	if event.damage >= Constants.HEAVY_ATTACK_DAMAGE:
		shake(Constants.CAMERA_SHAKE_HEAVY, Constants.CAMERA_SHAKE_DURATION)
	else:
		shake(Constants.CAMERA_SHAKE_LIGHT, Constants.CAMERA_SHAKE_DURATION)


func _on_kill_event(_event: CombatKillEvent) -> void:
	shake(Constants.CAMERA_SHAKE_KILL, Constants.CAMERA_SHAKE_DURATION)
