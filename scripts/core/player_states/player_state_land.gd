## Player landing state. Brief recovery pause after landing from a jump/fall.
class_name PlayerStateLand
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = Constants.PLAYER_LAND_RECOVERY_TIME
	entity.velocity.x = 0.0
	entity.velocity.y = 0.0
	(entity as PlayerController).play_animation(&"idle")
	(entity as PlayerController).spawn_dust(Constants.DUST_LAND_AMOUNT)
	AudioManager.play_sfx_variant(&"land", Constants.SFX_VOL_LAND)


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	_timer -= delta
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

	# Jump buffer takes priority even during landing recovery.
	if player.jump_buffer_timer > 0.0:
		player.consume_jump()
		return &"jump"

	if _timer <= 0.0:
		# Consume buffered actions so presses during landing aren't lost.
		if player.intent_buffer.consume(&"attack_light"):
			if InputManager.is_action_pressed_for_player(player.player_index, &"move_up"):
				return &"attack_launcher"
			return &"attack_light"
		if player.intent_buffer.consume(&"attack_heavy"):
			return &"attack_heavy"
		if player.intent_buffer.consume(&"dodge") and player.can_dodge():
			return &"dodge"
		if player.intent_buffer.consume(&"technique"):
			return &"technique"

		var x_input := player.get_movement_input()
		if absf(x_input) > Constants.INPUT_DEADZONE:
			return &"run"
		return &"idle"

	return &""
