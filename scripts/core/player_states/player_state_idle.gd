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
	player.apply_belt_depth(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	if not entity.is_on_floor():
		return &"fall"

	if player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	if Input.is_action_just_pressed("attack_light"):
		if Input.is_action_pressed("move_up"):
			return &"attack_launcher"
		return &"attack_light"
	if Input.is_action_just_pressed("attack_heavy"):
		return &"attack_heavy"
	if Input.is_action_just_pressed("dodge") and player.can_dodge():
		return &"dodge"
	if Input.is_action_just_pressed("technique"):
		return &"technique"

	var x_input := player.get_movement_input()
	if absf(x_input) > Constants.INPUT_DEADZONE:
		return &"run"

	return &""
