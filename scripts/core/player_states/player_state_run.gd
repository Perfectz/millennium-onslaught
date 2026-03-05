## Player running state. Moves horizontally based on input.
class_name PlayerStateRun
extends State


func enter(_previous_state: StringName) -> void:
	(entity as PlayerController).play_animation(&"run")
	(entity as PlayerController)._dust_run_timer = 0.0


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	var input := player.get_movement_input_vector()
	entity.velocity.x = input.x * Constants.PLAYER_MOVE_SPEED
	entity.velocity.z = input.y * Constants.PLAYER_MOVE_SPEED
	player.update_facing_from_input(input, delta)
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()
	player.tick_run_dust(delta)

	if not entity.is_on_floor():
		return &"fall"

	if player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	# Buffered action intents — survives hitstop and cross-state transitions.
	if player.intent_buffer.consume(&"attack_light"):
		if InputManager.is_action_pressed_for_player(player.player_index, &"move_up"):
			return &"attack_launcher"
		return &"attack_light"
	if player.intent_buffer.consume(&"attack_heavy"):
		return &"attack_heavy"
	if player.intent_buffer.has_buffered(&"dodge") and player.can_dodge():
		player.intent_buffer.consume(&"dodge")
		return &"dodge"
	if player.intent_buffer.consume(&"technique"):
		return &"technique"
	if player.intent_buffer.consume(&"spell"):
		return &"spell"

	if input.length() < Constants.INPUT_DEADZONE:
		return &"idle"

	return &""
