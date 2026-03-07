extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: godot --headless --path . -s res://scripts/tools/capture_character_model_preview.gd -- <character_def> <anim_name> <output_path>")
		quit(1)
		return

	var def_path := args[0]
	var anim_name := StringName(args[1])
	var output_path := args[2]

	var def := load(def_path)
	if def == null:
		push_error("failed_to_load_character_def: %s" % def_path)
		quit(1)
		return

	var viewport := SubViewport.new()
	viewport.size = Vector2i(768, 768)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var world := Node3D.new()
	viewport.add_child(world)

	var camera := Camera3D.new()
	camera.look_at_from_position(Vector3(0.0, 1.25, 3.25), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	world.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -30.0, 0.0)
	world.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(1.75, 2.0, 1.5)
	fill.light_energy = 1.4
	world.add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.5, 1.5, -1.25)
	rim.light_energy = 0.8
	world.add_child(rim)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(4.0, 4.0)
	ground.mesh = ground_mesh
	ground.rotation_degrees.x = -90.0
	ground.position.y = 0.0
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.16, 0.16, 0.18, 1.0)
	ground.material_override = ground_mat
	world.add_child(ground)

	var model := CharacterModel.new()
	model.setup(def)
	world.add_child(model)

	await process_frame
	await process_frame
	model.play_animation(anim_name)
	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	if image == null:
		push_error("failed_to_capture_image")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var result := image.save_png(ProjectSettings.globalize_path(output_path))
	print("save_result: ", result)
	print("output_path: ", ProjectSettings.globalize_path(output_path))
	quit(0 if result == OK else 1)
