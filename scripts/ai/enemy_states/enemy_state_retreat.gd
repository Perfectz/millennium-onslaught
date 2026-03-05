## Ranged enemy retreats when player gets too close.
class_name EnemyStateRetreat
extends State


func enter(_previous_state: StringName) -> void:
	(entity as EnemyController).play_animation(&"run")


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController

	if enemy.target == null:
		return &"idle"

	enemy.update_facing_toward_target()

	# Move AWAY from target on XZ plane.
	var away_dir := entity.global_position - enemy.target.global_position
	away_dir.y = 0.0
	if away_dir.length_squared() > 0.001:
		away_dir = away_dir.normalized()
	else:
		away_dir = -enemy.facing_direction
	var speed := enemy.get_move_speed()
	entity.velocity.x = away_dir.x * speed
	entity.velocity.z = away_dir.z * speed

	enemy.apply_gravity(delta)
	entity.move_and_slide()

	var dist := enemy.get_horizontal_distance_to_target()
	# Once we're at preferred distance, shoot if off cooldown.
	if dist >= Constants.ENEMY_RANGED_PREFERRED_DISTANCE:
		if enemy.attack_cooldown_timer <= 0.0:
			return &"shoot"
		return &"chase"

	return &""
