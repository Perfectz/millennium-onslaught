## Premium glassmorphism theme for hub screens (overworld, town).
class_name HighTechTheme
extends RefCounted


static var _theme: Theme


static func apply_theme(control: Control) -> void:
	control.theme = get_theme()


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


## Animated nebula/bokeh background shader — replaces the flat gradient.
static func create_background_gradient(top_color: Color = Color(0.05, 0.08, 0.14, 0.7), bottom_color: Color = Color(0.01, 0.03, 0.07, 0.8)) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
void fragment() {
	vec4 grad = mix(top_color, bottom_color, UV.y);
	// Soft tech grid with variable density
	float fine_x = step(0.988, fract(UV.x * 120.0));
	float fine_y = step(0.988, fract(UV.y * 68.0));
	float coarse_x = step(0.994, fract(UV.x * 24.0));
	float coarse_y = step(0.994, fract(UV.y * 14.0));
	float grid = (fine_x + fine_y) * 0.025 + (coarse_x + coarse_y) * 0.06;
	// Slow-drifting nebula glow
	vec2 uv_a = UV * 2.0 + vec2(TIME * 0.015, TIME * 0.008);
	vec2 uv_b = UV * 3.5 - vec2(TIME * 0.012, TIME * -0.01);
	float n_a = sin(uv_a.x * 3.14) * cos(uv_a.y * 2.72) * 0.5 + 0.5;
	float n_b = sin(uv_b.x * 2.33) * cos(uv_b.y * 3.67) * 0.5 + 0.5;
	float nebula = n_a * n_b * 0.15;
	// Radial falloff — brighter near center-right
	vec2 center = vec2(0.62, 0.42);
	float radial = 1.0 - smoothstep(0.0, 0.7, distance(UV, center));
	nebula *= radial;
	vec3 nebula_color = mix(top_color.rgb, vec3(0.18, 0.4, 0.7), 0.5) * nebula;
	COLOR = vec4(grad.rgb + vec3(grid) * 0.8 + nebula_color, grad.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("top_color", top_color)
	mat.set_shader_parameter("bottom_color", bottom_color)
	rect.material = mat
	return rect


## Glass panel with subtle corner radius, accent top-border stripe, and layered depth.
static func create_glass_panel_style(accent: Color, fill_alpha: float = 0.34, border_alpha: float = 0.85) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.11, fill_alpha)
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha * 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	style.shadow_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 0.08)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	return style


## Nav button with left accent stripe, subtle rounding, and distinct state styling.
static func style_nav_button(button: Button, accent: Color, font_size: int = 22) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.flat = false
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.7, 0.8, 0.88))
	button.add_theme_color_override("font_hover_color", Color(0.88, 0.94, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.95, 0.98, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(accent.r, accent.g, accent.b))
	button.add_theme_stylebox_override("normal", _nav_btn_state(accent, 0.22, 0.15, 0))
	button.add_theme_stylebox_override("hover", _nav_btn_state(accent, 0.38, 0.55, 4))
	button.add_theme_stylebox_override("focus", _nav_btn_state(accent, 0.48, 0.9, 10))
	button.add_theme_stylebox_override("pressed", _nav_btn_state(accent, 0.36, 0.7, 6))


## Focus scale + tint animation for interactive controls.
static func wire_focus_pop(control: Control, focus_scale: float = 1.04) -> void:
	control.pivot_offset = control.size * 0.5
	control.resized.connect(func() -> void:
		control.pivot_offset = control.size * 0.5
	)
	control.focus_entered.connect(func() -> void:
		_animate_focus(control, focus_scale, Color(1.08, 1.1, 1.12))
	)
	control.focus_exited.connect(func() -> void:
		_animate_focus(control, 1.0, Color.WHITE)
	)


## Thin accent-colored separator with gradient fade.
static func create_separator(color: Color = Color(0.5, 0.87, 1.0, 0.35), height: float = 1.0) -> ColorRect:
	var separator := ColorRect.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.custom_minimum_size = Vector2(0, height)
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 line_color : source_color;
void fragment() {
	float fade = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.7, UV.x);
	COLOR = vec4(line_color.rgb, line_color.a * fade);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("line_color", color)
	separator.material = mat
	return separator


## Create an accent-colored selection indicator (vertical bar).
static func create_selection_indicator(accent: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(3, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.color = accent
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


static func _nav_btn_state(accent: Color, fill_alpha: float, border_alpha: float, shadow_size: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.08, 0.13, fill_alpha)
	# Left accent stripe
	s.border_width_left = 3
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 18
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	if shadow_size > 0:
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.15)
		s.shadow_size = shadow_size
		s.shadow_offset = Vector2(0, 1)
	s.anti_aliasing = true
	s.anti_aliasing_size = 1.0
	return s


static func _animate_focus(control: Control, scale_amount: float, tint: Color) -> void:
	if control.has_meta("focus_tween"):
		var old_tween: Variant = control.get_meta("focus_tween")
		if old_tween is Tween and is_instance_valid(old_tween):
			(old_tween as Tween).kill()
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE * scale_amount, 0.12)
	tween.parallel().tween_property(control, "self_modulate", tint, 0.12)
	control.set_meta("focus_tween", tween)


static func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.set_font_size("font_size", "Label", 16)
	theme.set_font_size("font_size", "Button", 20)
	theme.set_color("font_color", "Label", Color(0.86, 0.92, 0.97))
	theme.set_constant("outline_size", "Label", 1)
	theme.set_color("font_outline_color", "Label", Color(0.0, 0.0, 0.0, 0.55))
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	return theme
