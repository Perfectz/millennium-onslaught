## Air light combo state. Two-step chain for launcher follow-ups.
class_name PlayerStateAttackAir
extends State


const AIR_COMBO_MAX_STEPS: int = 2

var _attack_data: AttackDef
var _timer: float = 0.0
var _phase: int = 0  # 0=windup, 1=active, 2=recovery
var _air_step: int = 1


func enter(previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	if previous_state != &"attack_air":
		player.combo_tracker.reset()

	_air_step = player.combo_tracker.advance_step()
	if _air_step > AIR_COMBO_MAX_STEPS:
		player.combo_tracker.reset()
		_air_step = player.combo_tracker.advance_step()

	match _air_step:
		1:
			_attack_data = preload("res://resources/attacks/light_attack_1.tres").duplicate()
			_attack_data.hitstop_duration = 0.05
		_:
			_attack_data = preload("res://resources/attacks/light_attack_2.tres").duplicate()
			_attack_data.hitstop_duration = 0.07

	_attack_data.windup_time = 0.03
	_attack_data.active_time = 0.11
	_attack_data.recovery_time = 0.14
	_attack_data.knockback_force *= 0.9 if _air_step == 1 else 1.05

	_phase = 0
	_timer = _attack_data.windup_time
	var anim_name: StringName = &"attack_light_1" if _air_step == 1 else &"attack_light_2"
	player.play_animation(anim_name, Constants.PLAYER_ATTACK_SPEED_SCALE * 0.9)
	player.flash_mesh(Color(0.85, 0.95, 1.0))
	var forward := 1.0 if player.facing_right else -1.0
	entity.velocity.x = forward * Constants.PLAYER_ATTACK_LUNGE_SPEED * 0.5

	if _timer <= 0.0:
		_start_active()


func _start_active() -> void:
	_phase = 1
	_timer = _attack_data.active_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.enable(_attack_data, player.facing_right)
	EventBus.combat_attack_started.emit(player, &"light")


func _start_recovery() -> void:
	_phase = 2
	_timer = _attack_data.recovery_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.restore_mesh()


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.restore_mesh()


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController
	_timer -= delta

	var forward := 1.0 if player.facing_right else -1.0
	entity.velocity.x = move_toward(
		entity.velocity.x,
		forward * Constants.PLAYER_ATTACK_LUNGE_SPEED * 0.35,
		Constants.PLAYER_RUN_SPEED * delta
	)
	player.apply_gravity(delta)
	player.apply_belt_depth(delta)
	entity.move_and_slide()
	player.clamp_belt_depth()

	match _phase:
		0:
			if _timer <= 0.0:
				_start_active()
		1:
			if _timer <= 0.0:
				_start_recovery()
		2:
			if _air_step < AIR_COMBO_MAX_STEPS and _timer <= _attack_data.recovery_time * 0.7:
				if player.intent_buffer.consume(&"attack_light"):
					return &"attack_air"
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"land"
				return &"fall"

	return &""
