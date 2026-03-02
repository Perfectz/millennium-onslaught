## Boss phase transition state. Brief invincibility + visual flash + camera shake.
## Sets enrage multipliers then returns to chase.
class_name EnemyStateBossPhaseCheck
extends State


const BossAttack2 := preload("res://resources/attacks/boss_attack_2.tres")

var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	var enemy := entity as EnemyController
	_timer = 1.0
	enemy.hurtbox.is_invincible = true
	entity.velocity = Vector3.ZERO

	# Visual: flash purple.
	enemy.flash_mesh(Color(0.9, 0.2, 1.0))

	# Camera shake for phase transition impact.
	EventBus.dungeon_boss_phase_changed.emit(enemy, 2)


func physics_process(delta: float) -> StringName:
	var enemy := entity as EnemyController
	enemy.apply_gravity(delta)
	entity.move_and_slide()

	_timer -= delta

	# Pulsing flash during transition.
	if fmod(_timer, 0.2) < 0.1:
		enemy.flash_mesh(Color(0.9, 0.2, 1.0))
	else:
		enemy.flash_mesh(Color(0.4, 0.1, 0.5))

	if _timer <= 0.0:
		# Apply enrage.
		enemy.boss_phase = 2
		enemy.speed_multiplier = Constants.BOSS_ENRAGE_SPEED_MULT
		enemy.boss_attack_override = BossAttack2
		enemy.hurtbox.is_invincible = false
		enemy.restore_mesh()
		return &"chase"

	return &""


func exit() -> void:
	var enemy := entity as EnemyController
	enemy.hurtbox.is_invincible = false
	enemy.restore_mesh()
