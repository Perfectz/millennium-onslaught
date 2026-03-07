## Enemy CharacterBody3D — data-driven via EnemyDef.
## Owns state machine, health, hitbox/hurtbox, target tracking, juggle state.
class_name EnemyController
extends CharacterBody3D

const RuntimeBoundsPolicyScript := preload("res://scripts/components/runtime_bounds_policy.gd")


@onready var state_machine: StateMachine = $StateMachine
@onready var model_pivot: Node3D = $ModelPivot
@onready var enemy_model: Node3D = $ModelPivot/EnemyModel
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

## The enemy definition resource driving this enemy's stats and behavior.
@export var enemy_def: EnemyDef = null

var health: HealthComponent
var juggle: JuggleTracker
var status_effects: StatusEffectTracker
var target: Node3D = null
var facing_angle: float = 0.0
var facing_direction: Vector3 = Vector3.RIGHT
var facing_right: bool:
	get: return absf(facing_angle) < PI * 0.5

## Shield enemy: hits absorbed before stagger.
var _block_hits_remaining: int = 0
var _is_blocking: bool = false
var _stagger_override_duration: float = 0.0
var _original_material: Material = null
var _health_bar_fill: MeshInstance3D = null

## Enemy type identifier (from EnemyDef).
var enemy_type: StringName = &"rusher"

## Attack cooldown for token system.
var attack_cooldown_timer: float = 0.0

## Hit lag freeze timer — brief pause on the enemy model for impact feel.
var _hit_lag_timer: float = 0.0
var _hit_lag_frozen: bool = false

## Boss phase tracking.
var boss_phase: int = 1
var speed_multiplier: float = 1.0
var boss_attack_override: AttackDef = null


func _ready() -> void:
	var hp := Constants.ENEMY_RUSHER_HP
	var behavior := &"rusher"

	if enemy_def:
		hp = enemy_def.base_hp
		behavior = enemy_def.behavior
		enemy_type = enemy_def.enemy_type
		_block_hits_remaining = Constants.ENEMY_SHIELD_STAGGER_HITS if enemy_def.can_block else 0
		# Apply mesh color from definition.
		_apply_mesh_color(enemy_def.mesh_color)

	health = HealthComponent.new(hp)
	juggle = JuggleTracker.new(Constants.MAX_JUGGLE_COUNT)
	status_effects = StatusEffectTracker.new()

	state_machine.entity = self
	state_machine.add_state(&"idle", EnemyStateIdle.new())
	state_machine.add_state(&"chase", EnemyStateChase.new())
	state_machine.add_state(&"attack", EnemyStateAttack.new())
	state_machine.add_state(&"hurt", EnemyStateHurt.new())
	state_machine.add_state(&"dead", EnemyStateDead.new())

	# Register ALL behavior states so configure() can switch to any behavior.
	state_machine.add_state(&"retreat", EnemyStateRetreat.new())
	state_machine.add_state(&"shoot", EnemyStateShoot.new())
	state_machine.add_state(&"block", EnemyStateBlock.new())
	state_machine.add_state(&"stagger", EnemyStateStagger.new())
	state_machine.add_state(&"boss_phase_check", EnemyStateBossPhaseCheck.new())
	state_machine.add_state(&"dormant", EnemyStateDormant.new())

	state_machine.set_initial_state(&"idle")
	hurtbox.hit_received.connect(_on_hit_received)
	_create_health_bar()
	add_to_group("enemies")
	EventBus.enemy_spawned.emit(self, enemy_type)


func _physics_process(delta: float) -> void:
	# Hit lag: brief freeze on this enemy for impact feel.
	if _hit_lag_frozen:
		_hit_lag_timer -= delta
		if _hit_lag_timer <= 0.0:
			_hit_lag_frozen = false
		return

	var capped := minf(delta, Constants.DELTA_CAP)
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= capped
	# Tick status effects (burn DOT).
	var burn_damage := status_effects.tick(capped)
	if burn_damage > 0.0 and not health.is_dead():
		health.take_damage(burn_damage)
		if health.is_dead():
			state_machine.transition_to(&"dead")
	_update_health_bar()
	clamp_to_bounds()


## Clamp enemy position to active arena/room bounds (X + Z).
func clamp_to_bounds() -> void:
	position = RuntimeBoundsPolicyScript.clamp_position(position, RuntimeState.get_active_bounds())


func set_target(new_target: Node3D) -> void:
	target = new_target


func update_facing_toward_target() -> void:
	if target == null or not is_instance_valid(target) or not is_inside_tree():
		return
	var dir := target.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		facing_angle = atan2(-dir.z, dir.x)
		facing_direction = dir.normalized()
		model_pivot.rotation.y = facing_angle


## Euclidean XZ distance to target (isometric — both axes matter equally).
func get_horizontal_distance_to_target() -> float:
	if target == null or not is_instance_valid(target) or not is_inside_tree():
		return INF
	var diff := global_position - target.global_position
	diff.y = 0.0
	return diff.length()


## Get the move speed from enemy def or fall back to rusher speed.
func get_move_speed() -> float:
	var base_speed: float
	if enemy_def:
		base_speed = enemy_def.move_speed * speed_multiplier
	else:
		base_speed = Constants.ENEMY_RUSHER_SPEED * speed_multiplier
	return base_speed * status_effects.get_speed_multiplier()


## Get the attack range from enemy def or fall back to rusher range.
func get_attack_range() -> float:
	if enemy_def:
		return enemy_def.attack_range
	return Constants.ENEMY_RUSHER_ATTACK_RANGE


## Get the attack cooldown from def or constant.
func get_attack_cooldown() -> float:
	if enemy_def:
		return enemy_def.attack_cooldown
	return Constants.ENEMY_ATTACK_COOLDOWN


## Get the perception delay from def or constant.
func get_perception_delay() -> float:
	if enemy_def:
		return enemy_def.perception_delay
	return Constants.ENEMY_PERCEPTION_DELAY


## Whether this enemy can currently block hits.
func is_blocking() -> bool:
	return _is_blocking and _block_hits_remaining > 0


## Start blocking (shield enemy).
func start_blocking() -> void:
	_is_blocking = true


## Stop blocking.
func stop_blocking() -> void:
	_is_blocking = false


## Absorb a blocked hit. Returns true if still blocking, false if staggered.
func absorb_block_hit() -> bool:
	_block_hits_remaining -= 1
	if _block_hits_remaining <= 0:
		_is_blocking = false
		_stagger_override_duration = Constants.ENEMY_SHIELD_STAGGER_DURATION
		_block_hits_remaining = Constants.ENEMY_SHIELD_STAGGER_HITS
		return false
	return true


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity := Constants.WORLD_GRAVITY
		if juggle.is_airborne():
			gravity *= Constants.JUGGLE_GRAVITY_MULTIPLIER
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -Constants.TERMINAL_VELOCITY)


func _on_hit_received(attack_data: AttackDef, attacker: Node3D) -> void:
	if not is_instance_valid(attacker):
		return
	# Shield enemies can block frontal attacks (dot product check).
	if is_blocking():
		var to_attacker := (attacker.global_position - global_position).normalized()
		to_attacker.y = 0.0
		var attacker_in_front := facing_direction.dot(to_attacker) > 0.0
		if attacker_in_front:
			var reduced_damage := attack_data.base_damage * (1.0 - Constants.ENEMY_SHIELD_BLOCK_REDUCTION)
			health.take_damage(reduced_damage)
			if not absorb_block_hit():
				state_machine.transition_to(&"stagger")
			return

	# Calculate elemental multiplier from enemy weakness/resistance.
	var elem_mult := 1.0
	if enemy_def and attack_data.element_type != &"":
		elem_mult = ElementCalculator.get_multiplier(
			attack_data.element_type, enemy_def.weakness, enemy_def.resistance
		)
	var dmg_taken_mult := status_effects.get_damage_taken_multiplier()
	var attacker_str: int = 0
	if attacker.has_method("get_derived_stats"):
		attacker_str = StatCalculator.get_stat(attacker.get_derived_stats(), &"strength")
	CombatSystem.process_hit(
		health, attack_data, attacker, self,
		0.0, attacker_str, Constants.STRENGTH_DAMAGE_SCALE, elem_mult, dmg_taken_mult
	)
	# Apply elemental status effects from the incoming attack.
	CombatSystem.apply_status_if_applicable(attack_data, self, status_effects)

	# Hit lag: brief freeze on impact for weight/crunch feel.
	var lag_dur := Constants.HIT_LAG_HEAVY_DURATION if attack_data.knockback_force >= Constants.KNOCKBACK_HEAVY else Constants.HIT_LAG_DURATION
	_hit_lag_timer = lag_dur
	_hit_lag_frozen = true

	# Apply knockback — primarily X-axis, Z dampened for belt-scroller feel.
	var push_dir := (global_position - attacker.global_position)
	push_dir.y = 0.0
	if push_dir.length_squared() < 0.001:
		push_dir = -facing_direction
	push_dir = push_dir.normalized()
	var resistance := 0.0
	if enemy_def:
		resistance = clampf(enemy_def.knockback_resistance, 0.0, 0.95)
	var kb_strength := attack_data.knockback_force * (1.0 - resistance)
	velocity.x = push_dir.x * kb_strength
	velocity.z = push_dir.z * kb_strength * Constants.KNOCKBACK_Z_DAMPEN

	# Launcher check.
	if attack_data.is_launcher and not juggle.is_airborne():
		var base_launch := attack_data.launch_velocity if attack_data.launch_velocity > 0.0 else Constants.JUGGLE_LAUNCH_VELOCITY
		velocity.y = base_launch * (1.0 - resistance * 0.5)
		juggle.launch()
		EventBus.combat_juggle_launched.emit(self, attacker)
	elif juggle.is_airborne():
		juggle.register_air_hit()
		EventBus.combat_juggle_hit.emit(self, juggle.get_hit_count())
		if juggle.is_limit_reached():
			# Hard knockdown — forced to ground.
			velocity.y = -Constants.JUGGLE_LAUNCH_VELOCITY
			EventBus.combat_juggle_limit_reached.emit(self)

	if health.is_dead():
		state_machine.transition_to(&"dead")
	elif boss_phase == 1 and enemy_def and enemy_def.behavior == &"boss":
		var hp_ratio := health.get_current_hp() / health.get_max_hp()
		if hp_ratio <= Constants.BOSS_PHASE_2_HP_THRESHOLD:
			state_machine.transition_to(&"boss_phase_check")
		else:
			state_machine.transition_to(&"hurt")
	else:
		state_machine.transition_to(&"hurt")


func play_animation(anim_name: StringName, speed_scale: float = 1.0) -> void:
	if enemy_model and enemy_model.has_method("play_animation"):
		enemy_model.play_animation(anim_name, speed_scale)


func get_animation_duration(anim_name: StringName) -> float:
	if enemy_model and enemy_model.has_method("get_animation_duration"):
		return enemy_model.get_animation_duration(anim_name)
	return 0.0


func flash_mesh(color: Color) -> void:
	if enemy_model and enemy_model.has_method("flash"):
		enemy_model.flash(color)
		return

	var mesh := model_pivot.get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	if _original_material == null:
		_original_material = mesh.get_surface_override_material(0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mesh.set_surface_override_material(0, mat)


func restore_mesh() -> void:
	if enemy_model and enemy_model.has_method("restore"):
		enemy_model.restore()
		return

	var mesh := model_pivot.get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	mesh.set_surface_override_material(0, _original_material)


func _create_health_bar() -> void:
	var bar_holder := Node3D.new()
	bar_holder.name = "HealthBar"
	bar_holder.position = Vector3(0, 2.4, 0)
	add_child(bar_holder)

	# Background bar (dark red).
	var bg := MeshInstance3D.new()
	bg.name = "BarBG"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(1.2, 0.18)
	bg.mesh = bg_mesh
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.0, 0.0, 0.9)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	bg_mat.render_priority = 1
	bg.material_override = bg_mat
	bar_holder.add_child(bg)

	# Fill bar (green → yellow → red based on HP).
	var fill := MeshInstance3D.new()
	fill.name = "BarFill"
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(1.1, 0.12)
	fill.mesh = fill_mesh
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.0, 0.9, 0.0, 1.0)
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.no_depth_test = true
	fill_mat.render_priority = 2
	fill.material_override = fill_mat
	fill.position.z = -0.01
	bar_holder.add_child(fill)

	_health_bar_fill = fill


func _update_health_bar() -> void:
	if _health_bar_fill == null or health == null:
		return
	var ratio := clampf(health.get_current_hp() / health.get_max_hp(), 0.0, 1.0)
	_health_bar_fill.scale.x = maxf(ratio, 0.001)
	_health_bar_fill.position.x = (ratio - 1.0) * 0.55
	# Color: green → yellow → red.
	var fill_color: Color
	if ratio > 0.5:
		fill_color = Color(0.0, 0.9, 0.0, 1.0).lerp(Color(0.9, 0.9, 0.0, 1.0), (1.0 - ratio) * 2.0)
	else:
		fill_color = Color(0.9, 0.9, 0.0, 1.0).lerp(Color(0.9, 0.0, 0.0, 1.0), (0.5 - ratio) * 2.0)
	(_health_bar_fill.material_override as StandardMaterial3D).albedo_color = fill_color


func _apply_mesh_color(color: Color) -> void:
	# Try the enemy model first, then fall back to a static Mesh child.
	if enemy_model and enemy_model.has_method("set_base_color"):
		enemy_model.set_base_color(color)
		return

	var mesh_instance := model_pivot.get_node_or_null("Mesh")
	if mesh_instance == null and enemy_model:
		# Search within the enemy model for a MeshInstance3D child.
		for child in enemy_model.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	if mesh_instance and mesh_instance is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		(mesh_instance as MeshInstance3D).material_override = mat


## Configure this enemy from an EnemyDef at runtime (for pool reuse).
## When start_dormant is true, the enemy stands idle until the player is in range.
func configure(def: EnemyDef, player_target: Node3D, start_dormant: bool = false) -> void:
	enemy_def = def
	enemy_type = def.enemy_type
	health.reset(def.base_hp)
	juggle.land()
	target = player_target
	_block_hits_remaining = Constants.ENEMY_SHIELD_STAGGER_HITS if def.can_block else 0
	_is_blocking = false
	_stagger_override_duration = 0.0
	attack_cooldown_timer = 0.0
	boss_phase = 1
	speed_multiplier = 1.0
	boss_attack_override = null
	status_effects.clear_all()
	_apply_mesh_color(def.mesh_color)
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLATFORM
	state_machine.set_initial_state(&"dormant" if start_dormant else &"idle")


## Activate a pre-spawned encounter enemy so it starts participating immediately.
func activate_for_encounter() -> void:
	if health == null or health.is_dead():
		return
	if state_machine == null:
		return
	if state_machine.current_state_name == &"dormant":
		state_machine.transition_to(&"idle")


## Apply a stagger override used by parries/guard breaks.
func apply_parry_stun(duration: float, parry_player: Node3D = null) -> void:
	if health == null or health.is_dead():
		return
	_stagger_override_duration = maxf(_stagger_override_duration, duration)
	stop_blocking()
	hitbox.disable()
	if is_instance_valid(parry_player):
		var push_dir := (global_position - parry_player.global_position)
		push_dir.y = 0.0
		if push_dir.length_squared() < 0.001:
			push_dir = -facing_direction
		push_dir = push_dir.normalized()
		var push_force := maxf(Constants.KNOCKBACK_LIGHT * 0.8, 2.5)
		velocity.x = push_dir.x * push_force
		velocity.z = push_dir.z * push_force * Constants.KNOCKBACK_Z_DAMPEN
	state_machine.transition_to(&"stagger")


## Consume and clear stagger override duration.
func consume_stagger_duration(default_duration: float) -> float:
	var duration := _stagger_override_duration if _stagger_override_duration > 0.0 else default_duration
	_stagger_override_duration = 0.0
	return duration
