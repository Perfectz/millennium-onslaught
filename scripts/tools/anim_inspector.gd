## Temporary diagnostic: prints ALL bone names from UAL GLB to build mapping table.
extends SceneTree


func _init() -> void:
	print("=== UAL1 ALL BONES ===")
	_print_all_bones("res://assets/models/characters/alys/UAL1_Standard.glb")
	quit()


func _print_all_bones(path: String) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var err := gltf_doc.append_from_file(abs_path, gltf_state)
	if err != OK:
		print("Failed to load: ", err)
		return
	var root := gltf_doc.generate_scene(gltf_state)
	if root == null:
		return
	var skel := _find_skeleton(root)
	if skel:
		print("Bone count: ", skel.get_bone_count())
		for i in range(skel.get_bone_count()):
			print("  [%d] %s" % [i, skel.get_bone_name(i)])
	root.queue_free()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null
