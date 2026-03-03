## Enemy death state. Disables combat interaction, plays shrink animation, then frees.
class_name EnemyStateDead
extends State


func enter(_previous_state: StringName) -> void:
	entity.velocity = Vector3.ZERO
	var enemy := entity as EnemyController
	enemy.hitbox.disable()
	enemy.hurtbox.is_invincible = true
	enemy.stop_blocking()
	enemy.remove_from_group("enemies")
	if enemy.juggle.is_airborne():
		enemy.juggle.land()
	EventBus.enemy_died.emit(entity, enemy.enemy_type, entity.global_position)
	entity.set_deferred("collision_layer", 0)
	entity.set_deferred("collision_mask", 0)

	# Death visual: play death animation, flash red, linger, dissolve, then remove.
	enemy.play_animation(&"dead")
	enemy.flash_mesh(Color(1.0, 0.1, 0.1))
	var health_bar := enemy.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.visible = false

	# Try dissolve effect on the enemy mesh; fall back to scale shrink.
	var mesh := enemy.model_pivot.get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var tween := entity.create_tween()
		tween.tween_interval(Constants.ENEMY_CORPSE_LINGER_TIME)
		tween.tween_callback(func() -> void:
			DissolveEffect.dissolve(mesh, Constants.DISSOLVE_DEATH_DURATION, entity.queue_free)
		)
	else:
		# Fallback: original scale shrink.
		var tween := entity.create_tween()
		tween.tween_interval(Constants.ENEMY_CORPSE_LINGER_TIME)
		tween.tween_property(enemy.model_pivot, "scale", Vector3(0.01, 0.01, 0.01), Constants.ENEMY_CORPSE_FADE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_callback(entity.queue_free)


func physics_process(_delta: float) -> StringName:
	return &""
