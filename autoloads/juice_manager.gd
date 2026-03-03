## Centralized screen-juice effects: directional shake, screen flash, slow-mo, zoom punch, damage vignette.
## All effects are event-driven via EventBus.
class_name JuiceManagerSingleton
extends Node


# ── State ────────────────────────────────────────────────────────────

var _camera_follow: CameraFollow = null
var _slowmo_tween: Tween = null

## Overlay nodes (created once, reused).
var _flash_rect: ColorRect = null
var _vignette_rect: ColorRect = null
var _vignette_shader: ShaderMaterial = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlays()
	_connect_events()


# ── Overlay Setup ────────────────────────────────────────────────────


func _create_overlays() -> void:
	# Screen flash overlay
	var canvas := CanvasLayer.new()
	canvas.name = "JuiceCanvas"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashRect"
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.visible = false
	canvas.add_child(_flash_rect)

	# Damage vignette overlay
	_vignette_rect = ColorRect.new()
	_vignette_rect.name = "DamageVignette"
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_rect.visible = false

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.8, 0.05, 0.05, 1.0);
void fragment() {
	vec2 p = UV - 0.5;
	float d = dot(p, p);
	float vig = smoothstep(0.12, 0.55, d) * intensity;
	COLOR = vec4(vignette_color.rgb, vig * vignette_color.a);
}
"""
	_vignette_shader = ShaderMaterial.new()
	_vignette_shader.shader = shader
	_vignette_shader.set_shader_parameter("intensity", 0.0)
	_vignette_rect.material = _vignette_shader
	canvas.add_child(_vignette_rect)


# ── Event Connections ────────────────────────────────────────────────


func _connect_events() -> void:
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.enemy_wave_cleared.connect(_on_wave_cleared)


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, hit_position: Vector3, attack_data: AttackDef) -> void:
	var is_heavy := damage >= Constants.HEAVY_ATTACK_DAMAGE
	var shake_str := Constants.CAMERA_SHAKE_HEAVY if is_heavy else Constants.CAMERA_SHAKE_LIGHT
	var direction := Vector3.RIGHT
	if _attacker is Node3D and _target is Node3D:
		direction = (_target.global_position - _attacker.global_position).normalized()
	directional_shake(shake_str, Constants.CAMERA_SHAKE_DURATION, direction)
	if attack_data and (attack_data.attack_name == &"heavy" or attack_data.is_launcher):
		zoom_punch(3.0, 0.16)
	if is_heavy:
		screen_flash(Color(1, 1, 1, 0.15), 0.06)


func _on_kill(_attacker: Node, _target: Node, kill_position: Vector3) -> void:
	directional_shake(Constants.CAMERA_SHAKE_KILL, Constants.CAMERA_SHAKE_DURATION * 1.3, Vector3.UP)
	screen_flash(Color(1, 0.95, 0.8, 0.25), 0.08)
	slow_motion(0.15, Constants.HITSTOP_KILL_DURATION)


func _on_wave_cleared() -> void:
	slow_motion(0.08, 0.35)
	zoom_punch(4.0, 0.25)
	screen_flash(Color(1.0, 0.95, 0.8, 0.3), 0.1)


func _on_player_health_changed(player_index: int, new_hp: float, max_hp: float) -> void:
	var ratio := new_hp / maxf(max_hp, 1.0)
	if ratio < 0.3:
		damage_vignette(0.5, 0.4)
	elif ratio < 0.5:
		damage_vignette(0.25, 0.3)


# ── Public API ───────────────────────────────────────────────────────


## Directional camera shake via CameraFollow's trauma system.
func directional_shake(intensity: float, _duration: float, _direction: Vector3 = Vector3.RIGHT) -> void:
	_find_camera_follow()
	if _camera_follow:
		# Convert intensity to trauma (0-1 range). Typical values: light=0.4, heavy=0.8, kill=1.2.
		var trauma_amount := clampf(intensity * 0.6, 0.0, 1.0)
		_camera_follow.add_trauma(trauma_amount)


## Full-screen color flash (white for crits, red for damage, etc).
func screen_flash(color: Color, duration: float) -> void:
	_flash_rect.color = color
	_flash_rect.visible = true
	_flash_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func() -> void: _flash_rect.visible = false)


## Brief slow-motion (time scale dip then restore).
func slow_motion(time_scale: float, duration: float) -> void:
	if _slowmo_tween != null:
		_slowmo_tween.kill()
	Engine.time_scale = time_scale
	_slowmo_tween = create_tween()
	_slowmo_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_slowmo_tween.tween_property(Engine, "time_scale", 1.0, duration * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_slowmo_tween.tween_callback(func() -> void: Engine.time_scale = 1.0)


## Red vignette pulse when player takes heavy damage or is low HP.
func damage_vignette(intensity: float, duration: float) -> void:
	_vignette_rect.visible = true
	_vignette_shader.set_shader_parameter("intensity", intensity)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(v: float) -> void:
		_vignette_shader.set_shader_parameter("intensity", v)
	, intensity, 0.0, duration)
	tween.tween_callback(func() -> void: _vignette_rect.visible = false)


## Camera zoom punch (zoom in briefly then back).
func zoom_punch(zoom_amount: float, duration: float) -> void:
	_find_camera_follow()
	if _camera_follow == null:
		return
	var original_fov := _camera_follow.fov
	var target_fov := original_fov - zoom_amount
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_camera_follow, "fov", target_fov, duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_camera_follow, "fov", original_fov, duration * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


# ── Internals ────────────────────────────────────────────────────────


func _find_camera_follow() -> void:
	if _camera_follow != null and is_instance_valid(_camera_follow):
		return
	var cam := get_viewport().get_camera_3d()
	if cam is CameraFollow:
		_camera_follow = cam as CameraFollow
