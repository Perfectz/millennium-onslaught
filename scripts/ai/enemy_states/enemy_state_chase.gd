## Enemy chase state. Moves toward target with circular flanking on XZ plane.
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

	# Compute flanking offset so enemies spread around the player.
	var flank_offset := _compute_flank_offset(enemy)
	var target_pos := enemy.target.global_position + flank_offset

	# Move toward flanked target on XZ plane at equal speed.
	var move_dir := target_pos - entity.global_position
	move_dir.y = 0.0
	var speed := enemy.get_move_speed()
	if move_dir.length_squared() > 0.01:
		move_dir = move_dir.normalized()
		entity.velocity.x = move_dir.x * speed
		entity.velocity.z = move_dir.z * speed
	else:
		entity.velocity.x = 0.0
		entity.velocity.z = 0.0

	enemy.apply_gravity(delta)
	entity.move_and_slide()
	enemy.clamp_to_bounds()

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


## Compute circular flanking offset so enemies distribute around the player.
## Each enemy gets a radial position at TAU * idx / count.
func _compute_flank_offset(enemy: EnemyController) -> Vector3:
	var enemies := enemy.get_tree().get_nodes_in_group(&"enemies")
	var active: Array[Node] = []
	for e in enemies:
		if e is EnemyController and (e as EnemyController).health and not (e as EnemyController).health.is_dead():
			active.append(e)
	if active.size() <= 1:
		return Vector3.ZERO
	var idx := active.find(enemy)
	if idx < 0:
		return Vector3.ZERO
	# Circular distribution: each enemy gets an angle slice around the player.
	var angle := TAU * float(idx) / float(active.size())
	var radius := 1.5
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
