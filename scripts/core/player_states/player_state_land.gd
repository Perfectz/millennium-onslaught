## Player landing state. Brief recovery pause after landing from a jump/fall.
class_name PlayerStateLand
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = Constants.PLAYER_LAND_RECOVERY_TIME
	entity.velocity.x = 0.0
	entity.velocity.y = 0.0
	(entity as PlayerController).play_animation(&"idle")


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	_timer -= delta
	player.apply_gravity(delta)
	player.apply_belt_depth(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	# Jump buffer takes priority even during landing recovery.
	if player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	if _timer <= 0.0:
		var x_input := player.get_movement_input()
		if absf(x_input) > Constants.INPUT_DEADZONE:
			return &"run"
		return &"idle"

	return &""
