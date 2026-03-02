## Shield enemy actively blocks frontal attacks while approaching.
class_name EnemyStateBlock
extends State


func enter(_previous_state: StringName) -> void:
	var enemy := entity as EnemyController
	enemy.start_blocking()


func exit() -> void:
	# Don't stop blocking on exit — controller manages block state.
	pass


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController

	if enemy.target == null:
		enemy.stop_blocking()
		return &"idle"

	enemy.update_facing_toward_target()

	# Advance slowly while blocking.
	var dir_x := signf(enemy.target.global_position.x - entity.global_position.x)
	entity.velocity.x = dir_x * enemy.get_move_speed() * 0.4

	# Belt-depth.
	var z_diff := enemy.target.global_position.z - entity.global_position.z
	if absf(z_diff) > 0.2:
		entity.velocity.z = signf(z_diff) * enemy.get_move_speed() * 0.3
	else:
		entity.velocity.z = 0.0

	enemy.apply_gravity(delta)
	entity.move_and_slide()

	# If in attack range, drop guard briefly to attack.
	if enemy.get_horizontal_distance_to_target() <= enemy.get_attack_range():
		if enemy.attack_cooldown_timer <= 0.0:
			enemy.stop_blocking()
			return &"attack"

	return &""
