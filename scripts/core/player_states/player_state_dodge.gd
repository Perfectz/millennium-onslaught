## Player dodge/dash state. Grants invincibility frames and fast lateral movement.
class_name PlayerStateDodge
extends State


var _timer: float = 0.0
var _invincibility_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_visible: bool = true


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
	EventBus.combat_dodge.emit(player)


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.hurtbox.is_invincible = false
	player.model_pivot.visible = true


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	_timer -= delta
	_invincibility_timer -= delta

	if _invincibility_timer <= 0.0:
		player.hurtbox.is_invincible = false
		player.model_pivot.visible = true
	else:
		# Flicker the model during i-frames for visual feedback.
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = Constants.DODGE_FLASH_INTERVAL
			_flash_visible = not _flash_visible
			player.model_pivot.visible = _flash_visible

	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	if _timer <= 0.0:
		if entity.is_on_floor():
			# Consume buffered actions for instant post-dodge response.
			if player.intent_buffer.consume(&"attack_light"):
				if Input.is_action_pressed("move_up"):
					return &"attack_launcher"
				return &"attack_light"
			if player.intent_buffer.consume(&"attack_heavy"):
				return &"attack_heavy"
			if player.intent_buffer.consume(&"technique"):
				return &"technique"
			return &"idle"
		return &"fall"

	return &""
