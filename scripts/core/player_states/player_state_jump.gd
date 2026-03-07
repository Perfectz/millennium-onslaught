## Player jump state. Applies initial jump velocity with variable height on early release.
class_name PlayerStateJump
extends State


var _variable_jump_applied: bool = false


func enter(_previous_state: StringName) -> void:
	entity.velocity.y = Constants.PLAYER_JUMP_VELOCITY
	_variable_jump_applied = false
	(entity as PlayerController).play_animation(&"jump")
	AudioManager.play_sfx_variant(&"jump", Constants.SFX_VOL_JUMP)


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	# Variable jump height: release early for short hop.
	if not _variable_jump_applied and not InputManager.is_action_pressed_for_player(player.player_index, &"jump") and entity.velocity.y > 0.0:
		entity.velocity.y *= Constants.PLAYER_VARIABLE_JUMP_DAMPEN
		_variable_jump_applied = true

	var input_vec := player.get_movement_input_vector()
	entity.velocity.x = input_vec.x * Constants.PLAYER_RUN_SPEED
	entity.velocity.z = input_vec.y * Constants.PLAYER_RUN_SPEED
	player.update_facing_from_input(input_vec, delta)
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

	if player.intent_buffer.consume(&"attack_light"):
		return &"attack_air"

	if entity.velocity.y <= 0.0:
		return &"fall"

	if entity.is_on_floor():
		return &"land"

	return &""
