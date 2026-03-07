## Player falling state. Applies coyote time grace period when walking off an edge.
class_name PlayerStateFall
extends State


func enter(previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	# Coyote time: grace period only when walking off an edge (not after jumping).
	if previous_state != &"jump":
		player.coyote_timer = Constants.PLAYER_COYOTE_TIME
	else:
		player.coyote_timer = 0.0
	player.play_animation(&"jump")


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	player.coyote_timer = maxf(player.coyote_timer - delta, 0.0)

	var input_vec := player.get_movement_input_vector()
	entity.velocity.x = input_vec.x * Constants.PLAYER_RUN_SPEED
	entity.velocity.z = input_vec.y * Constants.PLAYER_RUN_SPEED
	player.update_facing_from_input(input_vec, delta)
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

	if player.intent_buffer.consume(&"attack_light"):
		return &"attack_air"

	if entity.is_on_floor():
		return &"land"

	# Coyote jump: can still jump briefly after walking off edge.
	if player.coyote_timer > 0.0 and player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	return &""
