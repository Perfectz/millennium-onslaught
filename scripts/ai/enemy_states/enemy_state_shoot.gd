## Ranged enemy fires a projectile at the player.
class_name EnemyStateShoot
extends State


var _timer: float = 0.0
var _phase: int = 0  # 0=windup, 1=shoot, 2=recovery
const WINDUP_TIME: float = 0.3
const RECOVERY_TIME: float = 0.5


func enter(_previous_state: StringName) -> void:
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	var enemy := entity as EnemyController
	enemy.update_facing_toward_target()
	_phase = 0
	_timer = WINDUP_TIME


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController
	_timer -= delta
	enemy.apply_gravity(delta)
	entity.move_and_slide()

	match _phase:
		0:  # windup
			if _timer <= 0.0:
				_fire_projectile(enemy)
				_phase = 2
				_timer = RECOVERY_TIME
		2:  # recovery
			if _timer <= 0.0:
				enemy.attack_cooldown_timer = enemy.get_attack_cooldown()
				return &"chase"

	return &""


func _fire_projectile(enemy: EnemyController) -> void:
	if enemy.enemy_def == null or enemy.enemy_def.projectile_scene == null:
		return
	var projectile := enemy.enemy_def.projectile_scene.instantiate()
	entity.get_tree().root.add_child(projectile)
	projectile.global_position = entity.global_position + Vector3(0.0, 0.8, 0.0)

	if projectile.has_method("setup"):
		var dir := Vector3.RIGHT if enemy.facing_right else Vector3.LEFT
		projectile.setup(dir, Constants.ENEMY_PROJECTILE_SPEED, Constants.ENEMY_PROJECTILE_DAMAGE)
