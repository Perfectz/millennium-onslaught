## Manages a 3D character model loaded from FBX files.
## Loads base mesh from FBX, imports skeletal animations from separate FBX files,
## and handles material flash/restore for combat feedback.
class_name CharacterModel
extends Node3D


## The loaded model root node.
var _model_root: Node3D = null

## The animation player controlling skeletal animations.
var anim_player: AnimationPlayer = null

## The primary mesh instance for material overrides.
var _mesh_instance: MeshInstance3D = null

## All mesh instances (for flash/restore on multi-mesh models).
var _all_meshes: Array[MeshInstance3D] = []

## Original materials saved per surface per mesh.
var _original_materials: Array[Material] = []

## Currently playing animation name.
var _current_animation: StringName = &""


func _ready() -> void:
	_load_base_model()
	_apply_skin()
	_load_all_animations()


## Load the base FBX model which contains the mesh + skeleton.
func _load_base_model() -> void:
	var scene := load(Constants.PLAYER_MODEL_BASE_PATH) as PackedScene
	if scene == null:
		push_warning("CharacterModel: Failed to load model: " + Constants.PLAYER_MODEL_BASE_PATH)
		_create_fallback_mesh()
		return

	_model_root = scene.instantiate() as Node3D
	_model_root.scale = Constants.PLAYER_MODEL_SCALE
	_model_root.position = Constants.PLAYER_MODEL_OFFSET
	_model_root.rotation_degrees = Vector3(0.0, Constants.PLAYER_MODEL_ROTATION_Y, 0.0)
	add_child(_model_root)

	_mesh_instance = _find_mesh_instance(_model_root)
	_collect_all_meshes(_model_root)
	_save_original_materials()

	# Measure skeleton to find actual model height and auto-scale to match capsule.
	var skeleton := _find_skeleton(_model_root)
	if skeleton:
		var max_y := 0.0
		var min_y := 0.0
		for i in range(skeleton.get_bone_count()):
			var bone_pos := skeleton.get_bone_global_rest(i).origin
			max_y = maxf(max_y, bone_pos.y)
			min_y = minf(min_y, bone_pos.y)
		var skeleton_height := max_y - min_y
		if skeleton_height > 0.001:
			var target_height := 1.8
			var auto_scale := target_height / skeleton_height
			_model_root.scale = Vector3(auto_scale, auto_scale, auto_scale)
			# Offset so feet are at local Y=0 (ModelPivot is at y=0.9, so offset down by 0.9).
			_model_root.position.y = -0.9 + (-min_y * auto_scale)

	anim_player = _find_animation_player(_model_root)


## Apply the skin texture to the model mesh.
func _apply_skin() -> void:
	if _mesh_instance == null or Constants.PLAYER_MODEL_SKIN_PATH == "":
		return
	var tex := load(Constants.PLAYER_MODEL_SKIN_PATH) as Texture2D
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mesh_instance.set_surface_override_material(0, mat)
	# Update saved originals so restore() uses the textured material.
	_original_materials.clear()
	_save_original_materials()


## Load all animations defined in Constants.PLAYER_MODEL_ANIMATIONS from FBX files.
func _load_all_animations() -> void:
	if anim_player == null:
		return
	for anim_name: String in Constants.PLAYER_MODEL_ANIMATIONS:
		var fbx_path: String = Constants.PLAYER_MODEL_ANIMATIONS[anim_name]
		_import_animation_from_fbx(anim_name, fbx_path)


## Import a single animation from an FBX file and add it under the given name.
func _import_animation_from_fbx(anim_name: String, fbx_path: String) -> void:
	var scene := load(fbx_path) as PackedScene
	if scene == null:
		push_warning("CharacterModel: Failed to load animation: " + fbx_path)
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


## Remove position tracks from the root/hip bone to prevent animation root motion.
## Mixamo FBX animations bake movement into the hip bone, causing the mesh to
## teleport when looping since actual movement is driven by CharacterBody3D velocity.
func _strip_root_motion(anim: Animation) -> void:
	for i in range(anim.get_track_count() - 1, -1, -1):
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		var path := str(anim.track_get_path(i))
		# Strip position tracks on root/hip bone (Mixamo naming convention).
		if "Hips" in path or "Root" in path:
			anim.remove_track(i)


## Add an animation to the default animation library.
func _add_animation(anim_name: String, anim: Animation) -> void:
	if anim_player == null:
		return
	if not anim_player.has_animation_library(""):
		anim_player.add_animation_library("", AnimationLibrary.new())
	var lib := anim_player.get_animation_library("")
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)


## Play a named animation. Loop mode set automatically: idle/run loop, others play once.
## speed_scale multiplies playback speed (1.0 = normal).
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
		if anim_name == &"idle" or anim_name == &"run":
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
	anim_player.speed_scale = speed_scale
	# Cross-fade between looping animations (idle↔run) for smooth transitions.
	var blend := 0.15 if (anim_name == &"idle" or anim_name == &"run") else -1.0
	anim_player.play(full_name, blend)
	_current_animation = anim_name


## Get the duration of a named animation in seconds.
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


## Stop all animation playback.
func stop_animation() -> void:
	if anim_player:
		anim_player.stop()
	_current_animation = &""


## Flash all model meshes a solid color for combat feedback.
func flash(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	for mesh in _all_meshes:
		for i in range(mesh.get_surface_override_material_count()):
			mesh.set_surface_override_material(i, mat)


## Restore the original materials after flashing.
func restore() -> void:
	var idx := 0
	for mesh in _all_meshes:
		for i in range(mesh.get_surface_override_material_count()):
			if idx < _original_materials.size():
				mesh.set_surface_override_material(i, _original_materials[idx])
			idx += 1


## Get the primary mesh instance.
func get_mesh() -> MeshInstance3D:
	return _mesh_instance


## Resolve an animation name to its full library path.
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


## Create a fallback capsule mesh if model loading fails.
func _create_fallback_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FallbackMesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh_instance.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.9, 1.0)
	mesh_instance.set_surface_override_material(0, mat)
	_original_materials.append(mat)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance
	_all_meshes.append(mesh_instance)


## Collect all MeshInstance3D nodes in the tree.
func _collect_all_meshes(root: Node) -> void:
	if root is MeshInstance3D:
		_all_meshes.append(root as MeshInstance3D)
	for child in root.get_children():
		_collect_all_meshes(child)


## Save original materials for all collected meshes.
## Falls back to mesh surface material if no override exists, assigns a default
## material to prevent null material errors in the renderer.
func _save_original_materials() -> void:
	for mesh in _all_meshes:
		for i in range(mesh.get_surface_override_material_count()):
			var mat := mesh.get_surface_override_material(i)
			if mat == null and mesh.mesh:
				mat = mesh.mesh.surface_get_material(i)
			if mat == null:
				mat = StandardMaterial3D.new()
				mesh.set_surface_override_material(i, mat)
			_original_materials.append(mat)


## Find first MeshInstance3D in node tree recursively.
func _find_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found
	return null


## Find first AnimationPlayer in node tree recursively.
func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


## Find first Skeleton3D in node tree recursively.
func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null
