## Battlefield-specific effects: Combination shockwave rings and flash. Event-driven.
class_name BattlefieldVFX
extends Node3D


const RING_POOL: int = 6
const RING_TIME: float = 0.45
const FLASH_ENERGY: float = 6.0
const ELEMENT_COLORS: Dictionary = {
	&"fire": Color(1.0, 0.45, 0.15),
	&"ice": Color(0.55, 0.85, 1.0),
	&"lightning": Color(0.8, 0.7, 1.0),
	&"dark": Color(0.75, 0.3, 0.95),
}
const DEFAULT_COLOR := Color(1.0, 0.85, 0.4)

var _rings: Array[MeshInstance3D] = []
var _next_ring: int = 0
var _flash: OmniLight3D
var _color: Color = DEFAULT_COLOR


func _ready() -> void:
	for i in RING_POOL:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.85
		torus.outer_radius = 1.0
		torus.rings = 40
		ring.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.visible = false
		add_child(ring)
		_rings.append(ring)
	_flash = OmniLight3D.new()
	_flash.omni_range = Constants.COMBINATION_ATTACK_RADIUS * 2.0
	_flash.light_energy = 0.0
	add_child(_flash)
	EventBus.combat_combination_started.connect(_on_started)
	EventBus.combat_combination_pulse.connect(_on_pulse)


func _on_started(player: Node, element: StringName) -> void:
	_color = ELEMENT_COLORS.get(element, DEFAULT_COLOR)
	if player is Node3D:
		_flash.global_position = (player as Node3D).global_position + Vector3(0, 1.5, 0)
	_flash.light_color = _color
	_flash.light_energy = FLASH_ENERGY
	var t := create_tween()
	t.tween_property(_flash, "light_energy", 0.0, Constants.COMBINATION_ATTACK_DURATION)
	JuiceManager.screen_flash(Color(_color, 0.35), 0.12)
	JuiceManager.zoom_punch(5.0, 0.3)


func _on_pulse(_player: Node, origin: Vector3, radius: float) -> void:
	var ring := _rings[_next_ring]
	_next_ring = (_next_ring + 1) % _rings.size()
	var mat := ring.material_override as StandardMaterial3D
	mat.albedo_color = Color(_color, 0.9)
	ring.global_position = origin + Vector3(0, 0.25, 0)
	ring.scale = Vector3(0.3, 0.3, 0.3)
	ring.visible = true
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector3(radius, radius * 0.4, radius), RING_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, RING_TIME)
	t.chain().tween_callback(func() -> void: ring.visible = false)
	JuiceManager.directional_shake(Constants.CAMERA_SHAKE_HEAVY, Constants.CAMERA_SHAKE_DURATION, Vector3.UP)
