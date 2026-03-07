extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: godot --headless --path . -s res://scripts/tools/inspect_scene_structure.gd -- <scene_path>")
		quit(1)
		return

	var scene_path := args[0]
	print("scene_path: ", scene_path)

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("failed_to_load: %s" % scene_path)
		quit(1)
		return

	var root := packed.instantiate()
	_dump_node(root, 0)
	root.queue_free()
	quit()


func _dump_node(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	var line := "%s- %s (%s)" % [indent, node.name, node.get_class()]

	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		line += " bones=%d" % skeleton.get_bone_count()
		print(line)
		for bone_idx in range(skeleton.get_bone_count()):
			var parent_idx := skeleton.get_bone_parent(bone_idx)
			var parent_name := "<root>"
			if parent_idx != -1:
				parent_name = skeleton.get_bone_name(parent_idx)
			print("%s  bone[%d]: %s parent=%s" % [indent, bone_idx, skeleton.get_bone_name(bone_idx), parent_name])
	elif node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var surface_count := 0
		if mesh_instance.mesh != null:
			surface_count = mesh_instance.mesh.get_surface_count()
		line += " skin=%s mesh=%s surfaces=%d" % [
			str(mesh_instance.skin != null),
			str(mesh_instance.mesh != null),
			surface_count,
		]
		print(line)
	elif node is AnimationPlayer:
		var player := node as AnimationPlayer
		line += " libraries=%d root_node=%s" % [player.get_animation_library_list().size(), str(player.root_node)]
		print(line)
		for lib_name in player.get_animation_library_list():
			var lib := player.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				var anim := lib.get_animation(anim_name)
				print("%s  anim[%s]: length=%s tracks=%d" % [indent, anim_name, str(anim.length), anim.get_track_count()])
	else:
		print(line)

	for child in node.get_children():
		_dump_node(child, depth + 1)
