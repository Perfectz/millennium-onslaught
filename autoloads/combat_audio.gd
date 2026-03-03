## Combat audio handler. Listens to EventBus combat signals and triggers SFX
## via AudioManager's variant pool system. Implements layered hit model and
## tier-based volume hierarchy per beat-em-up audio design principles.
class_name CombatAudioSingleton
extends Node


## Cache whether pools were loaded (set after first check).
var _pools_verified: bool = false
var _combo_step_by_player: Dictionary = {}
## Running hit count for combo milestone audio (reset on combo drop).
var _combo_hit_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Defer connection so AudioManager has loaded the SFX library first.
	call_deferred("_connect_events")


func _connect_events() -> void:
	_pools_verified = true

	# Tier A — must cut through
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)
	EventBus.combat_block.connect(_on_block)
	EventBus.combat_parry.connect(_on_parry)

	# Tier B — support
	EventBus.combat_attack_started.connect(_on_attack_started)
	EventBus.combat_dodge.connect(_on_dodge)
	EventBus.player_died.connect(_on_player_died)
	EventBus.combat_juggle_launched.connect(_on_juggle_launched)
	EventBus.combat_combo_step.connect(_on_combo_step)
	EventBus.combat_combo_dropped.connect(_on_combo_dropped)


# ── Tier A Handlers ──────────────────────────────────────────────────


func _on_hit_landed(attacker: Node, _target: Node, damage: float, _hit_position: Vector3, attack_data: AttackDef) -> void:
	var is_player_attacking := attacker is PlayerController
	var attack_name := attack_data.attack_name if attack_data else &""
	if damage >= Constants.HEAVY_ATTACK_DAMAGE or attack_name == &"heavy":
		# Heavy hit: transient + body layer
		AudioManager.play_sfx_variant(&"hit_heavy", Constants.SFX_VOL_HIT_HEAVY)
		AudioManager.play_sfx_variant(&"hit_body", Constants.SFX_VOL_HIT_BODY)
	elif attack_name == &"light_1" or attack_name == &"light_2" or attack_name == &"light_finisher":
		# Light hit: transient only
		var vol := Constants.SFX_VOL_HIT_LIGHT if is_player_attacking else Constants.SFX_VOL_HIT_LIGHT - 3.0
		AudioManager.play_sfx_variant_pitched(&"hit_light", vol, _get_light_pitch_from_name(attack_name))
	elif damage >= Constants.LIGHT_ATTACK_DAMAGE * 0.8:
		var vol_fallback := Constants.SFX_VOL_HIT_LIGHT if is_player_attacking else Constants.SFX_VOL_HIT_LIGHT - 3.0
		AudioManager.play_sfx_variant(&"hit_light", vol_fallback)
	else:
		# Weak hit (enemy on player): quieter
		AudioManager.play_sfx_variant(&"hit_light", Constants.SFX_VOL_HIT_LIGHT - 3.0)

	# Player hurt vocal (Tier B — below hit transient).
	if _target is PlayerController:
		AudioManager.play_sfx_variant(&"player_hurt", Constants.SFX_VOL_PLAYER_HURT)

	# Combo milestone audio — escalating pitch ding every 5 hits.
	if is_player_attacking:
		_combo_hit_count += 1
		if _combo_hit_count % Constants.COMBO_MILESTONE_INTERVAL == 0:
			var pitch := 1.0 + (_combo_hit_count / float(Constants.COMBO_MILESTONE_INTERVAL)) * 0.08
			AudioManager.play_sfx_variant_pitched(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM, clampf(pitch, 1.0, 1.5))


func _on_kill(_attacker: Node, _target: Node, _kill_position: Vector3) -> void:
	# Kill: signature transient + louder body layer
	AudioManager.play_sfx_variant_pitched(&"kill", Constants.SFX_VOL_KILL + 1.0, 0.82)
	AudioManager.play_sfx_variant(&"hit_body", Constants.SFX_VOL_HIT_BODY + 2.0)


func _on_block(_player: Node) -> void:
	AudioManager.play_sfx_variant(&"block", Constants.SFX_VOL_BLOCK)


func _on_parry(_player: Node, _attacker: Node) -> void:
	AudioManager.play_sfx_variant(&"parry", Constants.SFX_VOL_PARRY)


# ── Tier B Handlers ──────────────────────────────────────────────────


func _on_attack_started(attacker: Node, attack_type: StringName) -> void:
	if not attacker is PlayerController:
		return  # Only play whiff for player attacks (density management).
	var step: int = int(_combo_step_by_player.get(attacker.get_instance_id(), 1))
	match attack_type:
		&"light":
			AudioManager.play_sfx_variant_pitched(
				&"whiff_light",
				Constants.SFX_VOL_WHIFF_LIGHT,
				_get_light_pitch_from_step(step)
			)
		&"heavy":
			AudioManager.play_sfx_variant(&"whiff_heavy", Constants.SFX_VOL_WHIFF_HEAVY)
		&"launcher":
			AudioManager.play_sfx_variant(&"whiff_heavy", Constants.SFX_VOL_WHIFF_HEAVY)


func _on_dodge(_player: Node) -> void:
	AudioManager.play_sfx_variant(&"dodge", Constants.SFX_VOL_DODGE)


func _on_player_died(_player_index: int) -> void:
	AudioManager.play_sfx_variant(&"knockdown", Constants.SFX_VOL_KNOCKDOWN)


func _on_juggle_launched(_target: Node, _launcher: Node) -> void:
	AudioManager.play_sfx_variant(&"hit_launcher", Constants.SFX_VOL_HIT_LAUNCHER)


func _on_combo_step(player: Node, step: int) -> void:
	if not player is PlayerController:
		return
	_combo_step_by_player[player.get_instance_id()] = clampi(step, 1, 3)


func _on_combo_dropped(player: Node) -> void:
	if not player is PlayerController:
		return
	var pid := player.get_instance_id()
	if pid in _combo_step_by_player:
		_combo_step_by_player.erase(pid)
	_combo_hit_count = 0


func _get_light_pitch_from_step(step: int) -> float:
	match clampi(step, 1, 3):
		1:
			return 0.95
		2:
			return 1.05
		_:
			return 1.15


func _get_light_pitch_from_name(attack_name: StringName) -> float:
	match attack_name:
		&"light_1":
			return 0.95
		&"light_2":
			return 1.05
		&"light_finisher":
			return 1.15
		_:
			return 1.0
