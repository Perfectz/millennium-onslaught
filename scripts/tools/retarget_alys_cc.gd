extends SceneTree


const FPS := 30.0
const TARGET_SCENE_PATH := "res://assets/models/characters/alys_cc/base/alys Rigged with texture.fbx"

const MANNY_TO_CC_MAP := [
	{"source": "pelvis", "position": "CC_Base_Hip", "rotation": "CC_Base_Pelvis"},
	{"source": "spine_01", "rotation": "CC_Base_Waist"},
	{"source": "spine_03", "rotation": "CC_Base_Spine01"},
	{"source": "spine_05", "rotation": "CC_Base_Spine02"},
	{"source": "neck_01", "rotation": "CC_Base_NeckTwist01"},
	{"source": "neck_02", "rotation": "CC_Base_NeckTwist02"},
	{"source": "head", "rotation": "CC_Base_Head"},
	{"source": "clavicle_l", "rotation": "CC_Base_L_Clavicle"},
	{"source": "upperarm_l", "rotation": "CC_Base_L_Upperarm"},
	{"source": "upperarm_twist_01_l", "rotation": "CC_Base_L_UpperarmTwist01"},
	{"source": "upperarm_twist_02_l", "rotation": "CC_Base_L_UpperarmTwist02"},
	{"source": "lowerarm_l", "rotation": "CC_Base_L_Forearm"},
	{"source": "lowerarm_twist_01_l", "rotation": "CC_Base_L_ForearmTwist01"},
	{"source": "lowerarm_twist_02_l", "rotation": "CC_Base_L_ForearmTwist02"},
	{"source": "hand_l", "rotation": "CC_Base_L_Hand"},
	{"source": "thumb_01_l", "rotation": "CC_Base_L_Thumb1"},
	{"source": "thumb_02_l", "rotation": "CC_Base_L_Thumb2"},
	{"source": "thumb_03_l", "rotation": "CC_Base_L_Thumb3"},
	{"source": "index_metacarpal_l", "rotation": "CC_Base_L_Index1"},
	{"source": "index_01_l", "rotation": "CC_Base_L_Index2"},
	{"source": "index_02_l", "rotation": "CC_Base_L_Index3"},
	{"source": "middle_metacarpal_l", "rotation": "CC_Base_L_Mid1"},
	{"source": "middle_01_l", "rotation": "CC_Base_L_Mid2"},
	{"source": "middle_02_l", "rotation": "CC_Base_L_Mid3"},
	{"source": "ring_metacarpal_l", "rotation": "CC_Base_L_Ring1"},
	{"source": "ring_01_l", "rotation": "CC_Base_L_Ring2"},
	{"source": "ring_02_l", "rotation": "CC_Base_L_Ring3"},
	{"source": "pinky_metacarpal_l", "rotation": "CC_Base_L_Pinky1"},
	{"source": "pinky_01_l", "rotation": "CC_Base_L_Pinky2"},
	{"source": "pinky_02_l", "rotation": "CC_Base_L_Pinky3"},
	{"source": "clavicle_r", "rotation": "CC_Base_R_Clavicle"},
	{"source": "upperarm_r", "rotation": "CC_Base_R_Upperarm"},
	{"source": "upperarm_twist_01_r", "rotation": "CC_Base_R_UpperarmTwist01"},
	{"source": "upperarm_twist_02_r", "rotation": "CC_Base_R_UpperarmTwist02"},
	{"source": "lowerarm_r", "rotation": "CC_Base_R_Forearm"},
	{"source": "lowerarm_twist_01_r", "rotation": "CC_Base_R_ForearmTwist01"},
	{"source": "lowerarm_twist_02_r", "rotation": "CC_Base_R_ForearmTwist02"},
	{"source": "hand_r", "rotation": "CC_Base_R_Hand"},
	{"source": "thumb_01_r", "rotation": "CC_Base_R_Thumb1"},
	{"source": "thumb_02_r", "rotation": "CC_Base_R_Thumb2"},
	{"source": "thumb_03_r", "rotation": "CC_Base_R_Thumb3"},
	{"source": "index_metacarpal_r", "rotation": "CC_Base_R_Index1"},
	{"source": "index_01_r", "rotation": "CC_Base_R_Index2"},
	{"source": "index_02_r", "rotation": "CC_Base_R_Index3"},
	{"source": "middle_metacarpal_r", "rotation": "CC_Base_R_Mid1"},
	{"source": "middle_01_r", "rotation": "CC_Base_R_Mid2"},
	{"source": "middle_02_r", "rotation": "CC_Base_R_Mid3"},
	{"source": "ring_metacarpal_r", "rotation": "CC_Base_R_Ring1"},
	{"source": "ring_01_r", "rotation": "CC_Base_R_Ring2"},
	{"source": "ring_02_r", "rotation": "CC_Base_R_Ring3"},
	{"source": "pinky_metacarpal_r", "rotation": "CC_Base_R_Pinky1"},
	{"source": "pinky_01_r", "rotation": "CC_Base_R_Pinky2"},
	{"source": "pinky_02_r", "rotation": "CC_Base_R_Pinky3"},
	{"source": "thigh_l", "rotation": "CC_Base_L_Thigh"},
	{"source": "thigh_twist_01_l", "rotation": "CC_Base_L_ThighTwist01"},
	{"source": "thigh_twist_02_l", "rotation": "CC_Base_L_ThighTwist02"},
	{"source": "calf_l", "rotation": "CC_Base_L_Calf"},
	{"source": "calf_twist_01_l", "rotation": "CC_Base_L_CalfTwist01"},
	{"source": "calf_twist_02_l", "rotation": "CC_Base_L_CalfTwist02"},
	{"source": "foot_l", "rotation": "CC_Base_L_Foot"},
	{"source": "ball_l", "rotation": "CC_Base_L_ToeBase"},
	{"source": "thigh_r", "rotation": "CC_Base_R_Thigh"},
	{"source": "thigh_twist_01_r", "rotation": "CC_Base_R_ThighTwist01"},
	{"source": "thigh_twist_02_r", "rotation": "CC_Base_R_ThighTwist02"},
	{"source": "calf_r", "rotation": "CC_Base_R_Calf"},
	{"source": "calf_twist_01_r", "rotation": "CC_Base_R_CalfTwist01"},
	{"source": "calf_twist_02_r", "rotation": "CC_Base_R_CalfTwist02"},
	{"source": "foot_r", "rotation": "CC_Base_R_Foot"},
	{"source": "ball_r", "rotation": "CC_Base_R_ToeBase"},
]

const MIXAMO_TO_CC_MAP := [
	{"source": "mixamorig_Hips", "position": "CC_Base_Hip", "rotation": "CC_Base_Pelvis"},
	{"source": "mixamorig_Spine", "rotation": "CC_Base_Waist"},
	{"source": "mixamorig_Spine1", "rotation": "CC_Base_Spine01"},
	{"source": "mixamorig_Spine2", "rotation": "CC_Base_Spine02"},
	{"source": "mixamorig_Neck", "rotation": "CC_Base_NeckTwist01"},
	{"source": "mixamorig_Head", "rotation": "CC_Base_Head"},
	{"source": "mixamorig_LeftShoulder", "rotation": "CC_Base_L_Clavicle"},
	{"source": "mixamorig_LeftArm", "rotation": "CC_Base_L_Upperarm"},
	{"source": "mixamorig_LeftForeArm", "rotation": "CC_Base_L_Forearm"},
	{"source": "mixamorig_LeftHand", "rotation": "CC_Base_L_Hand"},
	{"source": "mixamorig_LeftHandThumb1", "rotation": "CC_Base_L_Thumb1"},
	{"source": "mixamorig_LeftHandThumb2", "rotation": "CC_Base_L_Thumb2"},
	{"source": "mixamorig_LeftHandThumb3", "rotation": "CC_Base_L_Thumb3"},
	{"source": "mixamorig_LeftHandIndex1", "rotation": "CC_Base_L_Index1"},
	{"source": "mixamorig_LeftHandIndex2", "rotation": "CC_Base_L_Index2"},
	{"source": "mixamorig_LeftHandIndex3", "rotation": "CC_Base_L_Index3"},
	{"source": "mixamorig_LeftHandMiddle1", "rotation": "CC_Base_L_Mid1"},
	{"source": "mixamorig_LeftHandMiddle2", "rotation": "CC_Base_L_Mid2"},
	{"source": "mixamorig_LeftHandMiddle3", "rotation": "CC_Base_L_Mid3"},
	{"source": "mixamorig_LeftHandRing1", "rotation": "CC_Base_L_Ring1"},
	{"source": "mixamorig_LeftHandRing2", "rotation": "CC_Base_L_Ring2"},
	{"source": "mixamorig_LeftHandRing3", "rotation": "CC_Base_L_Ring3"},
	{"source": "mixamorig_LeftHandPinky1", "rotation": "CC_Base_L_Pinky1"},
	{"source": "mixamorig_LeftHandPinky2", "rotation": "CC_Base_L_Pinky2"},
	{"source": "mixamorig_LeftHandPinky3", "rotation": "CC_Base_L_Pinky3"},
	{"source": "mixamorig_RightShoulder", "rotation": "CC_Base_R_Clavicle"},
	{"source": "mixamorig_RightArm", "rotation": "CC_Base_R_Upperarm"},
	{"source": "mixamorig_RightForeArm", "rotation": "CC_Base_R_Forearm"},
	{"source": "mixamorig_RightHand", "rotation": "CC_Base_R_Hand"},
	{"source": "mixamorig_RightHandThumb1", "rotation": "CC_Base_R_Thumb1"},
	{"source": "mixamorig_RightHandThumb2", "rotation": "CC_Base_R_Thumb2"},
	{"source": "mixamorig_RightHandThumb3", "rotation": "CC_Base_R_Thumb3"},
	{"source": "mixamorig_RightHandIndex1", "rotation": "CC_Base_R_Index1"},
	{"source": "mixamorig_RightHandIndex2", "rotation": "CC_Base_R_Index2"},
	{"source": "mixamorig_RightHandIndex3", "rotation": "CC_Base_R_Index3"},
	{"source": "mixamorig_RightHandMiddle1", "rotation": "CC_Base_R_Mid1"},
	{"source": "mixamorig_RightHandMiddle2", "rotation": "CC_Base_R_Mid2"},
	{"source": "mixamorig_RightHandMiddle3", "rotation": "CC_Base_R_Mid3"},
	{"source": "mixamorig_RightHandRing1", "rotation": "CC_Base_R_Ring1"},
	{"source": "mixamorig_RightHandRing2", "rotation": "CC_Base_R_Ring2"},
	{"source": "mixamorig_RightHandRing3", "rotation": "CC_Base_R_Ring3"},
	{"source": "mixamorig_RightHandPinky1", "rotation": "CC_Base_R_Pinky1"},
	{"source": "mixamorig_RightHandPinky2", "rotation": "CC_Base_R_Pinky2"},
	{"source": "mixamorig_RightHandPinky3", "rotation": "CC_Base_R_Pinky3"},
	{"source": "mixamorig_LeftUpLeg", "rotation": "CC_Base_L_Thigh"},
	{"source": "mixamorig_LeftLeg", "rotation": "CC_Base_L_Calf"},
	{"source": "mixamorig_LeftFoot", "rotation": "CC_Base_L_Foot"},
	{"source": "mixamorig_LeftToeBase", "rotation": "CC_Base_L_ToeBase"},
	{"source": "mixamorig_RightUpLeg", "rotation": "CC_Base_R_Thigh"},
	{"source": "mixamorig_RightLeg", "rotation": "CC_Base_R_Calf"},
	{"source": "mixamorig_RightFoot", "rotation": "CC_Base_R_Foot"},
	{"source": "mixamorig_RightToeBase", "rotation": "CC_Base_R_ToeBase"},
]

const PACKS := [
	{
		"label": "manny_combat",
		"source_dir": "res://assets/models/characters/alys_cc/unarmed_fighting_v1_source",
		"output_dir": "res://assets/models/characters/alys_cc/unarmed_fighting_v1_retargeted",
		"mapping": MANNY_TO_CC_MAP,
		"clips": [
			{"source": "A_UnarmedFightingAnimationsV1_Idle_1.fbx", "output": "idle.tscn"},
			{"source": "A_UnarmedFightingAnimationsV1_Hit_1.fbx", "output": "hurt.tscn"},
			{"source": "A_UnarmedFightingAnimationsV1_Dead_1.fbx", "output": "dead.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_1_IP.fbx", "output": "attack_1.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_2_IP.fbx", "output": "attack_2.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_3_IP.fbx", "output": "attack_3.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_4_IP.fbx", "output": "attack_4.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_5_IP.fbx", "output": "attack_5.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_6_IP.fbx", "output": "attack_6.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_7_IP.fbx", "output": "attack_7.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_8_IP.fbx", "output": "attack_8.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_9_IP.fbx", "output": "attack_9.tscn"},
			{"source": "IP/A_UnarmedFightingAnimationsV1_10_IP.fbx", "output": "attack_10.tscn"},
		],
	},
	{
		"label": "mixamo_locomotion",
		"source_dir": "res://assets/models/characters/alys",
		"output_dir": "res://assets/models/characters/alys_cc/locomotion_retargeted",
		"mapping": MIXAMO_TO_CC_MAP,
		"clips": [
			{"source": "run.fbx", "output": "run.tscn"},
			{"source": "jump.fbx", "output": "jump.tscn"},
			{"source": "dodge.fbx", "output": "dodge.tscn"},
		],
	},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for pack in PACKS:
		_retarget_pack(pack)
	quit()


func _retarget_pack(pack: Dictionary) -> void:
	var output_dir := String(pack["output_dir"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

	for clip in pack["clips"]:
		var source_path := String(pack["source_dir"]).path_join(String(clip["source"]))
		var output_path := output_dir.path_join(String(clip["output"]))
		var ok := _retarget_clip(source_path, output_path, pack["mapping"])
		print("%s %s -> %s ok=%s" % [String(pack["label"]), source_path, output_path, str(ok)])


func _retarget_clip(source_path: String, output_path: String, mapping: Array) -> bool:
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
	var mapped_pairs := _build_pairs(source_skeleton, target_skeleton, mapping)
	if mapped_pairs.is_empty():
		_cleanup_nodes(source_root, target_root)
		return false

	var retargeted := Animation.new()
	retargeted.length = source_anim.length

	for pair_index in range(mapped_pairs.size()):
		var pair: Dictionary = mapped_pairs[pair_index]
		var position_track := -1
		var position_target_name := String(pair.get("position_target_name", ""))
		if not position_target_name.is_empty():
			position_track = retargeted.add_track(Animation.TYPE_POSITION_3D)
			retargeted.track_set_path(position_track, NodePath("Skeleton3D:%s" % position_target_name))

		var rotation_track := -1
		var rotation_target_name := String(pair.get("rotation_target_name", ""))
		if not rotation_target_name.is_empty():
			rotation_track = retargeted.add_track(Animation.TYPE_ROTATION_3D)
			retargeted.track_set_path(rotation_track, NodePath("Skeleton3D:%s" % rotation_target_name))

		pair["position_track"] = position_track
		pair["rotation_track"] = rotation_track
		mapped_pairs[pair_index] = pair

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
			var source_index := int(pair["source_index"])
			var source_global_rest := source_skeleton.get_bone_global_rest(source_index)
			var source_global_pose := source_skeleton.get_bone_global_pose(source_index)
			var delta_global := source_global_rest.affine_inverse() * source_global_pose

			var position_target_index := int(pair["position_target_index"])
			if position_target_index != -1:
				var position_target_global_pose := target_skeleton.get_bone_global_rest(position_target_index) * delta_global
				var position_parent_global := _resolve_parent_global(target_globals, target_skeleton, int(pair["position_parent"]))
				var local_position_pose := position_parent_global.affine_inverse() * position_target_global_pose
				retargeted.position_track_insert_key(int(pair["position_track"]), time, local_position_pose.origin)
				target_globals[position_target_index] = Transform3D(
					target_skeleton.get_bone_global_rest(position_target_index).basis,
					position_target_global_pose.origin
				)

			var rotation_target_index := int(pair["rotation_target_index"])
			if rotation_target_index != -1:
				var rotation_target_global_pose := target_skeleton.get_bone_global_rest(rotation_target_index) * delta_global
				var rotation_parent_global := _resolve_parent_global(target_globals, target_skeleton, int(pair["rotation_parent"]))
				var local_rotation_pose := rotation_parent_global.affine_inverse() * rotation_target_global_pose
				retargeted.rotation_track_insert_key(
					int(pair["rotation_track"]),
					time,
					local_rotation_pose.basis.get_rotation_quaternion()
				)

				var stored_origin := rotation_target_global_pose.origin
				if target_globals.has(rotation_target_index):
					stored_origin = (target_globals[rotation_target_index] as Transform3D).origin
				target_globals[rotation_target_index] = Transform3D(rotation_target_global_pose.basis, stored_origin)

	target_player.add_animation_library("", AnimationLibrary.new())
	target_player.get_animation_library("").add_animation(output_path.get_file().get_basename(), retargeted)

	var packed := PackedScene.new()
	var packed_ok := packed.pack(target_root) == OK
	if packed_ok:
		packed_ok = ResourceSaver.save(packed, output_path) == OK

	_cleanup_nodes(source_root, target_root)
	return packed_ok


func _build_pairs(source_skeleton: Skeleton3D, target_skeleton: Skeleton3D, mapping: Array) -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []

	for entry in mapping:
		var source_name := String(entry.get("source", ""))
		if source_name.is_empty():
			continue

		var source_index := source_skeleton.find_bone(source_name)
		if source_index == -1:
			continue

		var position_target_name := String(entry.get("position", ""))
		var rotation_target_name := String(entry.get("rotation", ""))
		var position_target_index := -1
		var rotation_target_index := -1

		if not position_target_name.is_empty():
			position_target_index = target_skeleton.find_bone(position_target_name)
			if position_target_index == -1:
				continue
		if not rotation_target_name.is_empty():
			rotation_target_index = target_skeleton.find_bone(rotation_target_name)
			if rotation_target_index == -1:
				continue
		if position_target_index == -1 and rotation_target_index == -1:
			continue

		var sort_target_index := rotation_target_index if rotation_target_index != -1 else position_target_index
		pairs.append({
			"source_index": source_index,
			"source_name": source_name,
			"position_target_index": position_target_index,
			"position_target_name": position_target_name,
			"position_parent": target_skeleton.get_bone_parent(position_target_index) if position_target_index != -1 else -1,
			"rotation_target_index": rotation_target_index,
			"rotation_target_name": rotation_target_name,
			"rotation_parent": target_skeleton.get_bone_parent(rotation_target_index) if rotation_target_index != -1 else -1,
			"depth": _bone_depth(target_skeleton, sort_target_index),
			"sort_index": sort_target_index,
			"position_track": -1,
			"rotation_track": -1,
		})

	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.depth) == int(b.depth):
			return int(a.sort_index) < int(b.sort_index)
		return int(a.depth) < int(b.depth)
	)
	return pairs


func _resolve_parent_global(target_globals: Dictionary, target_skeleton: Skeleton3D, parent_index: int) -> Transform3D:
	if parent_index == -1:
		return Transform3D.IDENTITY
	if target_globals.has(parent_index):
		return target_globals[parent_index] as Transform3D
	return target_skeleton.get_bone_global_rest(parent_index)


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
	player.root_node = NodePath("..")
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
