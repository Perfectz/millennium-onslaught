## Enemy idle state. Waits for perception delay before chasing target.
class_name EnemyStateIdle
extends State


var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = (entity as EnemyController).get_perception_delay()
	entity.velocity.x = 0.0
	(entity as EnemyController).play_animation(&"idle")


func physics_process(delta: float) -> StringName:
	_timer -= delta
	(entity as EnemyController).apply_gravity(delta)
	entity.move_and_slide()

	if _timer <= 0.0:
		var enemy := entity as EnemyController
		if enemy.target != null:
			return &"chase"

	return &""
