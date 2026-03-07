## Shared modern RPG UI style and transition helpers.
class_name UIStyle
extends RefCounted


static var _theme: Theme
static var _particle_texture: Texture2D


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func apply_theme(control: Control) -> void:
	control.theme = get_theme()


static func play_modal_intro(overlay: ColorRect, card: Control) -> void:
	if overlay:
		var target_alpha := overlay.color.a
		overlay.color.a = 0.0
		var overlay_tween := overlay.create_tween()
		overlay_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		overlay_tween.set_trans(Tween.TRANS_QUAD)
		overlay_tween.set_ease(Tween.EASE_OUT)
		overlay_tween.tween_property(overlay, "color:a", target_alpha, 0.2)

	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0.0
	var card_tween := card.create_tween()
	card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	card_tween.set_trans(Tween.TRANS_QUAD)
	card_tween.set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card, "modulate:a", 1.0, 0.18)
	card_tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.24)


static func style_button(button: Button, _base_color: Color, border_color: Color, font_size: int = 22) -> void:
	var accent := border_color
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.84, 0.92, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_color_override("font_disabled_color", Color(0.44, 0.52, 0.6))
	button.add_theme_stylebox_override("normal",
		_glass_btn_style(Color(0.05, 0.08, 0.12, 0.42), accent, 0.28, 0))
	button.add_theme_stylebox_override("hover",
		_glass_btn_style(Color(0.07, 0.12, 0.18, 0.62), accent, 0.56, 6))
	var focus_s := _glass_btn_style(Color(0.08, 0.14, 0.21, 0.68), accent, 0.82, 14)
	focus_s.border_width_top = 1
	focus_s.border_width_right = 1
	focus_s.border_width_bottom = 1
	button.add_theme_stylebox_override("focus", focus_s)
	button.add_theme_stylebox_override("pressed",
		_glass_btn_style(Color(0.04, 0.06, 0.09, 0.72), accent, 0.48, 0))
	button.add_theme_stylebox_override("disabled",
		_glass_btn_style(Color(0.04, 0.05, 0.08, 0.28), accent, 0.08, 0))
	add_focus_feedback(button, accent, 1.012)


static func style_tab_button(button: Button, accent: Color, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color",
		Color(0.94, 0.98, 1.0) if active else Color(0.62, 0.72, 0.82))
	button.add_theme_color_override("font_hover_color", Color(0.98, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_stylebox_override("normal", _tab_btn_style(accent, active, false))
	button.add_theme_stylebox_override("hover", _tab_btn_style(accent, true, true))
	button.add_theme_stylebox_override("focus", _tab_btn_style(accent, true, true))
	button.add_theme_stylebox_override("pressed", _tab_btn_style(accent, active, false))
	add_focus_feedback(button, accent, 1.01)


static func style_option_button(button: OptionButton, accent: Color, font_size: int = 18) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 42.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	style_button(button, Color.BLACK, accent, font_size)


static func style_check_box(button: BaseButton, accent: Color, font_size: int = 18) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_stylebox_override("normal",
		_glass_btn_style(Color(0.04, 0.07, 0.12, 0.32), accent, 0.18, 0))
	button.add_theme_stylebox_override("hover",
		_glass_btn_style(Color(0.06, 0.1, 0.16, 0.52), accent, 0.38, 6))
	button.add_theme_stylebox_override("focus",
		_glass_btn_style(Color(0.06, 0.11, 0.18, 0.62), accent, 0.56, 10))
	button.add_theme_stylebox_override("pressed",
		_glass_btn_style(Color(0.04, 0.08, 0.13, 0.56), accent, 0.32, 0))
	add_focus_feedback(button, accent, 1.008)


static func style_slider(slider: HSlider, accent: Color) -> void:
	slider.focus_mode = Control.FOCUS_ALL
	slider.custom_minimum_size.y = maxf(slider.custom_minimum_size.y, 28.0)
	slider.modulate = Color(0.96, 0.98, 1.0)
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.08, 0.11, 0.16, 0.82)
	groove.corner_radius_top_left = 3
	groove.corner_radius_top_right = 3
	groove.corner_radius_bottom_left = 3
	groove.corner_radius_bottom_right = 3
	groove.content_margin_top = 5
	groove.content_margin_bottom = 5
	groove.anti_aliasing = true
	var fill := groove.duplicate() as StyleBoxFlat
	fill.bg_color = Color(accent.r, accent.g, accent.b, 0.62)
	fill.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	fill.shadow_size = 6
	slider.add_theme_stylebox_override("slider", groove)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	add_focus_feedback(slider, accent, 1.0, Color(1.0, 1.0, 1.0, 1.0), Color(0.86, 0.9, 0.96, 1.0))


static func create_panel_style(bg_color: Color, border_color: Color, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, minf(bg_color.a, 0.74))
	style.border_color = Color(border_color.r, border_color.g, border_color.b, minf(border_color.a, 0.42))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var r := mini(corner_radius, 10)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.08)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	return style


static func _glass_btn_style(bg: Color, accent: Color, border_a: float, shadow_sz: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(accent.r, accent.g, accent.b, border_a)
	s.border_width_left = 3
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 20
	s.content_margin_right = 16
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	if shadow_sz > 0:
		s.shadow_color = Color(accent.r, accent.g, accent.b, 0.12)
		s.shadow_size = shadow_sz
	s.anti_aliasing = true
	return s


static func _tab_btn_style(accent: Color, emphasize: bool, lifted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.66 if emphasize else 0.22)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.82 if emphasize else 0.2)
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 18
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	if lifted:
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.14)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 1)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	return style


static func punch(control: Control, strength: float = 0.08) -> void:
	var from := Vector2.ONE * (1.0 + strength)
	control.scale = from
	var tween := control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.2)


static func animate_objective(label: Label, text: String) -> void:
	var target := "OBJECTIVE  |  %s" % text
	if label.text == target:
		return

	if not label.has_meta("_objective_base_x"):
		label.set_meta("_objective_base_x", label.position.x)
	var base_x := float(label.get_meta("_objective_base_x"))

	var out_tween := label.create_tween()
	out_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out_tween.set_trans(Tween.TRANS_QUAD)
	out_tween.set_ease(Tween.EASE_OUT)
	out_tween.tween_property(label, "modulate:a", 0.0, 0.09)
	out_tween.parallel().tween_property(label, "position:x", base_x + 8.0, 0.09)
	out_tween.tween_callback(func() -> void:
		label.text = target
		label.position.x = base_x - 8.0
	)
	out_tween.tween_property(label, "modulate:a", 1.0, 0.11)
	out_tween.parallel().tween_property(label, "position:x", base_x, 0.11)


static func rank_color(rank: String) -> Color:
	match rank:
		"S":
			return Color(1.0, 0.88, 0.43)
		"A":
			return Color(0.7, 0.94, 1.0)
		"B":
			return Color(0.77, 0.9, 1.0)
		"C":
			return Color(0.85, 0.86, 0.9)
		_:
			return Color(0.95, 0.74, 0.74)


# ─── Visual Effect Helpers ──────────────────────────────────────────


## Create floating ambient particles for menu backgrounds.
static func create_particle_field(rect_size: Vector2, color: Color = Color(0.5, 0.7, 1.0, 0.2), count: int = 30) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = count
	particles.lifetime = 5.0
	particles.preprocess = 5.0
	particles.texture = _get_particle_texture()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = rect_size * 0.5
	particles.position = rect_size * 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 6.0
	particles.initial_velocity_max = 18.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	particles.color = color
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.15, color)
	gradient.add_point(0.85, color)
	particles.color_ramp = gradient
	return particles


## Create a vignette overlay for edge darkening.
static func create_vignette(strength: float = 0.4) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float strength : hint_range(0.0, 1.5) = 0.4;\nvoid fragment() {\n\tvec2 uv = UV - 0.5;\n\tfloat vig = 1.0 - dot(uv, uv) * strength * 4.0;\n\tCOLOR = vec4(0.0, 0.0, 0.0, 1.0 - clamp(vig, 0.0, 1.0));\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("strength", strength)
	rect.material = mat
	return rect


## Create subtle scanline overlay.
static func create_scanlines(alpha: float = 0.03) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float alpha_val : hint_range(0.0, 0.2) = 0.03;\nvoid fragment() {\n\tfloat line = step(0.5, fract(FRAGCOORD.y / 2.0));\n\tCOLOR = vec4(0.0, 0.0, 0.0, line * alpha_val);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("alpha_val", alpha)
	rect.material = mat
	return rect


## Slide a control in from an offset position.
static func slide_in(control: Control, from_offset: Vector2, duration: float = 0.25) -> void:
	var target_pos := control.position
	control.position = target_pos + from_offset
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "position", target_pos, duration)
	tween.parallel().tween_property(control, "modulate:a", 1.0, duration * 0.6)


## Flash a control's self_modulate with a color then restore.
static func flash_label(label: Control, flash_color: Color, duration: float = 0.5) -> void:
	label.self_modulate = flash_color
	punch(label, 0.06)
	var tween := label.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "self_modulate", Color.WHITE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## Create a styled horizontal separator.
static func create_separator(color: Color = Color(0.3, 0.5, 0.7, 0.3), height: float = 1.0) -> ColorRect:
	var sep := ColorRect.new()
	sep.color = color
	sep.custom_minimum_size = Vector2(0, height)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep


## Typewriter text reveal on a label.
static func typewriter(label: Label, text: String, chars_per_sec: float = 40.0) -> Tween:
	label.text = text
	label.visible_ratio = 0.0
	var duration := maxf(float(text.length()) / chars_per_sec, 0.1)
	var tween := label.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "visible_ratio", 1.0, duration)
	return tween


## Count up a number in a label.
static func count_up(label: Label, format_str: String, target: int, duration: float = 1.0) -> Tween:
	label.text = format_str % 0
	var tween := label.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void:
		label.text = format_str % int(v)
	, 0.0, float(target), duration)
	return tween


## Create a vertical gradient background.
static func create_gradient_bg(top_color: Color, bottom_color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform vec4 top_color : source_color;\nuniform vec4 bottom_color : source_color;\nvoid fragment() {\n\tCOLOR = mix(top_color, bottom_color, UV.y);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("top_color", top_color)
	mat.set_shader_parameter("bottom_color", bottom_color)
	rect.material = mat
	return rect


## Create an animated moving glow orb for menu backgrounds.
static func create_glow_orb(color: Color = Color(0.12, 0.35, 0.8), intensity: float = 0.18) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform vec4 glow_color : source_color;\nuniform float intensity : hint_range(0.0, 0.5) = 0.18;\nvoid fragment() {\n\tvec2 center = vec2(0.65 + sin(TIME * 0.3) * 0.04, 0.4 + cos(TIME * 0.22) * 0.05);\n\tfloat d = distance(UV, center);\n\tfloat glow = smoothstep(0.55, 0.0, d) * intensity;\n\tCOLOR = vec4(glow_color.rgb, glow);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("intensity", intensity)
	rect.material = mat
	return rect


## Apply standard screen effects (glow orb, particles, vignette, scanlines) to a bg Control.
static func apply_screen_effects(bg: Control, particle_color: Color = Color(0.5, 0.7, 1.0, 0.2), particle_count: int = 30, glow_color: Color = Color(0.12, 0.35, 0.8)) -> void:
	var size := _resolve_effect_size(bg)
	bg.add_child(create_glow_orb(glow_color))
	bg.add_child(create_particle_field(size, particle_color, particle_count))
	bg.add_child(create_vignette(0.28))
	if GameState.scanlines_enabled:
		bg.add_child(create_scanlines(0.018))


## Start a looping glow pulse on a control's self_modulate.
static func start_glow_pulse(control: Control, bright: Color = Color(1.1, 1.08, 1.05), dim: Color = Color(0.92, 0.94, 0.97), period: float = 2.5) -> void:
	var tween := control.create_tween()
	tween.set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(control, "self_modulate", bright, period * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "self_modulate", dim, period * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


static func add_focus_feedback(
	control: Control,
	accent: Color,
	scale_amount: float = 1.01,
	focused_modulate: Color = Color(1.0, 1.0, 1.0, 1.0),
	idle_modulate: Color = Color(0.92, 0.95, 0.99, 1.0)
) -> void:
	if control.has_meta("_ui_focus_feedback_wired"):
		return
	control.set_meta("_ui_focus_feedback_wired", true)
	control.focus_entered.connect(func() -> void:
		_tween_focus_state(control, accent, scale_amount, focused_modulate)
	)
	control.focus_exited.connect(func() -> void:
		_tween_focus_state(control, accent, 1.0, idle_modulate)
	)
	control.mouse_entered.connect(func() -> void:
		if not control.has_focus():
			_tween_focus_state(control, accent, maxf(1.0, scale_amount - 0.004), Color(0.97, 0.99, 1.0, 1.0))
	)
	control.mouse_exited.connect(func() -> void:
		if not control.has_focus():
			_tween_focus_state(control, accent, 1.0, idle_modulate)
	)


static func _get_particle_texture() -> Texture2D:
	if _particle_texture == null:
		var tex := GradientTexture2D.new()
		tex.width = 16
		tex.height = 16
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		tex.gradient = gradient
		_particle_texture = tex
	return _particle_texture


static func _resolve_effect_size(control: Control) -> Vector2:
	var size := control.get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(1920, 1080)
	return size


static func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", Color(0.9, 0.96, 1.0))
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0))
	theme.set_constant("outline_size", "Label", 1)
	theme.set_font_size("font_size", "Label", 16)
	theme.set_font_size("font_size", "Button", 22)
	theme.set_constant("h_separation", "HBoxContainer", 10)
	theme.set_constant("v_separation", "VBoxContainer", 10)
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	return theme


# ─── Menu Transition Helpers ────────────────────────────────────────


## Stagger-animate a list of controls (buttons, labels) into view.
## Position tweening is skipped when parent is a Container (containers manage
## child positions and would conflict with the tween).
static func stagger_entrance(controls: Array, delay_per: float = 0.06, slide_from: Vector2 = Vector2(-30, 0)) -> void:
	for i in controls.size():
		var c: Control = controls[i]
		c.modulate.a = 0.0
		var tween := c.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(delay_per * i)
		tween.tween_property(c, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
		if slide_from != Vector2.ZERO and not (c.get_parent() is Container):
			var target_pos := c.position
			c.position = target_pos + slide_from
			tween.parallel().tween_property(c, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Animate a control out before navigating away.
static func exit_animation(control: Control, direction: Vector2 = Vector2(30, 0), duration: float = 0.2, on_complete: Callable = Callable()) -> Tween:
	var tween := control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_property(control, "position", control.position + direction, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if on_complete.is_valid():
		tween.chain().tween_callback(on_complete)
	return tween


## Wire hover/press/focus sounds to a button via AudioManager variant pools.
static func wire_button_sounds(button: Button, navigate_sfx: StringName = &"ui_click", press_sfx: StringName = &"ui_confirm") -> void:
	button.mouse_entered.connect(func() -> void:
		AudioManager.play_sfx_variant(navigate_sfx, Constants.SFX_VOL_UI_CLICK)
	)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx_variant(press_sfx, Constants.SFX_VOL_UI_CONFIRM)
	)
	button.focus_entered.connect(func() -> void:
		AudioManager.play_sfx_variant(navigate_sfx, Constants.SFX_VOL_UI_CLICK)
	)


## Wire sounds to all Button children of a container.
static func wire_all_button_sounds(container: Control, navigate_sfx: StringName = &"ui_click", press_sfx: StringName = &"ui_confirm") -> void:
	for child in container.get_children():
		if child is Button:
			wire_button_sounds(child, navigate_sfx, press_sfx)
		if child is Control and child.get_child_count() > 0:
			wire_all_button_sounds(child, navigate_sfx, press_sfx)


## Scale-bounce feedback on button press (non-destructive).
static func add_press_feedback(button: Button, scale_amount: float = 0.95) -> void:
	button.button_down.connect(func() -> void:
		var tween := button.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(button, "scale", Vector2.ONE * scale_amount, 0.05).set_trans(Tween.TRANS_QUAD)
	)
	button.button_up.connect(func() -> void:
		var tween := button.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


static func _tween_focus_state(control: Control, _accent: Color, scale_amount: float, modulate_color: Color) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE * scale_amount, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "self_modulate", modulate_color, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
