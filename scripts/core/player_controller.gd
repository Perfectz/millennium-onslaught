## Player CharacterBody3D — owns state machine, health, combo, hitbox/hurtbox.
## Bridges component signals to EventBus for cross-system communication.
class_name PlayerController
extends CharacterBody3D


const _SPELL_FIREBALL := preload("res://resources/techniques/spell_fireball.tres")
const _SPELL_HEAL := preload("res://resources/techniques/spell_heal.tres")
const _SPELL_BURST := preload("res://resources/techniques/spell_radiant_burst.tres")
const PlayerHitPolicyScript := preload("res://scripts/components/player_hit_policy.gd")
const PlayerLockOnPolicyScript := preload("res://scripts/components/player_lock_on_policy.gd")
const PlayerProfilePolicyScript := preload("res://scripts/components/player_profile_policy.gd")
const PlayerRuntimePolicyScript := preload("res://scripts/components/player_runtime_policy.gd")
const PlayerStatsPolicyScript := preload("res://scripts/components/player_stats_policy.gd")
const RuntimeBoundsPolicyScript := preload("res://scripts/components/runtime_bounds_policy.gd")
const DUST_POOL_NAME: StringName = &"player_dust"
const WORLD_EFFECTS_ANCHOR_NAME: StringName = &"WorldEffects"
const DUST_POOL_SIZE: int = 12


@onready var state_machine: StateMachine = $StateMachine
@onready var model_pivot: Node3D = $ModelPivot
@onready var character_model: Node3D = $ModelPivot/CharacterModel
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

## Facing angle in radians. 0 = right (+X), PI/2 = forward (-Z).
var facing_angle: float = 0.0
## Unit direction vector on XZ plane derived from facing_angle.
var facing_direction: Vector3 = Vector3.RIGHT
## Backward-compatible facing flag (computed from facing_angle).
var facing_right: bool:
	get: return absf(facing_angle) < PI * 0.5
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var dodge_cooldown_timer: float = 0.0
var _parry_timer: float = 0.0
var _is_block_held: bool = false

## Lock-on targeting — currently locked enemy (null = no lock).
var lock_target: Node3D = null
var _lock_reticle: MeshInstance3D = null

## Player index for multiplayer. 0 = keyboard player.
var player_index: int = 0

var health: HealthComponent
var combo_tracker: ComboTracker
var tp_tracker: TPTracker

## Unified intent buffer — survives hitstop, sampled every real-time frame.
var intent_buffer: InputIntentBuffer

## Character definition — loaded from CharacterDef .tres resource.
var character_def: CharacterDef

## XP and leveling tracker.
var xp_tracker: XPTracker

## Equipment slot manager.
var equipment_manager: EquipmentManager

## Active status effects on this player.
var status_effects: StatusEffectTracker

## Currently selected technique index.
var active_technique_index: int = 0

## The spell queued by a button press for the spell state to consume.
var _pending_spell: TechniqueDef = null

## Dust particle timer for run footsteps.
var _dust_run_timer: float = 0.0
var _active_dust_bursts: Array[GPUParticles3D] = []
var _lock_on_policy = PlayerLockOnPolicyScript.new()


func _ready() -> void:
	health = HealthComponent.new(Constants.PLAYER_MAX_HP)
	combo_tracker = ComboTracker.new(Constants.PLAYER_COMBO_MAX_STEPS, Constants.COMBO_INPUT_WINDOW)
	tp_tracker = TPTracker.new()
	intent_buffer = InputIntentBuffer.new()
	xp_tracker = XPTracker.new()
	equipment_manager = EquipmentManager.new()
	status_effects = StatusEffectTracker.new()

	# Sample inputs even when Engine.time_scale == 0 (hitstop).
	process_mode = Node.PROCESS_MODE_ALWAYS

	state_machine.entity = self
	state_machine.add_state(&"idle", PlayerStateIdle.new())
	state_machine.add_state(&"run", PlayerStateRun.new())
	state_machine.add_state(&"jump", PlayerStateJump.new())
	state_machine.add_state(&"fall", PlayerStateFall.new())
	state_machine.add_state(&"land", PlayerStateLand.new())
	state_machine.add_state(&"attack_light", PlayerStateAttackLight.new())
	state_machine.add_state(&"attack_heavy", PlayerStateAttackHeavy.new())
	state_machine.add_state(&"attack_launcher", PlayerStateAttackLauncher.new())
	var AttackAirScript := load("res://scripts/core/player_states/player_state_attack_air.gd")
	state_machine.add_state(&"attack_air", AttackAirScript.new())
	var TechniqueScript := load("res://scripts/core/player_states/player_state_technique.gd")
	state_machine.add_state(&"technique", TechniqueScript.new())
	var SpellScript := load("res://scripts/core/player_states/player_state_spell.gd")
	state_machine.add_state(&"spell", SpellScript.new())
	state_machine.add_state(&"dodge", PlayerStateDodge.new())
	state_machine.add_state(&"hurt", PlayerStateHurt.new())
	state_machine.add_state(&"dead", PlayerStateDead.new())
	state_machine.set_initial_state(&"idle")

	hurtbox.hit_received.connect(_on_hit_received)
	_bridge_eventbus_signals()
	_load_character_from_game_state()
	EventBus.enemy_died.connect(_on_any_enemy_died)
	EventBus.rpg_equipment_changed.connect(_on_equipment_changed)
	# Emit initial state after all nodes are ready so the HUD receives the values.
	call_deferred(&"_emit_initial_state")


func _exit_tree() -> void:
	_reclaim_active_dust_bursts()
	_disconnect_health_signals()


func _physics_process(delta: float) -> void:
	was_on_floor = is_on_floor()
	var runtime := PlayerRuntimePolicyScript.tick_physics_state(
		delta,
		Constants.DELTA_CAP,
		InputManager.is_action_just_pressed_for_player(player_index, &"jump"),
		jump_buffer_timer,
		Constants.PLAYER_JUMP_BUFFER_TIME,
		dodge_cooldown_timer,
		_parry_timer
	)
	var capped := float(runtime.get("delta", delta))
	jump_buffer_timer = float(runtime.get("jump_buffer_timer", jump_buffer_timer))
	dodge_cooldown_timer = float(runtime.get("dodge_cooldown_timer", dodge_cooldown_timer))
	_parry_timer = float(runtime.get("parry_timer", _parry_timer))

	combo_tracker.tick(capped)
	tp_tracker.tick_regen(capped)

	# Tick status effects (burn DOT, freeze, bleed).
	var burn_damage := status_effects.tick(capped)
	if burn_damage > 0.0 and not health.is_dead():
		health.take_damage(burn_damage)
		if health.is_dead():
			state_machine.transition_to(&"dead")


	# Early fall recovery — catch falls before the kill plane at Y < -10.
	var recovery := PlayerRuntimePolicyScript.resolve_fall_recovery(position, velocity, -2.0, 0.1)
	position = recovery.get("position", position) as Vector3
	velocity = recovery.get("velocity", velocity) as Vector3


## Sample action inputs every real-time frame, even during hitstop
## (Engine.time_scale == 0). Records intents into the buffer so they
## survive until the next physics frame where a state can consume them.
func _process(_delta: float) -> void:
	# Rapid-fire: record held attack buttons every frame so combos auto-chain.
	if InputManager.is_action_just_pressed_for_player(player_index, &"attack_light") or InputManager.is_action_pressed_for_player(player_index, &"attack_light"):
		intent_buffer.record(&"attack_light")
	if InputManager.is_action_just_pressed_for_player(player_index, &"attack_heavy") or InputManager.is_action_pressed_for_player(player_index, &"attack_heavy"):
		intent_buffer.record(&"attack_heavy")
	if InputManager.is_action_just_pressed_for_player(player_index, &"dodge"):
		intent_buffer.record(&"dodge")
	if InputManager.is_action_just_pressed_for_player(player_index, &"technique"):
		intent_buffer.record(&"technique")
	var guard_state := PlayerRuntimePolicyScript.resolve_guard_state(
		InputManager.is_action_just_pressed_for_player(player_index, &"block"),
		InputManager.is_action_pressed_for_player(player_index, &"block"),
		Constants.PARRY_WINDOW,
		_parry_timer
	)
	_is_block_held = bool(guard_state.get("block_held", false))
	_parry_timer = float(guard_state.get("parry_timer", _parry_timer))
	# Launcher is triggered by attack_light + move_up — detected at consume time
	# in idle/run states, not as its own input action.

	# Lock-on targeting toggle/cycle.
	if InputManager.is_action_just_pressed_for_player(player_index, &"lock_on"):
		try_lock_on()

	# Button-based spell casting (LB=heal, RT=projectile, LT=AoE).
	if InputManager.is_action_just_pressed_for_player(player_index, &"heal_spell"):
		_pending_spell = _SPELL_HEAL
		intent_buffer.record(&"spell")
	if InputManager.is_action_just_pressed_for_player(player_index, &"projectile_attack"):
		_pending_spell = _SPELL_FIREBALL
		intent_buffer.record(&"spell")
	if InputManager.is_action_just_pressed_for_player(player_index, &"aoe_spell"):
		_pending_spell = _SPELL_BURST
		intent_buffer.record(&"spell")


## Apply gravity with fall multiplier.
func apply_gravity(delta: float) -> void:
	velocity.y = PlayerRuntimePolicyScript.compute_gravity_velocity(
		velocity.y,
		is_on_floor(),
		delta,
		Constants.WORLD_GRAVITY,
		Constants.PLAYER_FALL_GRAVITY_MULTIPLIER,
		Constants.TERMINAL_VELOCITY
	)
	# One-way platforms: only collide when falling so players can jump through from below.
	# Layer 8 (1-indexed) = LAYER_PLATFORM (128). Disabled while rising, enabled while falling.
	set_collision_mask_value(8, PlayerRuntimePolicyScript.should_enable_platform_collision(velocity.y))


## Clamp position to arena/room bounds with soft pushback on all 4 edges.
func clamp_to_bounds() -> void:
	var resolved := RuntimeBoundsPolicyScript.apply_soft_pushback(
		position,
		velocity,
		RuntimeState.get_active_bounds(),
		Constants.BOUNDARY_PUSHBACK_ZONE,
		Constants.BOUNDARY_PUSHBACK_FORCE
	)
	position = resolved.get("position", position) as Vector3
	velocity = resolved.get("velocity", velocity) as Vector3


## Get unified XZ movement input vector from stick/keyboard.
## Movement is projected onto the active camera plane so forward/back input
## tracks what the player sees on screen like an over-the-shoulder game.
func get_movement_input_vector() -> Vector2:
	var raw_input := _get_raw_movement_input_vector()
	if raw_input.length() <= Constants.INPUT_DEADZONE:
		return Vector2.ZERO
	return _get_camera_relative_movement_input(raw_input)


func _get_raw_movement_input_vector() -> Vector2:
	var x := InputManager.get_axis_for_player(player_index, &"move_left", &"move_right")
	var z := InputManager.get_axis_for_player(player_index, &"move_up", &"move_down")
	var input := Vector2(x, z)
	if input.length() > 1.0:
		input = input.normalized()
	return input


func _get_camera_relative_movement_input(raw_input: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(camera):
		return raw_input

	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	if camera_forward.length_squared() <= 0.001:
		return raw_input
	camera_forward = camera_forward.normalized()

	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	if camera_right.length_squared() <= 0.001:
		camera_right = Vector3(camera_forward.z, 0.0, -camera_forward.x)
	else:
		camera_right = camera_right.normalized()

	var world_input := (camera_right * raw_input.x) + (camera_forward * -raw_input.y)
	if world_input.length_squared() <= 0.001:
		return Vector2.ZERO
	world_input = world_input.normalized()
	return Vector2(world_input.x, world_input.z)


## Backward-compatible single-axis movement input.
func get_movement_input() -> float:
	return get_movement_input_vector().x


## Update facing angle and direction from 2D input. Smoothly rotates model.
## When lock_target is set, facing auto-tracks the locked enemy instead.
func update_facing_from_input(input: Vector2, delta: float) -> void:
	if lock_target and is_instance_valid(lock_target):
		var dir := lock_target.global_position - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.001:
			var target_angle := atan2(-dir.z, dir.x)
			var weight := clampf(Constants.LOCK_ON_FACING_LERP_SPEED * delta, 0.0, 1.0)
			facing_angle = lerp_angle(facing_angle, target_angle, weight)
			if not is_finite(facing_angle):
				facing_angle = target_angle
			facing_direction = Vector3(cos(facing_angle), 0.0, -sin(facing_angle))
			model_pivot.rotation.y = facing_angle
		return
	if input.length_squared() < Constants.INPUT_DEADZONE * Constants.INPUT_DEADZONE:
		return
	var target_angle := atan2(-input.y, input.x)
	facing_angle = lerp_angle(facing_angle, target_angle, Constants.PLAYER_FACING_LERP_SPEED * delta)
	facing_direction = Vector3(cos(facing_angle), 0.0, -sin(facing_angle))
	model_pivot.rotation.y = facing_angle


## Legacy facing update (deprecated — use update_facing_from_input).
func update_facing(x_input: float) -> void:
	update_facing_from_input(Vector2(x_input, 0.0), 0.1)


## Consume the jump buffer after a successful jump.
func consume_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


## Check if dodge is off cooldown.
func can_dodge() -> bool:
	return dodge_cooldown_timer <= 0.0


## Whether block is currently held.
func is_blocking() -> bool:
	return _is_block_held


## Whether parry timing window is currently active.
func is_parry_active() -> bool:
	return _is_block_held and _parry_timer > 0.0


## Start the dodge cooldown timer.
func start_dodge_cooldown() -> void:
	dodge_cooldown_timer = Constants.DODGE_COOLDOWN


## Spawn a small burst of dust particles at the player's feet.
func spawn_dust(amount: int) -> void:
	if not is_inside_tree():
		return
	_ensure_dust_pool()
	var burst := ObjectPool.get_instance(DUST_POOL_NAME) as GPUParticles3D
	var pooled := true
	if burst == null:
		var fallback_scene := _create_dust_scene()
		burst = fallback_scene.instantiate() as GPUParticles3D
		pooled = false
	if burst == null:
		return
	if not _mount_world_effect(burst):
		if pooled:
			ObjectPool.return_instance(burst)
		else:
			burst.queue_free()
		return
	burst.amount = amount
	burst.global_position = global_position
	burst.emitting = false
	burst.restart()
	burst.emitting = true
	_track_dust_burst(burst)
	burst.finished.connect(func() -> void:
		_release_dust_burst(burst, pooled)
	, CONNECT_ONE_SHOT)


## Tick dust timer during run state. Spawns puffs at interval.
func tick_run_dust(delta: float) -> void:
	if not is_on_floor():
		return
	_dust_run_timer -= delta
	if _dust_run_timer <= 0.0:
		_dust_run_timer = Constants.DUST_RUN_INTERVAL
		spawn_dust(Constants.DUST_RUN_AMOUNT)
		AudioManager.play_sfx_variant(&"footstep", Constants.SFX_VOL_FOOTSTEP)


## Flash the mesh a solid color for attack feedback.
func flash_mesh(color: Color) -> void:
	if character_model:
		character_model.flash(color)


## Restore the mesh to its original material.
func restore_mesh() -> void:
	if character_model:
		character_model.restore()


## Play a named animation on the character model.
func play_animation(anim_name: StringName, speed_scale: float = 1.0) -> void:
	if character_model:
		character_model.play_animation(anim_name, speed_scale)


## Get the duration of a named animation in seconds.
func get_animation_duration(anim_name: StringName) -> float:
	if character_model:
		return character_model.get_animation_duration(anim_name)
	return 0.0


func _on_hit_received(attack_data: AttackDef, attacker: Node3D) -> void:
	# Ignore hits while already dead or if attacker was freed.
	if health.is_dead():
		return
	if not is_instance_valid(attacker):
		return
	if GameState.god_mode:
		return

	var damage_context := PlayerHitPolicyScript.build_damage_context(
		get_derived_stats(),
		status_effects.get_damage_taken_multiplier()
	)
	var resolution := PlayerHitPolicyScript.resolve_hit_response(
		attack_data,
		attacker.global_position,
		global_position,
		facing_direction,
		is_parry_active(),
		is_blocking(),
		Constants.BLOCK_DAMAGE_REDUCTION,
		0.25,
		Constants.KNOCKBACK_Z_DAMPEN
	)
	var outcome := resolution.get("outcome", &"hit") as StringName

	if outcome == &"parry":
		_parry_timer = 0.0
		EventBus.combat_parry.emit(self, attacker)
		tp_tracker.add_tp(Constants.TP_PARRY_BONUS)
		if is_instance_valid(attacker) and attacker.has_method("apply_parry_stun"):
			attacker.apply_parry_stun(Constants.PARRY_STUN_DURATION, self)
		return

	var blocked := bool(resolution.get("blocked", false))
	if blocked:
		EventBus.combat_block.emit(self)
	var resolved_attack := resolution.get("resolved_attack", attack_data) as AttackDef

	CombatSystem.process_hit(
		health, resolved_attack, attacker, self,
		float(damage_context.get("defense", 0.0)),
		0,
		0.0,
		1.0,
		float(damage_context.get("damage_taken_multiplier", 1.0))
	)

	# Apply elemental status effects from the incoming attack.
	CombatSystem.apply_status_if_applicable(resolved_attack, self, status_effects)

	# Apply knockback — primarily X-axis, Z dampened for belt-scroller feel.
	velocity = resolution.get("knockback_velocity", Vector3.ZERO) as Vector3

	if health.is_dead():
		state_machine.transition_to(&"dead")
	elif blocked:
		# Guarded hits don't force hurt state; keep control responsive.
		flash_mesh(Color(0.7, 0.9, 1.0))
		get_tree().create_timer(Constants.BLOCK_FLASH_DURATION).timeout.connect(restore_mesh)
	else:
		state_machine.transition_to(&"hurt")


## Bridge component signals to the global EventBus.
func _bridge_eventbus_signals() -> void:
	_connect_health_signals()
	combo_tracker.combo_advanced.connect(func(step: int) -> void:
		EventBus.combat_combo_step.emit(self, step)
	)
	combo_tracker.combo_dropped.connect(func() -> void:
		EventBus.combat_combo_dropped.emit(self)
	)
	combo_tracker.combo_finished.connect(func() -> void:
		tp_tracker.add_tp(Constants.TP_COMBO_FINISHER_BONUS)
	)
	tp_tracker.tp_changed.connect(func(new_tp: float, max_tp: float) -> void:
		_sync_live_state_to_game_state()
		EventBus.player_tp_changed.emit(player_index, new_tp, max_tp)
	)
	xp_tracker.level_up.connect(func(new_level: int, stat_points: int) -> void:
		EventBus.rpg_level_up.emit(player_index, new_level)
		var char_id := _get_active_character_id()
		var data := GameState.ensure_character_record(char_id)
		if data.is_empty():
			return
		var updated := PlayerProfilePolicyScript.build_level_up_record(
			data,
			char_id,
			new_level,
			stat_points,
			Constants.CHARACTER_STAT_GROWTH,
			Constants.DEFAULT_STAT_GROWTH
		)
		GameState.character_data[char_id] = updated
		var stat_points_available := int(updated.get("stat_points_available", 0))
		# Restore HP to full on level-up.
		health.heal(health.get_max_hp())
		_sync_live_state_to_game_state(stat_points_available)
		EventBus.player_health_changed.emit(player_index, health.get_current_hp(), health.get_max_hp())
		EventBus.rpg_stat_points_available.emit(player_index, stat_points_available)
	)
	xp_tracker.xp_gained.connect(func(amount: int, _total: int) -> void:
		_sync_live_state_to_game_state()
		EventBus.rpg_xp_gained.emit(player_index, amount)
	)
	status_effects.effect_expired.connect(func(effect_type: StringName) -> void:
		EventBus.rpg_status_effect_expired.emit(self, effect_type)
	)
	EventBus.enemy_died.connect(_on_enemy_kill_heal)


## Configure the player with a CharacterDef resource.
func configure(def: CharacterDef) -> void:
	character_def = def
	active_technique_index = 0


## Compute derived stats (base + equipment + skill bonuses + active buffs).
func get_derived_stats() -> Dictionary:
	var char_id := _get_active_character_id()
	var fallback_base_stats := {}
	if character_def:
		fallback_base_stats = character_def.base_stats
	return PlayerStatsPolicyScript.build_derived_stats(
		PlayerStatsPolicyScript.resolve_base_stats(char_id, GameState.character_data, fallback_base_stats),
		equipment_manager.get_total_bonuses(),
		status_effects.get_defense_bonus()
	)


## Get the currently selected technique, or null if none available.
func get_active_technique() -> TechniqueDef:
	if not character_def:
		return null
	if character_def.techniques.is_empty():
		return null
	active_technique_index = clampi(active_technique_index, 0, character_def.techniques.size() - 1)
	return character_def.techniques[active_technique_index]


## Cycle to the next available technique.
func cycle_technique() -> void:
	if not character_def or character_def.techniques.is_empty():
		return
	active_technique_index = (active_technique_index + 1) % character_def.techniques.size()


## Load CharacterDef and restore RPG state from GameState on ready.
func _load_character_from_game_state() -> void:
	var char_id := _get_active_character_id()
	var data := GameState.ensure_character_record(char_id)
	var def_path := String(Constants.CHARACTER_DEFS.get(char_id, ""))
	if not def_path.is_empty():
		var def := load(def_path) as CharacterDef
		if def:
			configure(def)
			if character_model:
				character_model.reload_model(def)
	_sync_equipment_manager_from_game_state()
	if not data.is_empty():
		var snapshot := PlayerProfilePolicyScript.build_restore_snapshot(
			char_id,
			data,
			Constants.CHARACTER_DEFS,
			get_derived_stats(),
			Constants.PLAYER_MAX_HP,
			Constants.TP_MAX,
			Constants.STAT_HP_SCALE
		)
		xp_tracker.set_state(int(snapshot.get("xp", 0)), int(snapshot.get("level", 1)))
		tp_tracker.set_current_tp(float(snapshot.get("tp", Constants.TP_MAX)))
		_replace_health_component(
			float(snapshot.get("max_hp", Constants.PLAYER_MAX_HP)),
			float(snapshot.get("saved_hp", Constants.PLAYER_MAX_HP))
		)
	_sync_live_state_to_game_state()


## Emit initial HP/TP values so the HUD picks them up after connecting signals.
func _emit_initial_state() -> void:
	EventBus.player_health_changed.emit(player_index, health.get_current_hp(), health.get_max_hp())
	EventBus.player_tp_changed.emit(player_index, tp_tracker.get_current_tp(), tp_tracker.get_max_tp())


func _connect_health_signals() -> void:
	if health == null:
		return
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	if not health.died.is_connected(_on_health_died):
		health.died.connect(_on_health_died)


func _disconnect_health_signals() -> void:
	if health == null:
		return
	if health.health_changed.is_connected(_on_health_changed):
		health.health_changed.disconnect(_on_health_changed)
	if health.died.is_connected(_on_health_died):
		health.died.disconnect(_on_health_died)


func _replace_health_component(max_hp: float, current_hp: float = -1.0) -> void:
	_disconnect_health_signals()
	var target_hp := max_hp if current_hp < 0.0 else clampf(current_hp, 0.0, max_hp)
	var replacement := HealthComponent.new(max_hp)
	var missing_hp := max_hp - target_hp
	if missing_hp > 0.0:
		replacement.take_damage(missing_hp)
	health = replacement
	_connect_health_signals()


func _on_health_changed(new_hp: float, max_hp: float) -> void:
	_sync_live_state_to_game_state()
	EventBus.player_health_changed.emit(player_index, new_hp, max_hp)


func _on_health_died() -> void:
	_sync_live_state_to_game_state()
	EventBus.player_died.emit(player_index)


func _on_enemy_kill_heal(_enemy: Node, _type: StringName, _pos: Vector3) -> void:
	if health != null and not health.is_dead():
		health.heal(Constants.PLAYER_KILL_HEAL)


func _ensure_dust_pool() -> void:
	if ObjectPool.get_total_count(DUST_POOL_NAME) > 0:
		return
	ObjectPool.warm_pool(_create_dust_scene(), DUST_POOL_SIZE, DUST_POOL_NAME)


func _create_dust_scene() -> PackedScene:
	var burst := GPUParticles3D.new()
	burst.name = "DustBurst"
	burst.amount = Constants.DUST_RUN_AMOUNT
	burst.lifetime = 0.35
	burst.one_shot = true
	burst.explosiveness = 1.0

	var process_mat := ParticleProcessMaterial.new()
	process_mat.spread = 60.0
	process_mat.initial_velocity_min = 1.0
	process_mat.initial_velocity_max = 2.5
	process_mat.gravity = Vector3(0, -2, 0)
	process_mat.scale_min = 0.04
	process_mat.scale_max = 0.12
	process_mat.color = Color(0.7, 0.65, 0.5, 0.6)
	process_mat.direction = Vector3(0, 1, 0)
	burst.process_material = process_mat

	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.7, 0.65, 0.5, 0.6)
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.material = draw_mat
	burst.draw_pass_1 = mesh

	var scene := PackedScene.new()
	scene.pack(burst)
	burst.free()
	return scene


func _mount_world_effect(effect: Node3D) -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return false
	var anchor := scene_root.get_node_or_null(String(WORLD_EFFECTS_ANCHOR_NAME)) as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = String(WORLD_EFFECTS_ANCHOR_NAME)
		scene_root.add_child(anchor)
	if effect.get_parent() != anchor:
		effect.reparent(anchor)
	return true


func _track_dust_burst(burst: GPUParticles3D) -> void:
	if burst not in _active_dust_bursts:
		_active_dust_bursts.append(burst)


func _release_dust_burst(burst: GPUParticles3D, pooled: bool) -> void:
	_active_dust_bursts.erase(burst)
	if not is_instance_valid(burst):
		return
	burst.emitting = false
	if pooled:
		if burst.get_parent() != ObjectPool:
			burst.reparent(ObjectPool)
		ObjectPool.return_instance(burst)
	else:
		burst.queue_free()


func _reclaim_active_dust_bursts() -> void:
	for burst in _active_dust_bursts.duplicate():
		_release_dust_burst(burst, burst.has_meta(&"pool_key"))
	_active_dust_bursts.clear()


func _sync_live_state_to_game_state(stat_points_available: int = -1) -> void:
	var char_id := _get_active_character_id()
	var payload := PlayerProfilePolicyScript.build_runtime_sync_payload(
		char_id,
		health.get_current_hp(),
		health.get_max_hp(),
		tp_tracker.get_current_tp(),
		xp_tracker.get_xp(),
		xp_tracker.get_level(),
		tp_tracker.get_max_tp(),
		stat_points_available
	)
	GameState.sync_character_runtime_payload(payload)


func _sync_equipment_manager_from_game_state() -> void:
	var char_id := _get_active_character_id()
	equipment_manager.set_state(GameState.get_equipped_item_state(char_id))


func _refresh_max_hp_from_stats() -> void:
	if health == null:
		return
	var refresh := PlayerStatsPolicyScript.build_health_refresh(
		health.get_current_hp(),
		get_derived_stats(),
		Constants.PLAYER_MAX_HP,
		Constants.STAT_HP_SCALE
	)
	health.set_max_hp(float(refresh.get("max_hp", Constants.PLAYER_MAX_HP)))
	_sync_live_state_to_game_state()
	EventBus.player_health_changed.emit(player_index, health.get_current_hp(), health.get_max_hp())


func _on_equipment_changed(changed_player_index: int, _slot: StringName, _item_id: StringName) -> void:
	if changed_player_index != player_index:
		return
	_sync_equipment_manager_from_game_state()
	_refresh_max_hp_from_stats()


## Get the active character id from GameState.
func _get_active_character_id() -> StringName:
	return PlayerProfilePolicyScript.resolve_active_character_id(GameState.active_party, player_index)


## Scale knockback down near room edges to reduce out-of-bounds pushes.
func _apply_edge_safe_knockback(raw_knockback_x: float) -> float:
	return RuntimeBoundsPolicyScript.scale_edge_knockback_x(
		raw_knockback_x,
		position.x,
		RuntimeState.get_active_bounds(),
		Constants.PLAYER_EDGE_KNOCKBACK_SAFE_MARGIN,
		Constants.PLAYER_EDGE_KNOCKBACK_MIN_SCALE
	)


## Get the spell queued by a button press. Clears after retrieval.
func get_pending_spell() -> TechniqueDef:
	var spell := _pending_spell
	_pending_spell = null
	return spell


# ---------- Lock-On Targeting ----------


## Toggle lock-on: if unlocked → lock nearest; if locked → cycle to next.
func try_lock_on() -> void:
	if lock_target and is_instance_valid(lock_target):
		_cycle_lock_target()
	else:
		var nearest := _find_nearest_enemy()
		if nearest:
			_set_lock_target(nearest)


## Find the closest alive enemy within range.
func _find_nearest_enemy() -> Node3D:
	return _lock_on_policy.select_nearest(
		global_position,
		get_tree().get_nodes_in_group(&"enemies"),
		Constants.LOCK_ON_MAX_RANGE * Constants.LOCK_ON_MAX_RANGE
	)


## Cycle to the next enemy by angular offset from current target.
func _cycle_lock_target() -> void:
	var next_target: Node3D = _lock_on_policy.select_next(
		global_position,
		lock_target,
		get_tree().get_nodes_in_group(&"enemies"),
		Constants.LOCK_ON_MAX_RANGE * Constants.LOCK_ON_MAX_RANGE
	)
	if next_target == null:
		# Only one enemy or none — release lock.
		_clear_lock_target()
		return
	_set_lock_target(next_target)


## Set a new lock target and create the reticle visual.
func _set_lock_target(target: Node3D) -> void:
	lock_target = target
	_destroy_reticle()
	_create_reticle()
	EventBus.combat_lock_on_changed.emit(self, lock_target)


## Clear the lock target and remove the reticle.
func _clear_lock_target() -> void:
	lock_target = null
	_destroy_reticle()
	EventBus.combat_lock_on_changed.emit(self, null)


## Handle an enemy dying — if it was our lock target, auto-switch or unlock.
func _on_any_enemy_died(enemy: Node, _type: StringName, _pos: Vector3) -> void:
	if enemy == lock_target:
		var next := _find_nearest_enemy()
		if next and next != enemy:
			_set_lock_target(next)
		else:
			_clear_lock_target()


## Create a gold ring reticle under the locked enemy.
func _create_reticle() -> void:
	if not lock_target or not is_instance_valid(lock_target):
		return
	_lock_reticle = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.8
	torus.rings = 16
	torus.ring_segments = 16
	_lock_reticle.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 1
	_lock_reticle.material_override = mat
	_lock_reticle.rotation.x = -PI * 0.5
	_lock_reticle.position.y = 0.1
	lock_target.add_child(_lock_reticle)


## Remove the reticle node if it exists.
func _destroy_reticle() -> void:
	if _lock_reticle and is_instance_valid(_lock_reticle):
		_lock_reticle.queue_free()
	_lock_reticle = null
