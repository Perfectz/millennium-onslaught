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

	# Read combo chain from CharacterDef if available, fall back to preloaded defaults.
	var chain: Array[AttackDef] = []
	if player.character_def and player.character_def.combo_chain.size() >= 3:
		chain = player.character_def.combo_chain
	if chain.size() >= 3:
		match _combo_step:
			1: _attack_data = chain[0].duplicate()
			2: _attack_data = chain[1].duplicate()
			_: _attack_data = chain[2].duplicate()
	else:
		match _combo_step:
			1: _attack_data = preload("res://resources/attacks/light_attack_1.tres").duplicate()
			2: _attack_data = preload("res://resources/attacks/light_attack_2.tres").duplicate()
			_: _attack_data = preload("res://resources/attacks/light_attack_3.tres").duplicate()

	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	_phase = 0
	_elapsed = 0.0

	var anim_name: StringName
	match _combo_step:
		1: anim_name = &"attack_light_1"
		2: anim_name = &"attack_light_2"
		_: anim_name = &"attack_light_3"
	var spd := Constants.PLAYER_ATTACK_SPEED_SCALE
	if player.character_def:
		spd *= player.character_def.attack_speed_scale
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
	player.hitbox.enable(_attack_data, player.facing_angle)
	entity.velocity.x = 0.0
	player.flash_mesh(Color(1.0, 1.0, 1.0))
	EventBus.combat_attack_started.emit(player, &"light")


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
	player.clamp_to_bounds()

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
				# Rapid-fire: restart combo if attack button still held.
				if InputManager.is_action_pressed_for_player(player.player_index, &"attack_light"):
					return &"attack_light"
				if entity.is_on_floor():
					return &"idle"
				return &"fall"
			# Combo chaining: allow light→light during recovery.
			if _combo_step > 0 and _combo_step < Constants.PLAYER_COMBO_MAX_STEPS and player.intent_buffer.consume(&"attack_light"):
				return &"attack_light"

	return &""


## Check if any cancel-able action is being input during the cancel window.
func _check_cancel_inputs(player: PlayerController) -> StringName:
	if player.intent_buffer.has_buffered(&"attack_heavy") and ComboCancelChecker.check(_attack_data, _elapsed, &"heavy"):
		player.intent_buffer.consume(&"attack_heavy")
		return &"attack_heavy"
	if player.intent_buffer.has_buffered(&"attack_light") and InputManager.is_action_pressed_for_player(player.player_index, &"move_up"):
		if ComboCancelChecker.check(_attack_data, _elapsed, &"launcher"):
			player.intent_buffer.consume(&"attack_light")
			return &"attack_launcher"
	if player.intent_buffer.has_buffered(&"dodge") and player.can_dodge() and ComboCancelChecker.check(_attack_data, _elapsed, &"dodge"):
		player.intent_buffer.consume(&"dodge")
		return &"dodge"
	if _phase == 2 and player.intent_buffer.consume(&"technique"):
		return &"technique"
	return &""
