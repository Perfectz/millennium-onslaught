## Player running state. Moves horizontally based on input.
class_name PlayerStateRun
extends State


func enter(_previous_state: StringName) -> void:
	(entity as PlayerController).play_animation(&"run")
	(entity as PlayerController)._dust_run_timer = 0.0


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	var x_input := player.get_movement_input()
	entity.velocity.x = x_input * Constants.PLAYER_RUN_SPEED
	player.update_facing(x_input)
	player.apply_gravity(delta)
	player.apply_belt_depth(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()
	player.tick_run_dust(delta)

	if not entity.is_on_floor():
		return &"fall"

	if player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	# Buffered action intents — survives hitstop and cross-state transitions.
	if player.intent_buffer.consume(&"attack_light"):
		if Input.is_action_pressed("move_up"):
			return &"attack_launcher"
		return &"attack_light"
	if player.intent_buffer.consume(&"attack_heavy"):
		return &"attack_heavy"
	if player.intent_buffer.consume(&"dodge") and player.can_dodge():
		return &"dodge"
	if player.intent_buffer.consume(&"technique") or Input.is_action_just_pressed(&"technique"):
		return &"technique"
	if player.intent_buffer.consume(&"spell"):
		return &"spell"

	if absf(x_input) < Constants.INPUT_DEADZONE:
		return &"idle"

	return &""
