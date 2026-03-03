## Loads and manages the base visual model for enemies.
## Handles flash/restore material overrides and skeletal animations.
class_name EnemyModel
extends Node3D


var _model_root: Node3D = null
var _all_meshes: Array[MeshInstance3D] = []
var _original_materials: Array[Material] = []
var anim_player: AnimationPlayer = null
var _current_animation: StringName = &""


func _ready() -> void:
	_load_model()
	_apply_albedo_texture()
	_save_original_materials()
	_load_all_animations()


func play_animation(anim_name: StringName, speed_scale: float = 1.0) -> void:
	if anim_player == null:
		return
	if anim_name == _current_animation and anim_player.is_playing():
		return

	var full_name := _resolve_animation_name(anim_name)
	if full_name == &"":
		return

	var anim := anim_player.get_animation(full_name)
	if anim:
		if anim_name == &"idle" or anim_name == &"run" or anim_name == &"walk":
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
	anim_player.speed_scale = speed_scale
	var blend := 0.15 if (anim_name == &"idle" or anim_name == &"run" or anim_name == &"walk") else -1.0
	anim_player.play(full_name, blend)
	_current_animation = anim_name


func get_animation_duration(anim_name: StringName) -> float:
	if anim_player == null:
		return 0.0
	var full_name := _resolve_animation_name(anim_name)
	if full_name == &"":
		return 0.0
	var anim := anim_player.get_animation(full_name)
	if anim:
		return anim.length
	return 0.0


func stop_animation() -> void:
	if anim_player:
		anim_player.stop()
	_current_animation = &""


func flash(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5

	for mesh in _all_meshes:
		for i in _get_surface_count(mesh):
			mesh.set_surface_override_material(i, mat)


func restore() -> void:
	var idx := 0
	for mesh in _all_meshes:
		for i in _get_surface_count(mesh):
			if idx < _original_materials.size():
				mesh.set_surface_override_material(i, _original_materials[idx])
			idx += 1


func _load_model() -> void:
	var packed := load(Constants.ENEMY_MODEL_BASE_PATH) as PackedScene
	if packed == null:
		push_warning("EnemyModel: Failed to load model: " + Constants.ENEMY_MODEL_BASE_PATH)
		_create_fallback_mesh()
		return

	_model_root = packed.instantiate() as Node3D
	_model_root.position = Constants.ENEMY_MODEL_OFFSET
	_model_root.rotation_degrees = Vector3(0.0, Constants.ENEMY_MODEL_ROTATION_Y, 0.0)
	_model_root.scale = Constants.ENEMY_MODEL_SCALE
	add_child(_model_root)

	_collect_all_meshes(_model_root)
	_auto_scale_and_ground()
	anim_player = _find_animation_player(_model_root)


func _apply_albedo_texture() -> void:
	if Constants.ENEMY_MODEL_SKIN_PATH == "":
		return

	var tex := load(Constants.ENEMY_MODEL_SKIN_PATH) as Texture2D
	if tex == null:
		return

	for mesh in _all_meshes:
		for i in _get_surface_count(mesh):
			var src_mat := mesh.get_surface_override_material(i)
			if src_mat == null and mesh.mesh:
				src_mat = mesh.mesh.surface_get_material(i)

			var std_mat: StandardMaterial3D
			if src_mat is StandardMaterial3D:
				std_mat = (src_mat as StandardMaterial3D).duplicate()
			else:
				std_mat = StandardMaterial3D.new()
			std_mat.albedo_texture = tex
			std_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mesh.set_surface_override_material(i, std_mat)


func _load_all_animations() -> void:
	if anim_player == null:
		return
	for anim_name: String in Constants.ENEMY_MODEL_ANIMATIONS:
		var fbx_path: String = Constants.ENEMY_MODEL_ANIMATIONS[anim_name]
		_import_animation_from_fbx(anim_name, fbx_path)


func _import_animation_from_fbx(anim_name: String, fbx_path: String) -> void:
	var scene := load(fbx_path) as PackedScene
	if scene == null:
		push_warning("EnemyModel: Failed to load animation: " + fbx_path)
		return

	var temp := scene.instantiate()
	var temp_player := _find_animation_player(temp)

	if temp_player:
		for lib_name in temp_player.get_animation_library_list():
			var lib := temp_player.get_animation_library(lib_name)
			for existing_name in lib.get_animation_list():
				var anim := lib.get_animation(existing_name).duplicate()
				_strip_root_motion(anim)
				_add_animation(anim_name, anim)
				break
			break

	temp.queue_free()


func _strip_root_motion(anim: Animation) -> void:
	for i in range(anim.get_track_count() - 1, -1, -1):
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		var path := str(anim.track_get_path(i))
		if "Hips" in path or "Root" in path:
			anim.remove_track(i)


func _add_animation(anim_name: String, anim: Animation) -> void:
	if anim_player == null:
		return
	if not anim_player.has_animation_library(""):
		anim_player.add_animation_library("", AnimationLibrary.new())
	var lib := anim_player.get_animation_library("")
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)


func _resolve_animation_name(anim_name: StringName) -> StringName:
	if anim_player.has_animation(anim_name):
		return anim_name
	for lib_name in anim_player.get_animation_library_list():
		var lib := anim_player.get_animation_library(lib_name)
		if lib.has_animation(anim_name):
			if lib_name == "":
				return anim_name
			return StringName(lib_name + "/" + str(anim_name))
	return &""


func _auto_scale_and_ground() -> void:
	var skeleton := _find_skeleton(_model_root)
	if skeleton == null:
		return

	var max_y := 0.0
	var min_y := 0.0
	for i in skeleton.get_bone_count():
		var bone_pos := skeleton.get_bone_global_rest(i).origin
		max_y = maxf(max_y, bone_pos.y)
		min_y = minf(min_y, bone_pos.y)

	var skeleton_height := max_y - min_y
	if skeleton_height <= 0.001:
		return

	# Enemy collision capsule is 1.6 units tall with ModelPivot at y=0.8.
	var target_height := 1.6
	var auto_scale := target_height / skeleton_height
	_model_root.scale *= auto_scale
	_model_root.position.y = Constants.ENEMY_MODEL_OFFSET.y + (-0.8 + (-min_y * _model_root.scale.y))


func _save_original_materials() -> void:
	_original_materials.clear()

	for mesh in _all_meshes:
		for i in _get_surface_count(mesh):
			var mat := mesh.get_surface_override_material(i)
			if mat == null and mesh.mesh:
				mat = mesh.mesh.surface_get_material(i)
			if mat == null:
				mat = StandardMaterial3D.new()
				mesh.set_surface_override_material(i, mat)
			_original_materials.append(mat)


func _create_fallback_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FallbackEnemyMesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	mesh_instance.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.2, 1.0)
	mesh_instance.set_surface_override_material(0, mat)
	add_child(mesh_instance)
	_all_meshes.append(mesh_instance)


func _collect_all_meshes(root: Node) -> void:
	if root is MeshInstance3D:
		_all_meshes.append(root as MeshInstance3D)
	for child in root.get_children():
		_collect_all_meshes(child)


func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _get_surface_count(mesh: MeshInstance3D) -> int:
	if mesh.mesh:
		return mesh.mesh.get_surface_count()
	return mesh.get_surface_override_material_count()
