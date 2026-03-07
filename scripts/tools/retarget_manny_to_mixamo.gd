extends SceneTree


const FPS := 30.0
const SOURCE_DIR := "res://assets/models/characters/alys/unarmed_fighting_v1"
const TARGET_SCENE_PATH := "res://assets/models/characters/alys/idle.fbx"
const OUTPUT_DIR := "res://assets/models/characters/alys/unarmed_fighting_v1_retargeted"

const CLIPS := [
	{"source": "A_UnarmedFightingAnimationsV1_Idle_1.fbx", "output": "idle.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_Hit_1.fbx", "output": "hurt.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_Dead_1.fbx", "output": "dead.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_1_IP.fbx", "output": "attack_1.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_2_IP.fbx", "output": "attack_2.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_3_IP.fbx", "output": "attack_3.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_4_IP.fbx", "output": "attack_4.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_5_IP.fbx", "output": "attack_5.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_6_IP.fbx", "output": "attack_6.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_7_IP.fbx", "output": "attack_7.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_8_IP.fbx", "output": "attack_8.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_9_IP.fbx", "output": "attack_9.tscn"},
	{"source": "A_UnarmedFightingAnimationsV1_10_IP.fbx", "output": "attack_10.tscn"},
]

const SOURCE_TO_TARGET_BONES := {
	"pelvis": "mixamorig_Hips",
	"spine_01": "mixamorig_Spine",
	"spine_03": "mixamorig_Spine1",
	"spine_05": "mixamorig_Spine2",
	"neck_02": "mixamorig_Neck",
	"head": "mixamorig_Head",
	"clavicle_l": "mixamorig_LeftShoulder",
	"upperarm_l": "mixamorig_LeftArm",
	"lowerarm_l": "mixamorig_LeftForeArm",
	"hand_l": "mixamorig_LeftHand",
	"thumb_01_l": "mixamorig_LeftHandThumb1",
	"thumb_02_l": "mixamorig_LeftHandThumb2",
	"thumb_03_l": "mixamorig_LeftHandThumb3",
	"index_metacarpal_l": "mixamorig_LeftHandIndex1",
	"index_01_l": "mixamorig_LeftHandIndex2",
	"index_02_l": "mixamorig_LeftHandIndex3",
	"index_03_l": "mixamorig_LeftHandIndex4",
	"middle_metacarpal_l": "mixamorig_LeftHandMiddle1",
	"middle_01_l": "mixamorig_LeftHandMiddle2",
	"middle_02_l": "mixamorig_LeftHandMiddle3",
	"middle_03_l": "mixamorig_LeftHandMiddle4",
	"ring_metacarpal_l": "mixamorig_LeftHandRing1",
	"ring_01_l": "mixamorig_LeftHandRing2",
	"ring_02_l": "mixamorig_LeftHandRing3",
	"ring_03_l": "mixamorig_LeftHandRing4",
	"pinky_metacarpal_l": "mixamorig_LeftHandPinky1",
	"pinky_01_l": "mixamorig_LeftHandPinky2",
	"pinky_02_l": "mixamorig_LeftHandPinky3",
	"pinky_03_l": "mixamorig_LeftHandPinky4",
	"clavicle_r": "mixamorig_RightShoulder",
	"upperarm_r": "mixamorig_RightArm",
	"lowerarm_r": "mixamorig_RightForeArm",
	"hand_r": "mixamorig_RightHand",
	"thumb_01_r": "mixamorig_RightHandThumb1",
	"thumb_02_r": "mixamorig_RightHandThumb2",
	"thumb_03_r": "mixamorig_RightHandThumb3",
	"index_metacarpal_r": "mixamorig_RightHandIndex1",
	"index_01_r": "mixamorig_RightHandIndex2",
	"index_02_r": "mixamorig_RightHandIndex3",
	"index_03_r": "mixamorig_RightHandIndex4",
	"middle_metacarpal_r": "mixamorig_RightHandMiddle1",
	"middle_01_r": "mixamorig_RightHandMiddle2",
	"middle_02_r": "mixamorig_RightHandMiddle3",
	"middle_03_r": "mixamorig_RightHandMiddle4",
	"ring_metacarpal_r": "mixamorig_RightHandRing1",
	"ring_01_r": "mixamorig_RightHandRing2",
	"ring_02_r": "mixamorig_RightHandRing3",
	"ring_03_r": "mixamorig_RightHandRing4",
	"pinky_metacarpal_r": "mixamorig_RightHandPinky1",
	"pinky_01_r": "mixamorig_RightHandPinky2",
	"pinky_02_r": "mixamorig_RightHandPinky3",
	"pinky_03_r": "mixamorig_RightHandPinky4",
	"thigh_l": "mixamorig_LeftUpLeg",
	"calf_l": "mixamorig_LeftLeg",
	"foot_l": "mixamorig_LeftFoot",
	"ball_l": "mixamorig_LeftToeBase",
	"thigh_r": "mixamorig_RightUpLeg",
	"calf_r": "mixamorig_RightLeg",
	"foot_r": "mixamorig_RightFoot",
	"ball_r": "mixamorig_RightToeBase",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_abs)

	for clip in CLIPS:
		var source_path := SOURCE_DIR.path_join(String(clip.source))
		var output_path := OUTPUT_DIR.path_join(String(clip.output))
		var ok := _retarget_clip(source_path, output_path)
		print("retarget ", source_path, " -> ", output_path, " ok=", ok)

	quit()


func _retarget_clip(source_path: String, output_path: String) -> bool:
	var source_scene := load(source_path) as PackedScene
	var target_scene := load(TARGET_SCENE_PATH) as PackedScene
	if source_scene == null or target_scene == null:
		return false

	var source_root := source_scene.instantiate()
	var target_root := target_scene.instantiate()
	root.add_child(source_root)
	root.add_child(target_root)

	var source_skeleton := _find_skeleton(source_root)
	var target_skeleton := _find_skeleton(target_root)
	var source_player := _find_animation_player(source_root)
	if source_skeleton == null or target_skeleton == null or source_player == null:
		_cleanup_nodes(source_root, target_root)
		return false

	var source_anim_name := _first_animation_name(source_player)
	if source_anim_name == &"":
		_cleanup_nodes(source_root, target_root)
		return false

	var source_anim := source_player.get_animation(source_anim_name)
	if source_anim == null:
		_cleanup_nodes(source_root, target_root)
		return false

	var target_player := _replace_animation_player(target_root)
	var mapped_pairs := _build_pairs(source_skeleton, target_skeleton)
	if mapped_pairs.is_empty():
		_cleanup_nodes(source_root, target_root)
		return false

	var retargeted := Animation.new()
	retargeted.length = source_anim.length

	for pair in mapped_pairs:
		if bool(pair["hip"]):
			pair["position_track"] = retargeted.add_track(Animation.TYPE_POSITION_3D)
			retargeted.track_set_path(int(pair["position_track"]), NodePath("Skeleton3D:%s" % String(pair["target_name"])))
		pair["rotation_track"] = retargeted.add_track(Animation.TYPE_ROTATION_3D)
		retargeted.track_set_path(int(pair["rotation_track"]), NodePath("Skeleton3D:%s" % String(pair["target_name"])))

	source_player.play(source_anim_name)
	source_player.advance(0.0)

	var frame_count := int(ceil(source_anim.length * FPS))
	for frame in range(frame_count + 1):
		var time := minf(frame / FPS, source_anim.length)
		source_player.seek(time, true)
		source_player.advance(0.0)
		source_skeleton.force_update_all_bone_transforms()

		var target_globals := {}
		for pair in mapped_pairs:
			var source_global_rest := source_skeleton.get_bone_global_rest(int(pair["source_index"]))
			var source_global_pose := source_skeleton.get_bone_global_pose(int(pair["source_index"]))
			var delta_global := source_global_rest.affine_inverse() * source_global_pose
			var target_global_pose := target_skeleton.get_bone_global_rest(int(pair["target_index"])) * delta_global

			var parent_global := Transform3D.IDENTITY
			var target_parent := int(pair["target_parent"])
			if target_parent != -1:
				if target_globals.has(target_parent):
					parent_global = target_globals[target_parent]
				else:
					parent_global = target_skeleton.get_bone_global_rest(target_parent)
			var local_target_pose := parent_global.affine_inverse() * target_global_pose
			target_globals[int(pair["target_index"])] = target_global_pose

			if int(pair["position_track"]) != -1:
				retargeted.position_track_insert_key(int(pair["position_track"]), time, local_target_pose.origin)
			retargeted.rotation_track_insert_key(int(pair["rotation_track"]), time, local_target_pose.basis.get_rotation_quaternion())

	target_player.add_animation_library("", AnimationLibrary.new())
	target_player.get_animation_library("").add_animation(output_path.get_file().get_basename(), retargeted)

	var packed := PackedScene.new()
	var packed_ok := packed.pack(target_root) == OK
	if packed_ok:
		packed_ok = ResourceSaver.save(packed, output_path) == OK

	_cleanup_nodes(source_root, target_root)
	return packed_ok


func _build_pairs(source_skeleton: Skeleton3D, target_skeleton: Skeleton3D) -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	for source_name in SOURCE_TO_TARGET_BONES.keys():
		var target_name := String(SOURCE_TO_TARGET_BONES[source_name])
		var source_index := source_skeleton.find_bone(source_name)
		var target_index := target_skeleton.find_bone(target_name)
		if source_index == -1 or target_index == -1:
			continue
		var target_parent := target_skeleton.get_bone_parent(target_index)
		pairs.append({
			"source_index": source_index,
			"source_name": source_name,
			"target_index": target_index,
			"target_name": target_name,
			"target_parent": target_parent,
			"depth": _bone_depth(target_skeleton, target_index),
			"hip": target_name == "mixamorig_Hips",
			"position_track": -1,
			"rotation_track": -1,
		})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.depth) == int(b.depth):
			return int(a.target_index) < int(b.target_index)
		return int(a.depth) < int(b.depth)
	)
	return pairs


func _bone_depth(skeleton: Skeleton3D, bone_index: int) -> int:
	var depth := 0
	var current := skeleton.get_bone_parent(bone_index)
	while current != -1:
		depth += 1
		current = skeleton.get_bone_parent(current)
	return depth


func _replace_animation_player(root_node: Node) -> AnimationPlayer:
	var existing := _find_animation_player(root_node)
	if existing != null:
		var parent := existing.get_parent()
		parent.remove_child(existing)
		existing.free()
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root_node.add_child(player)
	player.owner = root_node
	return player


func _first_animation_name(player: AnimationPlayer) -> StringName:
	for library_name in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		for anim_name in library.get_animation_list():
			return anim_name
	return &""


func _cleanup_nodes(source_root: Node, target_root: Node) -> void:
	if source_root != null and source_root.get_parent() != null:
		source_root.get_parent().remove_child(source_root)
	source_root.queue_free()
	if target_root != null and target_root.get_parent() != null:
		target_root.get_parent().remove_child(target_root)
	target_root.queue_free()


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
