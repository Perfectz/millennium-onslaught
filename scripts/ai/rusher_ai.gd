## Simple melee rusher enemy AI. Runs toward player and attacks when in range.
class_name RusherAI
extends EnemyAIBase


## Override chase to use rusher-specific speed.
func _process_chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_change_state(AIState.IDLE)
		return
	if _perception_timer > 0.0:
		return
	var to_target: Vector3 = _target.global_position - _enemy.global_position
	var dist: float = to_target.length()
	if dist <= Constants.ENEMY_RUSHER_ATTACK_RANGE and _has_attack_token and _attack_cooldown <= 0.0:
		_change_state(AIState.ATTACK)
		return
	var direction: Vector3 = to_target.normalized()
	_velocity_work.x = direction.x * Constants.ENEMY_RUSHER_SPEED
	_velocity_work.z = direction.z * (Constants.ENEMY_RUSHER_SPEED * 0.5)
	_velocity_work.y = -Constants.PLAYER_GRAVITY * delta
	_enemy.velocity = _velocity_work
	_enemy.move_and_slide()
