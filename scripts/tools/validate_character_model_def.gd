extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: godot --headless --path . -s res://scripts/tools/validate_character_model_def.gd -- <character_def>")
		quit(1)
		return

	var def_path := args[0]
	var def := load(def_path)
	if def == null:
		push_error("failed_to_load_character_def: %s" % def_path)
		quit(1)
		return

	var model := CharacterModel.new()
	model.setup(def)
	root.add_child(model)

	await process_frame
	await process_frame

	var mesh := model.get_mesh()
	print("mesh_loaded: ", mesh != null)
	print("anim_player_loaded: ", model.anim_player != null)
	print("idle_duration: ", model.get_animation_duration(&"idle"))
	print("run_duration: ", model.get_animation_duration(&"run"))
	print("attack_light_1_duration: ", model.get_animation_duration(&"attack_light_1"))

	if mesh == null or model.anim_player == null:
		quit(1)
		return

	if mesh.mesh != null:
		print("mesh_surface_count: ", mesh.mesh.get_surface_count())
	for surface_idx in range(mesh.get_surface_override_material_count()):
		var override_mat := mesh.get_surface_override_material(surface_idx)
		print("override_material_%d: %s" % [surface_idx, override_mat])
		if override_mat is StandardMaterial3D:
			var std_mat := override_mat as StandardMaterial3D
			print("override_material_%d_albedo_texture: %s" % [surface_idx, std_mat.albedo_texture])
			print("override_material_%d_vertex_color_use_as_albedo: %s" % [surface_idx, std_mat.vertex_color_use_as_albedo])
			print("override_material_%d_transparency: %d" % [surface_idx, std_mat.transparency])

	model.play_animation(&"idle")
	await process_frame
	print("current_animation: ", model.anim_player.current_animation)
	quit(0)
