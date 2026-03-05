## Enemy attack state with 3-phase timing (windup/active/recovery).
class_name EnemyStateAttack
extends State


var _attack_data: AttackDef
var _timer: float = 0.0
var _phase: int = 0  # 0=windup, 1=active, 2=recovery


func enter(_previous_state: StringName) -> void:
	var enemy := entity as EnemyController
	if enemy.boss_attack_override:
		_attack_data = enemy.boss_attack_override
	elif enemy.enemy_def and enemy.enemy_def.attack:
		_attack_data = enemy.enemy_def.attack
	else:
		_attack_data = preload("res://resources/attacks/enemy_rusher_attack.tres")
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	enemy.update_facing_toward_target()
	_phase = 0
	_timer = _attack_data.windup_time
	enemy.play_animation(&"attack")
	enemy.flash_mesh(Color(1.0, 0.6, 0.2))
	if _timer <= 0.0:
		_start_active()


func _start_active() -> void:
	_phase = 1
	_timer = _attack_data.active_time
	var enemy := entity as EnemyController
	enemy.hitbox.enable(_attack_data, enemy.facing_angle)
	enemy.flash_mesh(Color(1.0, 0.3, 0.3))


func _start_recovery() -> void:
	_phase = 2
	_timer = _attack_data.recovery_time
	var enemy := entity as EnemyController
	enemy.hitbox.disable()
	enemy.restore_mesh()


func exit() -> void:
	var enemy := entity as EnemyController
	enemy.hitbox.disable()
	enemy.restore_mesh()


func physics_process(delta: float) -> StringName:
	_timer -= delta
	(entity as EnemyController).apply_gravity(delta)
	entity.move_and_slide()

	match _phase:
		0:
			if _timer <= 0.0:
				_start_active()
		1:
			if _timer <= 0.0:
				_start_recovery()
		2:
			if _timer <= 0.0:
				var enemy := entity as EnemyController
				enemy.attack_cooldown_timer = enemy.get_attack_cooldown()
				return &"chase"

	return &""
