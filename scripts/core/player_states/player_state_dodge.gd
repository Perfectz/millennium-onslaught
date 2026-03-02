## Player dodge/dash state. Grants invincibility frames and fast lateral movement.
class_name PlayerStateDodge
extends State


var _timer: float = 0.0
var _invincibility_timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	_timer = Constants.DODGE_DURATION
	_invincibility_timer = Constants.DODGE_INVINCIBILITY_DURATION
	player.hurtbox.is_invincible = true
	player.start_dodge_cooldown()
	player.combo_tracker.reset()
	player.play_animation(&"dodge")

	var direction := 1.0 if player.facing_right else -1.0
	entity.velocity.x = direction * Constants.DODGE_SPEED
	entity.velocity.y = 0.0


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.hurtbox.is_invincible = false


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	_timer -= delta
	_invincibility_timer -= delta

	if _invincibility_timer <= 0.0:
		player.hurtbox.is_invincible = false

	player.apply_gravity(delta)
	entity.move_and_slide()

	if _timer <= 0.0:
		if entity.is_on_floor():
			return &"idle"
		return &"fall"

	return &""
