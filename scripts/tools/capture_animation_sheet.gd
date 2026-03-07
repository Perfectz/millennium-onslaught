extends SceneTree


const SCENES := [
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/idle.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_1.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_2.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_3.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_4.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_5.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_6.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_7.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_8.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_9.tscn",
	"res://assets/models/characters/alys/unarmed_fighting_v1_retargeted/attack_10.tscn",
]
const OUTPUT_DIR := "user://anim_previews"
const VIEW_SIZE := Vector2i(512, 512)
const GRID_COLUMNS := 4
const GRID_ROWS := 4


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for scene_path in SCENES:
		var ok := await _capture_scene(scene_path)
		print("capture ", scene_path, " ok=", ok)
	quit()


func _capture_scene(scene_path: String) -> bool:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return false

	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	root.add_child(viewport)

	var world := Node3D.new()
	viewport.add_child(world)

	var camera := Camera3D.new()
	camera.look_at_from_position(Vector3(0.0, 1.3, 3.0), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	world.add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -20.0, 0.0)
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(1.5, 2.0, 1.5)
	fill.light_energy = 1.5
	world.add_child(fill)

	var stage := Node3D.new()
	world.add_child(stage)

	var scene_root := packed.instantiate() as Node3D
	scene_root.rotation_degrees.y = 180.0
	stage.add_child(scene_root)

	var anim_player := _find_animation_player(scene_root)
	if anim_player == null:
		viewport.queue_free()
		return false

	var anim_name := _first_animation_name(anim_player)
	if anim_name == &"":
		viewport.queue_free()
		return false

	var anim := anim_player.get_animation(anim_name)
	if anim == null:
		viewport.queue_free()
		return false

	var sheet := Image.create(VIEW_SIZE.x * GRID_COLUMNS, VIEW_SIZE.y * GRID_ROWS, false, Image.FORMAT_RGBA8)
	anim_player.play(anim_name)

	await process_frame
	await process_frame

	for index in range(GRID_COLUMNS * GRID_ROWS):
		var t := 0.0
		if anim.length > 0.0:
			t = (anim.length * float(index)) / float(maxi((GRID_COLUMNS * GRID_ROWS) - 1, 1))
		anim_player.seek(t, true)
		anim_player.advance(0.0)
		await process_frame
		var frame := viewport.get_texture().get_image()
		if frame == null:
			viewport.queue_free()
			return false
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, VIEW_SIZE), Vector2i((index % GRID_COLUMNS) * VIEW_SIZE.x, (index / GRID_COLUMNS) * VIEW_SIZE.y))

	var output_name := "%s.png" % scene_path.get_file().get_basename()
	var output_path := OUTPUT_DIR.path_join(output_name)
	var save_ok := sheet.save_png(ProjectSettings.globalize_path(output_path)) == OK
	viewport.queue_free()
	return save_ok


func _first_animation_name(player: AnimationPlayer) -> StringName:
	for library_name in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		for anim_name in library.get_animation_list():
			return anim_name
	return &""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var player := _find_animation_player(child)
		if player != null:
			return player
	return null
