## Enemy chase state. Moves toward target with belt-depth tracking.
class_name EnemyStateChase
extends State


func enter(_previous_state: StringName) -> void:
	(entity as EnemyController).play_animation(&"run")


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController

	if not entity.is_inside_tree():
		return &""

	if enemy.target == null or not enemy.target.is_inside_tree():
		return &"idle"

	enemy.update_facing_toward_target()

	# Move toward target X position.
	var dir_x := signf(enemy.target.global_position.x - entity.global_position.x)
	var speed := enemy.get_move_speed()
	entity.velocity.x = dir_x * speed

	# Belt-depth: nudge Z toward target.
	var z_diff := enemy.target.global_position.z - entity.global_position.z
	if absf(z_diff) > Constants.ENEMY_Z_DEADZONE:
		entity.velocity.z = signf(z_diff) * speed * Constants.ENEMY_Z_SPEED_RATIO
	else:
		entity.velocity.z = 0.0

	enemy.apply_gravity(delta)
	entity.move_and_slide()

	# Ranged enemies prefer distance — switch to retreat/shoot.
	var dist := enemy.get_horizontal_distance_to_target()
	if enemy.enemy_def and enemy.enemy_def.behavior == &"ranged":
		if dist <= Constants.ENEMY_RANGED_RETREAT_DISTANCE:
			return &"retreat"
		if dist <= enemy.get_attack_range() and enemy.attack_cooldown_timer <= 0.0:
			return &"shoot"

	# Shield enemies start blocking when close.
	if enemy.enemy_def and enemy.enemy_def.behavior == &"shield":
		if dist <= enemy.get_attack_range() * Constants.ENEMY_SHIELD_BLOCK_RANGE_MULT:
			enemy.start_blocking()
		else:
			enemy.stop_blocking()

	if dist <= enemy.get_attack_range():
		if enemy.attack_cooldown_timer <= 0.0:
			return &"attack"

	return &""
