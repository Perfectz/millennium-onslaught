## Player hit-stun state. Decays knockback velocity then returns to idle/fall.
class_name PlayerStateHurt
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = Constants.PLAYER_HIT_STUN_DURATION
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.combo_tracker.reset()
	player.play_animation(&"hurt")


func physics_process(delta: float) -> StringName:
	_timer -= delta

	entity.velocity.x = move_toward(entity.velocity.x, 0.0, Constants.KNOCKBACK_FRICTION * delta)
	entity.velocity.z = move_toward(entity.velocity.z, 0.0, Constants.KNOCKBACK_FRICTION * delta)
	(entity as PlayerController).apply_gravity(delta)
	entity.move_and_slide()

	if _timer <= 0.0:
		if entity.is_on_floor():
			return &"idle"
		return &"fall"

	return &""
