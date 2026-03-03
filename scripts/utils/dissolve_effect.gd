## Helper to apply the dissolve shader to any MeshInstance3D and animate it.
## Usage: DissolveEffect.dissolve(mesh_instance, 1.0, callback)
class_name DissolveEffect
extends RefCounted


## Apply dissolve shader to a mesh and animate it from 0 → 1 over duration.
static func dissolve(mesh: MeshInstance3D, duration: float = 1.0, on_complete: Callable = Callable()) -> Tween:
	if mesh == null or not is_instance_valid(mesh):
		return null

	var material := _prepare_material(mesh)
	if material == null:
		return null

	material.set_shader_parameter("dissolve_amount", 0.0)

	var tween := mesh.create_tween()
	tween.tween_method(func(v: float) -> void:
		if is_instance_valid(mesh) and material != null:
			material.set_shader_parameter("dissolve_amount", v)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if on_complete.is_valid():
		tween.tween_callback(on_complete)

	return tween


## Reverse dissolve (materialize effect): animate from 1 → 0.
static func materialize(mesh: MeshInstance3D, duration: float = 1.0, on_complete: Callable = Callable()) -> Tween:
	if mesh == null or not is_instance_valid(mesh):
		return null

	var material := _prepare_material(mesh)
	if material == null:
		return null

	material.set_shader_parameter("dissolve_amount", 1.0)

	var tween := mesh.create_tween()
	tween.tween_method(func(v: float) -> void:
		if is_instance_valid(mesh) and material != null:
			material.set_shader_parameter("dissolve_amount", v)
	, 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if on_complete.is_valid():
		tween.tween_callback(on_complete)

	return tween


## Prepare the dissolve shader material on a mesh, preserving albedo texture.
static func _prepare_material(mesh: MeshInstance3D) -> ShaderMaterial:
	var shader := load("res://assets/shaders/dissolve.gdshader") as Shader
	if shader == null:
		push_error("DissolveEffect: dissolve.gdshader not found")
		return null

	var mat := ShaderMaterial.new()
	mat.shader = shader

	# Try to grab the albedo texture from the existing material.
	var existing_mat: Material = null
	if mesh.get_surface_override_material_count() > 0:
		existing_mat = mesh.get_surface_override_material(0)
	if existing_mat == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
		existing_mat = mesh.mesh.surface_get_material(0)

	if existing_mat is StandardMaterial3D:
		var std := existing_mat as StandardMaterial3D
		if std.albedo_texture:
			mat.set_shader_parameter("albedo_texture", std.albedo_texture)
		mat.set_shader_parameter("albedo_color", std.albedo_color)

	# Generate a simple noise texture for dissolve pattern.
	var noise_tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 256
	mat.set_shader_parameter("dissolve_noise", noise_tex)

	mesh.set_surface_override_material(0, mat)
	return mat
