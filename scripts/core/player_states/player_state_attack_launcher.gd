## Launcher attack — sends enemies airborne for juggle combos.
## Triggered by up+attack_light.
class_name PlayerStateAttackLauncher
extends State


var _attack_data: AttackDef
var _timer: float = 0.0
var _phase: int = 0  # 0=windup, 1=active, 2=recovery


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	# Read launcher attack from CharacterDef if available, fall back to preloaded default.
	if player.character_def and player.character_def.launcher_attack:
		_attack_data = player.character_def.launcher_attack.duplicate()
	else:
		_attack_data = preload("res://resources/attacks/launcher_attack.tres").duplicate()
	entity.velocity.x = 0.0
	player.combo_tracker.reset()
	_phase = 0
	var spd := Constants.PLAYER_ATTACK_SPEED_SCALE
	player.play_animation(&"attack_launcher", spd)

	# Derive phase timers from actual animation duration, scaled by attack speed.
	var anim_dur := player.get_animation_duration(&"attack_launcher")
	if anim_dur > 0.0:
		_attack_data.windup_time = (anim_dur * 0.05) / spd
		_attack_data.active_time = (anim_dur * 0.6) / spd
		_attack_data.recovery_time = (anim_dur * 0.2) / spd
	_timer = _attack_data.windup_time

	player.flash_mesh(Color(0.4, 0.8, 1.0))
	if _timer <= 0.0:
		_start_active()


func _start_active() -> void:
	_phase = 1
	_timer = _attack_data.active_time
	var player: PlayerController = entity as PlayerController
	player.hitbox.enable(_attack_data, player.facing_right)
	entity.velocity.x = 0.0
	player.flash_mesh(Color(1.0, 1.0, 1.0))
	EventBus.combat_attack_started.emit(player, &"launcher")


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
	player.apply_gravity(delta)
	entity.move_and_slide()

	match _phase:
		0:
			if _timer <= 0.0:
				_start_active()
		1:
			if _timer <= 0.0:
				_start_recovery()
		2:
			# Dodge or technique cancel during recovery.
			if player.intent_buffer.consume(&"dodge") and player.can_dodge():
				return &"dodge"
			if player.intent_buffer.consume(&"technique") or Input.is_action_just_pressed(&"technique"):
				return &"technique"
			if _timer <= 0.0:
				if entity.is_on_floor():
					return &"idle"
				return &"fall"

	return &""
