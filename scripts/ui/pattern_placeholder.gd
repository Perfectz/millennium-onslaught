## Stylized placeholder panel with animated shader, corner markers, and status indicator.
class_name PatternPlaceholder
extends PanelContainer


@export var title_text: String = "PLACEHOLDER"
@export var subtitle_text: String = "MISSING ASSET"
@export var base_color: Color = Color(0.08, 0.11, 0.17, 0.82)
@export var accent_color: Color = Color(0.33, 0.9, 1.0, 1.0)

var _title_label: Label
var _subtitle_label: Label
var _fill: ColorRect
var _status_dot: ColorRect


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_apply_visuals()
	_apply_text()


func set_content(title: String, subtitle: String = "") -> void:
	title_text = title
	subtitle_text = subtitle
	_apply_text()


func set_palette(base: Color, accent: Color) -> void:
	base_color = base
	accent_color = accent
	_apply_visuals()


func _build_ui() -> void:
	if _fill != null:
		return

	# Main animated fill
	_fill = ColorRect.new()
	_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	# Dark gradient overlay for depth
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ov_shader := Shader.new()
	ov_shader.code = """shader_type canvas_item;
void fragment() {
	float edge = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x)
		* smoothstep(0.0, 0.08, UV.y) * smoothstep(1.0, 0.92, UV.y);
	float center_bright = 1.0 - distance(UV, vec2(0.5)) * 0.4;
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - edge) * 0.35 + (1.0 - center_bright) * 0.12);
}
"""
	var ov_mat := ShaderMaterial.new()
	ov_mat.shader = ov_shader
	overlay.material = ov_mat
	add_child(overlay)

	# Corner markers (top-left and bottom-right brackets)
	for corner_data in [
		{"anchor_h": 0.0, "anchor_v": 0.0, "offset": Vector2(6, 6), "flip": Vector2(1, 1)},
		{"anchor_h": 1.0, "anchor_v": 1.0, "offset": Vector2(-6, -6), "flip": Vector2(-1, -1)},
	]:
		var marker := _create_corner_marker(corner_data)
		add_child(marker)

	# Content area
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	_title_label.add_theme_constant_override("outline_size", 1)
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	content.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.8))
	content.add_child(_subtitle_label)

	# Status indicator dot (top-right, pulsing)
	_status_dot = ColorRect.new()
	_status_dot.custom_minimum_size = Vector2(6, 6)
	_status_dot.size = Vector2(6, 6)
	_status_dot.anchor_left = 1.0
	_status_dot.anchor_right = 1.0
	_status_dot.offset_left = -16
	_status_dot.offset_top = 8
	_status_dot.offset_right = -10
	_status_dot.offset_bottom = 14
	_status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_dot)


func _create_corner_marker(data: Dictionary) -> Control:
	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var h_line := ColorRect.new()
	var v_line := ColorRect.new()
	h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ah: float = data["anchor_h"]
	var av: float = data["anchor_v"]
	var off: Vector2 = data["offset"]
	var fl: Vector2 = data["flip"]

	# Horizontal line (12px wide, 1px tall)
	h_line.anchor_left = ah
	h_line.anchor_right = ah
	h_line.anchor_top = av
	h_line.anchor_bottom = av
	h_line.offset_left = off.x
	h_line.offset_right = off.x + 14.0 * fl.x
	h_line.offset_top = off.y
	h_line.offset_bottom = off.y + 1.0
	container.add_child(h_line)

	# Vertical line (1px wide, 12px tall)
	v_line.anchor_left = ah
	v_line.anchor_right = ah
	v_line.anchor_top = av
	v_line.anchor_bottom = av
	v_line.offset_left = off.x
	v_line.offset_right = off.x + 1.0
	v_line.offset_top = off.y
	v_line.offset_bottom = off.y + 14.0 * fl.y
	container.add_child(v_line)

	# Store refs for color updates
	container.set_meta("h_line", h_line)
	container.set_meta("v_line", v_line)
	return container


func _apply_text() -> void:
	if _title_label == null:
		return
	_title_label.text = title_text.to_upper()
	_subtitle_label.text = subtitle_text


func _apply_visuals() -> void:
	if _fill == null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.anti_aliasing = true
	add_theme_stylebox_override("panel", style)

	_fill.material = _build_fill_material()

	# Update corner marker colors
	var marker_color := Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
	for child in get_children():
		if child is Control and child.has_meta("h_line"):
			(child.get_meta("h_line") as ColorRect).color = marker_color
			(child.get_meta("v_line") as ColorRect).color = marker_color

	# Status dot color
	if _status_dot:
		_status_dot.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.7)


func _build_fill_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 base_color : source_color;
uniform vec4 accent_color : source_color;
void fragment() {
	// Hex-grid pattern
	vec2 hex_uv = UV * vec2(18.0, 10.0);
	float hex_x = fract(hex_uv.x);
	float hex_y = fract(hex_uv.y + step(0.5, fract(hex_uv.x * 0.5)) * 0.5);
	float hex = smoothstep(0.48, 0.5, max(abs(hex_x - 0.5), abs(hex_y - 0.5)));
	// Slow scan line
	float scan = smoothstep(0.0, 0.02, abs(fract(UV.y - TIME * 0.06) - 0.5) - 0.48);
	float scan_bright = (1.0 - scan) * 0.12;
	// Subtle noise drift
	float drift = sin(UV.x * 7.0 + TIME * 0.4) * cos(UV.y * 5.0 + TIME * 0.3) * 0.5 + 0.5;
	float mix_amt = hex * 0.12 + drift * 0.06 + scan_bright;
	vec3 color_mix = mix(base_color.rgb, accent_color.rgb, clamp(mix_amt, 0.0, 1.0));
	COLOR = vec4(color_mix, base_color.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("accent_color", accent_color)
	return mat
