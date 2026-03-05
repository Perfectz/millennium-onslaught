## Enemy dormant state. Stands idle at a fixed position until the player
## enters engagement range, then transitions to chase after a staggered delay.
class_name EnemyStateDormant
extends State


## Random wake-up delay so enemies don't all rush at once.
var _wake_delay: float = 0.0
var _wake_triggered: bool = false


func enter(_previous_state: StringName) -> void:
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	_wake_triggered = false
	_wake_delay = 0.0
	(entity as EnemyController).play_animation(&"idle")


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController
	enemy.apply_gravity(delta)
	entity.move_and_slide()

	if _wake_triggered:
		_wake_delay -= delta
		if _wake_delay <= 0.0:
			return &"chase"
		return &""

	# Wake up when the player is within engagement range.
	var dist := enemy.get_horizontal_distance_to_target()
	if dist <= Constants.ENEMY_ENGAGEMENT_RANGE:
		_wake_triggered = true
		_wake_delay = randf_range(0.1, 0.6)

	return &""
