## Hitstop system. Freezes Engine.time_scale on significant hits for impact feel.
## Uses real time (ticks) to track freeze duration independent of time scale.
class_name HitstopSystem
extends Node


var _freeze_timer: float = 0.0
var _prev_ticks: int = 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_prev_ticks = Time.get_ticks_usec()
	EventBus.combat_hit_event.connect(_on_hit_event)
	EventBus.combat_kill_event.connect(_on_kill_event)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := (now - _prev_ticks) / 1_000_000.0
	_prev_ticks = now

	if _freeze_timer > 0.0:
		_freeze_timer -= real_delta
		if _freeze_timer <= 0.0:
			_freeze_timer = 0.0
			Engine.time_scale = 1.0


func start_hitstop(duration: float) -> void:
	_freeze_timer = maxf(_freeze_timer, duration)
	Engine.time_scale = 0.0


func _on_hit_event(event: CombatHitEvent) -> void:
	var attack_data := event.attack_data
	if attack_data != null and attack_data.hitstop_duration > 0.0:
		start_hitstop(attack_data.hitstop_duration)
		return
	if event.damage >= Constants.HEAVY_ATTACK_DAMAGE:
		start_hitstop(Constants.HITSTOP_HEAVY_DURATION)
	else:
		start_hitstop(Constants.HITSTOP_LIGHT_DURATION)


func _on_kill_event(_event: CombatKillEvent) -> void:
	start_hitstop(Constants.HITSTOP_KILL_DURATION)
