## Orchestrates hit registration, damage application, hitstop, and event emission.
class_name CombatSystem
extends Node


## Hitstop timer.
var _hitstop_remaining: float = 0.0

## Whether hitstop is currently active.
var _hitstop_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _hitstop_active:
		_hitstop_remaining -= delta
		if _hitstop_remaining <= 0.0:
			_end_hitstop()


## Register a hit from hitbox to hurtbox. Returns true if damage was applied.
func register_hit(hitbox: HitboxComponent, hurtbox: HurtboxComponent) -> bool:
	if hurtbox.is_invincible():
		return false
	var applied: bool = hurtbox.receive_hit(hitbox)
	if not applied:
		return false
	var attacker: Node = hitbox.get_owner_node()
	var target: Node = hurtbox.get_owner_node()
	var damage: float = hitbox.get_damage()
	var hit_pos: Vector3 = hurtbox.global_position
	# Emit combat event.
	EventBus.combat_hit_landed.emit(attacker, target, damage, hit_pos)
	EventBus.log_event(&"combat_hit_landed", {
		"damage": damage,
	})
	# Determine hitstop duration based on damage.
	var hitstop_dur: float = Constants.HITSTOP_LIGHT_DURATION
	if damage >= Constants.HEAVY_ATTACK_DAMAGE:
		hitstop_dur = Constants.HITSTOP_HEAVY_DURATION
	_start_hitstop(hitstop_dur)
	return true


## Register a kill.
func register_kill(attacker: Node, target: Node, position: Vector3) -> void:
	EventBus.combat_kill.emit(attacker, target, position)
	EventBus.log_event(&"combat_kill", {})
	_start_hitstop(Constants.HITSTOP_KILL_DURATION)


## Calculate damage with stat modifiers.
func calculate_damage(base_damage: float, strength: int, defense: int) -> float:
	var str_bonus: float = base_damage * (strength * 0.05)
	var raw: float = base_damage + str_bonus
	var def_reduction: float = raw * (defense * 0.03)
	return maxf(1.0, raw - def_reduction)


func _start_hitstop(duration: float) -> void:
	_hitstop_active = true
	_hitstop_remaining = duration
	get_tree().paused = true


func _end_hitstop() -> void:
	_hitstop_active = false
	_hitstop_remaining = 0.0
	get_tree().paused = false
