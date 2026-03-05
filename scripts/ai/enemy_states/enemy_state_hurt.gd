## Enemy hit-stun state. Decays knockback then transitions to chase or fall.
class_name EnemyStateHurt
extends State


var _timer: float = 0.0
var _flash_timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = Constants.ENEMY_HIT_STUN_DURATION
	var enemy := entity as EnemyController
	enemy.hitbox.disable()
	enemy.stop_blocking()
	enemy.play_animation(&"hurt")
	enemy.flash_mesh(Color(1, 1, 1))
	_flash_timer = 0.08


func physics_process(delta: float) -> StringName:
	_timer -= delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			(entity as EnemyController).restore_mesh()

	entity.velocity.x = move_toward(entity.velocity.x, 0.0, Constants.ENEMY_KNOCKBACK_FRICTION * delta)
	entity.velocity.z = move_toward(entity.velocity.z, 0.0, Constants.ENEMY_KNOCKBACK_FRICTION * delta)
	(entity as EnemyController).apply_gravity(delta)
	entity.move_and_slide()

	if _timer <= 0.0:
		var enemy := entity as EnemyController
		# Force an attack cooldown so the enemy can't immediately counterattack.
		enemy.attack_cooldown_timer = maxf(enemy.attack_cooldown_timer, Constants.ENEMY_POST_HURT_COOLDOWN)
		if entity.is_on_floor():
			if enemy.juggle.is_airborne():
				enemy.juggle.land()
			return &"chase"
		# If juggled, stay in hurt until landing — remain vulnerable to air hits.
		if enemy.juggle.is_airborne():
			return &""
		return &"idle"

	return &""
