extends SceneTree


const ALYS_PATH := "res://resources/characters/alys.tres"
const ANIMATIONS := [
	&"idle",
	&"run",
	&"jump",
	&"attack_light_1",
	&"attack_light_2",
	&"attack_light_3",
	&"attack_heavy",
	&"attack_launcher",
	&"hurt",
	&"dead",
	&"dodge",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var alys := load(ALYS_PATH)
	var model := CharacterModel.new()
	model.setup(alys)
	root.add_child(model)

	await process_frame
	await process_frame

	for anim_name in ANIMATIONS:
		model.play_animation(anim_name)
		await process_frame
		print("%s duration=%s" % [anim_name, model.get_animation_duration(anim_name)])

	quit()
