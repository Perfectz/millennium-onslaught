## Heavy attack state with 3-phase timing. Resets combo on entry.
## Supports cancel window: dodge cancel during late recovery.
class_name PlayerStateAttackHeavy
extends State


var _attack_data: AttackDef
var _timer: float = 0.0
var _elapsed: float = 0.0
var _phase: int = 0  # 0=windup, 1=active, 2=recovery


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	# Read heavy attack from CharacterDef if available, fall back to preloaded default.
	if player.character_def and player.character_def.heavy_attack:
		_attack_data = player.character_def.heavy_attack.duplicate()
	else:
		_attack_data = preload("res://resources/attacks/heavy_attack.tres").duplicate()
	entity.velocity.x = 0.0
	entity.velocity.z = 0.0
	player.combo_tracker.reset()
	_phase = 0
	_elapsed = 0.0
	var spd := Constants.PLAYER_ATTACK_SPEED_SCALE
	if player.character_def:
		spd *= player.character_def.attack_speed_scale
	player.play_animation(&"attack_heavy", spd)

	# Derive phase timers from actual animation duration, scaled by attack speed.
	var anim_dur := player.get_animation_duration(&"attack_heavy")
	if anim_dur > 0.0:
		_attack_data.windup_time = (anim_dur * 0.1) / spd
		_attack_data.active_time = (anim_dur * 0.6) / spd
		_attack_data.recovery_time = (anim_dur * 0.2) / spd
	_timer = _attack_data.windup_time

	player.flash_mesh(Color(1.0, 0.6, 0.2))
	if _timer <= 0.0:
		_start_active()


func _start_active() -> void:
	_phase = 1
	_timer = _attack_data.active_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.enable(_attack_data, player.facing_angle)
	entity.velocity.x = 0.0
	player.flash_mesh(Color(1.0, 1.0, 1.0))
	EventBus.combat_attack_started.emit(player, &"heavy")


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

	# Cancel window: dodge or technique during recovery.
	if player.intent_buffer.has_buffered(&"dodge") and player.can_dodge() and ComboCancelChecker.check(_attack_data, _elapsed, &"dodge"):
		player.intent_buffer.consume(&"dodge")
		return &"dodge"
	if _phase == 2 and player.intent_buffer.consume(&"technique"):
		return &"technique"

	match _phase:
		0:
			if _timer <= 0.0:
				_start_active()
		1:
			if _timer <= 0.0:
				_start_recovery()
		2:
			if _timer <= 0.0:
				# Rapid-fire: repeat heavy if button still held.
				if InputManager.is_action_pressed_for_player(player.player_index, &"attack_heavy"):
					return &"attack_heavy"
				if entity.is_on_floor():
					return &"idle"
				return &"fall"

	return &""
