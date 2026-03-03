## Player hit-stun state. Decays knockback velocity then returns to idle/fall.
class_name PlayerStateHurt
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = Constants.PLAYER_HIT_STUN_DURATION
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.combo_tracker.reset()
	# Clear stale intents on taking a hit — fresh start after stun.
	player.intent_buffer.clear_all()
	player.play_animation(&"hurt")


func physics_process(delta: float) -> StringName:
	_timer -= delta

	var player: PlayerController = entity as PlayerController
	entity.velocity.x = move_toward(entity.velocity.x, 0.0, Constants.KNOCKBACK_FRICTION * delta)
	entity.velocity.z = move_toward(entity.velocity.z, 0.0, Constants.KNOCKBACK_FRICTION * delta)
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	if _timer <= 0.0:
		# Consume any action buffered during stun for instant response on recovery.
		if entity.is_on_floor():
			if player.intent_buffer.consume(&"dodge") and player.can_dodge():
				return &"dodge"
			if player.intent_buffer.consume(&"attack_light"):
				return &"attack_light"
			if player.intent_buffer.consume(&"attack_heavy"):
				return &"attack_heavy"
			if player.intent_buffer.consume(&"technique"):
				return &"technique"
			return &"idle"
		return &"fall"

	return &""
