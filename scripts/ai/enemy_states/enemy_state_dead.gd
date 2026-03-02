## Enemy death state. Disables combat interaction, plays shrink animation, then frees.
class_name EnemyStateDead
extends State


func enter(_previous_state: StringName) -> void:
	entity.velocity = Vector3.ZERO
	var enemy := entity as EnemyController
	enemy.hitbox.disable()
	enemy.hurtbox.is_invincible = true
	enemy.stop_blocking()
	if enemy.juggle.is_airborne():
		enemy.juggle.land()
	EventBus.enemy_died.emit(entity, enemy.enemy_type, entity.global_position)
	entity.set_deferred("collision_layer", 0)
	entity.set_deferred("collision_mask", 0)

	# Death visual: flash red, shrink, then remove.
	enemy.flash_mesh(Color(1.0, 0.1, 0.1))
	var health_bar := enemy.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.visible = false

	var tween := entity.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(enemy.model_pivot, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
	tween.tween_callback(entity.queue_free)


func physics_process(_delta: float) -> StringName:
	return &""
