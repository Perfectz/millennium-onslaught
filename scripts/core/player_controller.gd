## Player CharacterBody3D — owns state machine, health, combo, hitbox/hurtbox.
## Bridges component signals to EventBus for cross-system communication.
class_name PlayerController
extends CharacterBody3D


const _SPELL_FIREBALL := preload("res://resources/techniques/spell_fireball.tres")
const _SPELL_HEAL := preload("res://resources/techniques/spell_heal.tres")
const _SPELL_BURST := preload("res://resources/techniques/spell_radiant_burst.tres")


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
	# Emit initial state after all nodes are ready so the HUD receives the values.
	call_deferred(&"_emit_initial_state")


func _physics_process(delta: float) -> void:
	var capped := minf(delta, Constants.DELTA_CAP)
	was_on_floor = is_on_floor()

	if InputManager.is_action_just_pressed_for_player(player_index, &"jump"):
		jump_buffer_timer = Constants.PLAYER_JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= capped

	combo_tracker.tick(capped)
	tp_tracker.tick_regen(capped)

	# Tick status effects (burn DOT, freeze, bleed).
	var burn_damage := status_effects.tick(capped)
	if burn_damage > 0.0 and not health.is_dead():
		health.take_damage(burn_damage)
		if health.is_dead():
			state_machine.transition_to(&"dead")

	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= capped
	if _parry_timer > 0.0:
		_parry_timer = maxf(_parry_timer - capped, 0.0)

	# Early fall recovery — catch falls before the kill plane at Y < -10.
	if position.y < -2.0:
		position.y = 0.1
		velocity.y = 0.0


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
	if InputManager.is_action_just_pressed_for_player(player_index, &"block"):
		_is_block_held = true
		_parry_timer = Constants.PARRY_WINDOW
	else:
		_is_block_held = InputManager.is_action_pressed_for_player(player_index, &"block")
		if not _is_block_held:
			_parry_timer = 0.0
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
	if not is_on_floor():
		var gravity := Constants.WORLD_GRAVITY
		if velocity.y < 0.0:
			gravity *= Constants.PLAYER_FALL_GRAVITY_MULTIPLIER
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -Constants.TERMINAL_VELOCITY)
	_update_platform_collision()


## One-way platforms: only collide when falling so players can jump through from below.
## Layer 8 (1-indexed) = LAYER_PLATFORM (128). Disabled while rising, enabled while falling.
func _update_platform_collision() -> void:
	set_collision_mask_value(8, velocity.y <= 0.0)


## Clamp position to arena/room bounds with soft pushback on all 4 edges.
func clamp_to_bounds() -> void:
	var min_x := -100.0
	var max_x := 100.0
	var min_z := -100.0
	var max_z := 100.0
	if GameState.room_bounds_active:
		min_x = GameState.room_bounds_min_x
		max_x = GameState.room_bounds_max_x
		min_z = GameState.room_bounds_min_z
		max_z = GameState.room_bounds_max_z
	elif GameState.encounter_active:
		min_x = GameState.arena_lock_min_x
		max_x = GameState.arena_lock_max_x
		min_z = GameState.arena_lock_min_z
		max_z = GameState.arena_lock_max_z
	# Soft pushback on all 4 edges.
	var zone := Constants.BOUNDARY_PUSHBACK_ZONE
	var force := Constants.BOUNDARY_PUSHBACK_FORCE
	if position.x < min_x + zone:
		var t := 1.0 - clampf((position.x - min_x) / zone, 0.0, 1.0)
		velocity.x = maxf(velocity.x, t * force)
	elif position.x > max_x - zone:
		var t := 1.0 - clampf((max_x - position.x) / zone, 0.0, 1.0)
		velocity.x = minf(velocity.x, -t * force)
	if position.z < min_z + zone:
		var t := 1.0 - clampf((position.z - min_z) / zone, 0.0, 1.0)
		velocity.z = maxf(velocity.z, t * force)
	elif position.z > max_z - zone:
		var t := 1.0 - clampf((max_z - position.z) / zone, 0.0, 1.0)
		velocity.z = minf(velocity.z, -t * force)
	# Hard clamp as fallback.
	position.x = clampf(position.x, min_x, max_x)
	position.z = clampf(position.z, min_z, max_z)


## Get unified XZ movement input vector from stick/keyboard.
func get_movement_input_vector() -> Vector2:
	var x := InputManager.get_axis_for_player(player_index, &"move_left", &"move_right")
	var z := InputManager.get_axis_for_player(player_index, &"move_up", &"move_down")
	var input := Vector2(x, z)
	if input.length() > 1.0:
		input = input.normalized()
	return input


## Backward-compatible single-axis movement input.
func get_movement_input() -> float:
	return InputManager.get_axis_for_player(player_index, &"move_left", &"move_right")


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
	var burst := GPUParticles3D.new()
	burst.amount = amount
	burst.lifetime = 0.35
	burst.one_shot = true
	burst.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.spread = 60.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.5
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = Color(0.7, 0.65, 0.5, 0.6)
	mat.direction = Vector3(0, 1, 0)
	burst.process_material = mat

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

	get_tree().root.add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	burst.finished.connect(burst.queue_free)


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

	# Calculate derived defense and damage-taken multiplier from RPG stats.
	var stats := get_derived_stats()
	var defense := StatCalculator.defense_value(StatCalculator.get_stat(stats, &"defense"))
	var dmg_taken_mult := status_effects.get_damage_taken_multiplier()
	var blocked := false
	var resolved_attack := attack_data

	if is_parry_active():
		_parry_timer = 0.0
		EventBus.combat_parry.emit(self, attacker)
		tp_tracker.add_tp(Constants.TP_PARRY_BONUS)
		if is_instance_valid(attacker) and attacker.has_method("apply_parry_stun"):
			attacker.apply_parry_stun(Constants.PARRY_STUN_DURATION, self)
		return

	if is_blocking():
		blocked = true
		EventBus.combat_block.emit(self)
		resolved_attack = attack_data.duplicate()
		var blocked_scale := maxf(1.0 - Constants.BLOCK_DAMAGE_REDUCTION, 0.0)
		resolved_attack.damage_multiplier *= blocked_scale
		resolved_attack.knockback_force *= 0.25

	CombatSystem.process_hit(
		health, resolved_attack, attacker, self,
		defense, 0, 0.0, 1.0, dmg_taken_mult
	)

	# Apply elemental status effects from the incoming attack.
	CombatSystem.apply_status_if_applicable(resolved_attack, self, status_effects)

	# Apply knockback — primarily X-axis, Z dampened for belt-scroller feel.
	var push_dir := (global_position - attacker.global_position)
	push_dir.y = 0.0
	if push_dir.length_squared() < 0.001:
		push_dir = -facing_direction
	push_dir = push_dir.normalized()
	var kb_force := resolved_attack.knockback_force
	velocity.x = push_dir.x * kb_force
	velocity.z = push_dir.z * kb_force * Constants.KNOCKBACK_Z_DAMPEN

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
	health.health_changed.connect(func(new_hp: float, max_hp: float) -> void:
		EventBus.player_health_changed.emit(player_index, new_hp, max_hp)
	)
	health.died.connect(func() -> void:
		EventBus.player_died.emit(player_index)
	)
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
		EventBus.player_tp_changed.emit(player_index, new_tp, max_tp)
	)
	xp_tracker.level_up.connect(func(new_level: int, stat_points: int) -> void:
		EventBus.rpg_level_up.emit(player_index, new_level)
		var char_id := _get_active_character_id()
		if char_id in GameState.character_data:
			var data: Dictionary = GameState.character_data[char_id]
			data["level"] = new_level
			data["stat_points_available"] = data.get("stat_points_available", 0) + stat_points
			# Apply automatic base stat growth.
			var growth: Dictionary = Constants.CHARACTER_STAT_GROWTH.get(char_id, Constants.DEFAULT_STAT_GROWTH)
			var stats: Dictionary = data.get("stats", {})
			for stat_key: StringName in growth:
				stats[stat_key] = stats.get(stat_key, 0) + growth[stat_key]
			data["stats"] = stats
			# Restore HP to full on level-up.
			health.heal(health.get_max_hp())
			EventBus.player_health_changed.emit(player_index, health.get_current_hp(), health.get_max_hp())
			EventBus.rpg_stat_points_available.emit(player_index, data["stat_points_available"])
	)
	xp_tracker.xp_gained.connect(func(amount: int, _total: int) -> void:
		EventBus.rpg_xp_gained.emit(player_index, amount)
	)
	status_effects.effect_expired.connect(func(effect_type: StringName) -> void:
		EventBus.rpg_status_effect_expired.emit(self, effect_type)
	)
	EventBus.enemy_died.connect(func(_enemy: Node, _type: StringName, _pos: Vector3) -> void:
		if not health.is_dead():
			health.heal(Constants.PLAYER_KILL_HEAL)
	)


## Configure the player with a CharacterDef resource.
func configure(def: CharacterDef) -> void:
	character_def = def
	active_technique_index = 0


## Compute derived stats (base + equipment + skill bonuses + active buffs).
func get_derived_stats() -> Dictionary:
	var char_id := _get_active_character_id()
	var base_stats: Dictionary = {}
	if char_id in GameState.character_data:
		base_stats = GameState.character_data[char_id].get("stats", {})
	elif character_def:
		base_stats = character_def.base_stats.duplicate()
	else:
		base_stats = {"strength": 5, "magic": 5, "defense": 5, "agility": 5}
	var equip_bonuses := equipment_manager.get_total_bonuses()
	var derived := StatCalculator.calculate_derived(base_stats, equip_bonuses, {})
	# Apply temporary defense buff from Barrier spell.
	var def_bonus := status_effects.get_defense_bonus()
	if def_bonus > 0.0:
		derived[&"defense"] = derived.get(&"defense", 0) + int(def_bonus)
	return derived


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
	# Load CharacterDef from Constants.CHARACTER_DEFS paths.
	if char_id in Constants.CHARACTER_DEFS:
		var def_path: String = Constants.CHARACTER_DEFS[char_id]
		var def := load(def_path) as CharacterDef
		if def:
			configure(def)
			if character_model:
				character_model.reload_model(def)
	# Restore XP/level from save data.
	if char_id in GameState.character_data:
		var data: Dictionary = GameState.character_data[char_id]
		xp_tracker.set_state(data.get("xp", 0), data.get("level", 1))
		# Restore TP from saved value.
		tp_tracker.set_current_tp(data.get("tp", Constants.TP_MAX))
		# Restore HP from saved value.
		var saved_hp: float = data.get("hp", Constants.PLAYER_MAX_HP)
		var stat_hp_bonus := StatCalculator.get_stat(get_derived_stats(), &"defense") * Constants.STAT_HP_SCALE
		var max_hp := Constants.PLAYER_MAX_HP + stat_hp_bonus
		health = HealthComponent.new(max_hp)
		health.take_damage(max_hp - saved_hp)
		# Re-bridge health signals after replacing the component.
		health.health_changed.connect(func(new_hp: float, hp_max: float) -> void:
			EventBus.player_health_changed.emit(player_index, new_hp, hp_max)
		)
		health.died.connect(func() -> void:
			EventBus.player_died.emit(player_index)
		)


## Emit initial HP/TP values so the HUD picks them up after connecting signals.
func _emit_initial_state() -> void:
	EventBus.player_health_changed.emit(player_index, health.get_current_hp(), health.get_max_hp())
	EventBus.player_tp_changed.emit(player_index, tp_tracker.get_current_tp(), tp_tracker.get_max_tp())


## Get the active character id from GameState.
func _get_active_character_id() -> StringName:
	if GameState.active_party.is_empty():
		return &"alys"
	return GameState.active_party[mini(player_index, GameState.active_party.size() - 1)]


## Scale knockback down near room edges to reduce out-of-bounds pushes.
func _apply_edge_safe_knockback(raw_knockback_x: float) -> float:
	if not GameState.room_bounds_active:
		return raw_knockback_x
	if is_zero_approx(raw_knockback_x):
		return 0.0

	var distance_to_edge := 0.0
	if raw_knockback_x < 0.0:
		distance_to_edge = position.x - GameState.room_bounds_min_x
	else:
		distance_to_edge = GameState.room_bounds_max_x - position.x

	var safe_margin := maxf(Constants.PLAYER_EDGE_KNOCKBACK_SAFE_MARGIN, 0.001)
	var edge_scale := clampf(
		distance_to_edge / safe_margin,
		Constants.PLAYER_EDGE_KNOCKBACK_MIN_SCALE,
		1.0
	)
	return raw_knockback_x * edge_scale


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
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	var best: Node3D = null
	var best_dist := Constants.LOCK_ON_MAX_RANGE * Constants.LOCK_ON_MAX_RANGE
	for e in enemies:
		if not e is CharacterBody3D or not is_instance_valid(e):
			continue
		if "health" in e and e.health and e.health.is_dead():
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


## Cycle to the next enemy by angular offset from current target.
func _cycle_lock_target() -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	var candidates: Array[Node3D] = []
	for e in enemies:
		if not e is CharacterBody3D or not is_instance_valid(e):
			continue
		if "health" in e and e.health and e.health.is_dead():
			continue
		if e != lock_target:
			candidates.append(e)
	if candidates.is_empty():
		# Only one enemy or none — release lock.
		_clear_lock_target()
		return
	# Sort by distance and pick the closest one that isn't the current target.
	var origin := global_position
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	_set_lock_target(candidates[0])


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


