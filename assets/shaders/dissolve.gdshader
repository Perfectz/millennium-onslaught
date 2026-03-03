shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D dissolve_noise : filter_linear_mipmap;
uniform float dissolve_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.04;
uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform vec4 edge_color_2 : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float edge_emission : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec4 tex = texture(albedo_texture, UV) * albedo_color;
	float noise_val = texture(dissolve_noise, UV).r;

	// Dissolve threshold
	float threshold = dissolve_amount;
	if (noise_val < threshold) {
		discard;
	}

	// Edge glow
	float edge = smoothstep(threshold, threshold + edge_width, noise_val);
	vec3 glow = mix(edge_color.rgb, edge_color_2.rgb, edge) * edge_emission;
	vec3 final_color = mix(tex.rgb + glow * (1.0 - edge), tex.rgb, edge);
	float final_emission = mix(edge_emission * (1.0 - edge), 0.0, edge);

	ALBEDO = final_color;
	EMISSION = glow * (1.0 - edge);
	ALPHA = tex.a;
}
