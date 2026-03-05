## Shield enemy actively blocks frontal attacks while approaching.
class_name EnemyStateBlock
extends State


func enter(_previous_state: StringName) -> void:
	var enemy := entity as EnemyController
	enemy.start_blocking()
	enemy.play_animation(&"walk")


func exit() -> void:
	# Don't stop blocking on exit — controller manages block state.
	pass


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController

	if enemy.target == null:
		enemy.stop_blocking()
		return &"idle"

	enemy.update_facing_toward_target()

	# Advance slowly while blocking on XZ plane.
	var toward := enemy.target.global_position - entity.global_position
	toward.y = 0.0
	if toward.length_squared() > 0.01:
		toward = toward.normalized()
		var speed := enemy.get_move_speed() * 0.4
		entity.velocity.x = toward.x * speed
		entity.velocity.z = toward.z * speed
	else:
		entity.velocity.x = 0.0
		entity.velocity.z = 0.0

	enemy.apply_gravity(delta)
	entity.move_and_slide()

	# If in attack range, drop guard briefly to attack.
	if enemy.get_horizontal_distance_to_target() <= enemy.get_attack_range():
		if enemy.attack_cooldown_timer <= 0.0:
			enemy.stop_blocking()
			return &"attack"

	return &""
