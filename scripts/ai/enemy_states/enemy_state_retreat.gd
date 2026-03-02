## Ranged enemy retreats when player gets too close.
class_name EnemyStateRetreat
extends State


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController

	if enemy.target == null:
		return &"idle"

	enemy.update_facing_toward_target()

	# Move AWAY from target on X axis.
	var dir_x := signf(entity.global_position.x - enemy.target.global_position.x)
	entity.velocity.x = dir_x * enemy.get_move_speed()
	entity.velocity.z = 0.0

	enemy.apply_gravity(delta)
	entity.move_and_slide()

	var dist := enemy.get_horizontal_distance_to_target()
	# Once we're at preferred distance, shoot if off cooldown.
	if dist >= Constants.ENEMY_RANGED_PREFERRED_DISTANCE:
		if enemy.attack_cooldown_timer <= 0.0:
			return &"shoot"
		return &"chase"

	return &""
