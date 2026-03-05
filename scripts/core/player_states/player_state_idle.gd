## Player idle state. Stands still, listens for movement/action inputs.
class_name PlayerStateIdle
extends State


func enter(_previous_state: StringName) -> void:
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	(entity as PlayerController).play_animation(&"idle")


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

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

	var input := player.get_movement_input_vector()
	if input.length() > Constants.INPUT_DEADZONE:
		return &"run"

	return &""
