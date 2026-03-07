extends SceneTree


const TARGET_BASE_PATH := "res://assets/models/characters/alys/alys_base.glb"
const TARGET_ANIM_PATH := "res://assets/models/characters/alys/idle.fbx"
const SOURCE_IDLE_PATH := "res://assets/models/characters/alys/unarmed_fighting_v1/A_UnarmedFightingAnimationsV1_Idle_1.fbx"
const SOURCE_ATTACK_PATH := "res://assets/models/characters/alys/unarmed_fighting_v1/A_UnarmedFightingAnimationsV1_1_IP.fbx"


func _initialize() -> void:
	_inspect_scene("target_base", TARGET_BASE_PATH)
	_inspect_scene("target_anim", TARGET_ANIM_PATH)
	_inspect_scene("source_idle", SOURCE_IDLE_PATH)
	_inspect_scene("source_attack", SOURCE_ATTACK_PATH)
	quit()


func _inspect_scene(label: String, path: String) -> void:
	print("--- ", label, " ---")
	print("path: ", path)
	var scene := load(path) as PackedScene
	if scene == null:
		print("failed_to_load")
		return

	var root := scene.instantiate()
	var skeleton := _find_skeleton(root)
	if skeleton == null:
		print("skeleton: none")
	else:
		print("skeleton: ", skeleton.name, " bones=", skeleton.get_bone_count())
		for i in range(mini(skeleton.get_bone_count(), 20)):
			print("bone[", i, "]: ", skeleton.get_bone_name(i))

	var player := _find_animation_player(root)
	if player == null:
		print("animation_player: none")
		root.queue_free()
		return

	print("animation_player: ", player.name)
	for lib_name in player.get_animation_library_list():
		var lib := player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var anim := lib.get_animation(anim_name)
			print("animation: ", anim_name, " length=", anim.length, " tracks=", anim.get_track_count())
			for track_idx in range(mini(anim.get_track_count(), 20)):
				print("track[", track_idx, "]: ", anim.track_get_path(track_idx), " type=", anim.track_get_type(track_idx))
			root.queue_free()
			return

	root.queue_free()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var skeleton := _find_skeleton(child)
		if skeleton != null:
			return skeleton
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var player := _find_animation_player(child)
		if player != null:
			return player
	return null
