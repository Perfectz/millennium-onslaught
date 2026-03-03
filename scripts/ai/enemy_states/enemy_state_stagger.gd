## Shield enemy stagger — guard broken, vulnerable for a duration.
class_name EnemyStateStagger
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	var enemy := entity as EnemyController
	_timer = enemy.consume_stagger_duration(Constants.ENEMY_SHIELD_STAGGER_DURATION)
	enemy.stop_blocking()
	enemy.hitbox.disable()
	entity.velocity.x = 0.0
	enemy.play_animation(&"hurt")


func physics_process(delta: float) -> StringName:
	_timer -= delta

	entity.velocity.x = move_toward(entity.velocity.x, 0.0, 10.0 * delta)
	(entity as EnemyController).apply_gravity(delta)
	entity.move_and_slide()

	if _timer <= 0.0:
		return &"chase"

	return &""
