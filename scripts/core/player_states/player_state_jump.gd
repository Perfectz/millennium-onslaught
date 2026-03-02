## Player jump state. Applies initial jump velocity with variable height on early release.
class_name PlayerStateJump
extends State


var _variable_jump_applied: bool = false


func enter(_previous_state: StringName) -> void:
	entity.velocity.y = Constants.PLAYER_JUMP_VELOCITY
	_variable_jump_applied = false
	(entity as PlayerController).play_animation(&"jump")


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	# Variable jump height: release early for short hop.
	if not _variable_jump_applied and Input.is_action_just_released("jump") and entity.velocity.y > 0.0:
		entity.velocity.y *= Constants.PLAYER_VARIABLE_JUMP_DAMPEN
		_variable_jump_applied = true

	var x_input := player.get_movement_input()
	entity.velocity.x = x_input * Constants.PLAYER_RUN_SPEED
	player.update_facing(x_input)
	player.apply_gravity(delta)
	player.apply_belt_depth(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	if entity.velocity.y <= 0.0:
		return &"fall"

	if entity.is_on_floor():
		return &"land"

	return &""
