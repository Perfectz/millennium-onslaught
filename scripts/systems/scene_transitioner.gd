## Scene transitions with multiple wipe styles: fade, diamond iris, directional slash, pixelate.
## Creates its own CanvasLayer + shader overlay.
class_name SceneTransitioner
extends CanvasLayer


enum WipeStyle {
	FADE,
	DIAMOND_IRIS,
	DIRECTIONAL_SLASH,
	PIXELATE,
}

const FADE_DURATION: float = 0.5

var _wipe_rect: ColorRect
var _wipe_material: ShaderMaterial
var _is_transitioning: bool = false
var _current_style: WipeStyle = WipeStyle.FADE


## Shader source - supports all wipe modes via a uniform int.
const WIPE_SHADER: String = """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int wipe_mode = 0; // 0=fade, 1=diamond, 2=slash, 3=pixelate
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.3) = 0.05;

void fragment() {
	float mask = 0.0;
	if (wipe_mode == 0) {
		// Simple fade
		mask = progress;
	} else if (wipe_mode == 1) {
		// Diamond iris from center
		vec2 p = abs(UV - 0.5) * 2.0;
		float diamond = p.x + p.y;
		mask = smoothstep(diamond - softness, diamond + softness, progress * 2.0);
	} else if (wipe_mode == 2) {
		// Directional slash (diagonal)
		float diag = (UV.x + UV.y) * 0.5;
		mask = smoothstep(diag - softness * 2.0, diag + softness * 2.0, progress);
	} else if (wipe_mode == 3) {
		// Pixelate dissolve
		float block_size = mix(1.0, 80.0, 1.0 - progress);
		vec2 block_uv = floor(UV * block_size) / block_size;
		float noise = fract(sin(dot(block_uv, vec2(12.9898, 78.233))) * 43758.5453);
		mask = step(noise, progress);
	}
	COLOR = vec4(wipe_color.rgb, mask);
}
"""


func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS

	_wipe_rect = ColorRect.new()
	_wipe_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = WIPE_SHADER
	_wipe_material = ShaderMaterial.new()
	_wipe_material.shader = shader
	_wipe_material.set_shader_parameter("progress", 0.0)
	_wipe_material.set_shader_parameter("wipe_mode", 0)
	_wipe_material.set_shader_parameter("wipe_color", Color.BLACK)
	_wipe_rect.material = _wipe_material
	add_child(_wipe_rect)


## Default transition (backwards-compatible).
func transition_to(scene_path: String, duration: float = FADE_DURATION) -> void:
	transition_to_styled(scene_path, WipeStyle.FADE, duration)


## Transition with a specific wipe style.
func transition_to_styled(scene_path: String, style: WipeStyle = WipeStyle.FADE, duration: float = FADE_DURATION) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_current_style = style
	_wipe_material.set_shader_parameter("wipe_mode", int(style))

	EventBus.emit_checked(&"scene_transition_started", [scene_path], {
		"target_scene": scene_path,
		"style": style,
	}, true)

	# Wipe out (progress 0 -> 1).
	await _animate_progress(1.0, duration * 0.5)

	# Change scene.
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneTransitioner: Failed to load scene: " + scene_path)
		await _animate_progress(0.0, duration * 0.5)
		_is_transitioning = false
		return

	# Wait one frame for the new scene to initialize.
	await get_tree().process_frame

	# Wipe in (progress 1 -> 0).
	await _animate_progress(0.0, duration * 0.5)

	_is_transitioning = false
	EventBus.emit_checked(&"scene_transition_completed", [scene_path], {
		"target_scene": scene_path,
	}, true)


## Check if a transition is in progress.
func is_transitioning() -> bool:
	return _is_transitioning


## Set the default wipe color.
func set_wipe_color(color: Color) -> void:
	_wipe_material.set_shader_parameter("wipe_color", color)


## Internal: animate the shader progress uniform.
func _animate_progress(target: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(v: float) -> void:
		_wipe_material.set_shader_parameter("progress", v)
	, float(_wipe_material.get_shader_parameter("progress")), target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _exit_tree() -> void:
	if _wipe_rect != null and is_instance_valid(_wipe_rect):
		_wipe_rect.material = null
		_wipe_rect.free()
	_wipe_rect = null
	if _wipe_material != null:
		_wipe_material.shader = null
	_wipe_material = null
