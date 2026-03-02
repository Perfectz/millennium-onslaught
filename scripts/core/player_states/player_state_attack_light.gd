## Light attack state with 3-phase timing (windup/active/recovery) and combo chaining.
## Supports cancel windows: mid-combo branching into heavy, launcher, or dodge.
class_name PlayerStateAttackLight
extends State


var _attack_data: AttackDef
var _timer: float = 0.0
var _elapsed: float = 0.0
var _phase: int = 0  # 0=windup, 1=active, 2=recovery
var _combo_step: int = 0


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	_combo_step = player.combo_tracker.advance_step()

	match _combo_step:
		1: _attack_data = preload("res://resources/attacks/light_attack_1.tres")
		2: _attack_data = preload("res://resources/attacks/light_attack_2.tres")
		_: _attack_data = preload("res://resources/attacks/light_attack_3.tres")

	entity.velocity.x = 0.0
	_phase = 0
	_elapsed = 0.0

	var anim_name: StringName
	match _combo_step:
		1: anim_name = &"attack_light_1"
		2: anim_name = &"attack_light_2"
		_: anim_name = &"attack_light_3"
	var spd := Constants.PLAYER_ATTACK_SPEED_SCALE
	player.play_animation(anim_name, spd)

	# Derive phase timers from actual animation duration, scaled by attack speed.
	var anim_dur := player.get_animation_duration(anim_name)
	if anim_dur > 0.0:
		_attack_data.windup_time = (anim_dur * 0.05) / spd
		_attack_data.active_time = (anim_dur * 0.6) / spd
		_attack_data.recovery_time = (anim_dur * 0.2) / spd
	_timer = _attack_data.windup_time

	player.flash_mesh(Color(1.0, 1.0, 0.5))
	if _timer <= 0.0:
		_start_active()


func _start_active() -> void:
	_phase = 1
	_timer = _attack_data.active_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.enable(_attack_data, player.facing_right)
	entity.velocity.x = 0.0
	player.flash_mesh(Color(1.0, 1.0, 1.0))


func _start_recovery() -> void:
	_phase = 2
	_timer = _attack_data.recovery_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.restore_mesh()
	player.play_animation(&"idle")


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.hitbox.disable()
	player.restore_mesh()


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController

	_timer -= delta
	_elapsed += delta
	player.apply_gravity(delta)
	entity.move_and_slide()

	# Check cancel window inputs.
	var cancel := _check_cancel_inputs(player)
	if cancel != &"":
		return cancel

	match _phase:
		0:  # windup
			if _timer <= 0.0:
				_start_active()
		1:  # active
			if _timer <= 0.0:
				_start_recovery()
		2:  # recovery
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"idle"
				return &"fall"
			# Combo chaining: allow light→light during recovery (not after finisher).
			if _combo_step > 0 and _combo_step < Constants.PLAYER_COMBO_MAX_STEPS and Input.is_action_just_pressed("attack_light"):
				return &"attack_light"

	return &""


## Check if any cancel-able action is being input during the cancel window.
func _check_cancel_inputs(player: PlayerController) -> StringName:
	if Input.is_action_just_pressed("attack_heavy"):
		if ComboCancelChecker.check(_attack_data, _elapsed, &"heavy"):
			return &"attack_heavy"
	if Input.is_action_just_pressed("attack_light") and Input.is_action_pressed("move_up"):
		if ComboCancelChecker.check(_attack_data, _elapsed, &"launcher"):
			return &"attack_launcher"
	if Input.is_action_just_pressed("dodge") and player.can_dodge():
		if ComboCancelChecker.check(_attack_data, _elapsed, &"dodge"):
			return &"dodge"
	return &""
