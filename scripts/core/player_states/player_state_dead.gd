## Player death state. Disables all combat interaction and plays death visual.
class_name PlayerStateDead
extends State


func enter(_previous_state: StringName) -> void:
	entity.velocity = Vector3.ZERO
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.hurtbox.is_invincible = true
	player.intent_buffer.clear_all()
	entity.set_deferred("collision_layer", 0)
	entity.set_deferred("collision_mask", 0)

	player.play_animation(&"dead")
	player.flash_mesh(Color(1.0, 0.1, 0.1))
	var tween := entity.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player.character_model, "scale", Vector3(1.5, 0.1, 1.5), 0.5)


func physics_process(_delta: float) -> StringName:
	return &""
