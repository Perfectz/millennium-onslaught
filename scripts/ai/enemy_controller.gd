## Enemy CharacterBody3D — data-driven via EnemyDef.
## Owns state machine, health, hitbox/hurtbox, target tracking, juggle state.
class_name EnemyController
extends CharacterBody3D


@onready var state_machine: StateMachine = $StateMachine
@onready var model_pivot: Node3D = $ModelPivot
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

## The enemy definition resource driving this enemy's stats and behavior.
@export var enemy_def: EnemyDef = null

var health: HealthComponent
var juggle: JuggleTracker
var target: Node3D = null
var facing_right: bool = true

## Shield enemy: hits absorbed before stagger.
var _block_hits_remaining: int = 0
var _is_blocking: bool = false
var _stagger_timer: float = 0.0
var _original_material: Material = null
var _health_bar_fill: MeshInstance3D = null

## Enemy type identifier (from EnemyDef).
var enemy_type: StringName = &"rusher"

## Attack cooldown for token system.
var attack_cooldown_timer: float = 0.0

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

	state_machine.set_initial_state(&"idle")
	hurtbox.hit_received.connect(_on_hit_received)
	_create_health_bar()
	EventBus.enemy_spawned.emit(self, enemy_type)


func _physics_process(delta: float) -> void:
	var capped := minf(delta, Constants.DELTA_CAP)
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= capped
	if _stagger_timer > 0.0:
		_stagger_timer -= capped
	_update_health_bar()


func set_target(new_target: Node3D) -> void:
	target = new_target


func update_facing_toward_target() -> void:
	if target == null or not is_inside_tree():
		return
	if target.global_position.x > global_position.x:
		facing_right = true
		model_pivot.rotation_degrees.y = 0.0
	else:
		facing_right = false
		model_pivot.rotation_degrees.y = 180.0


func get_horizontal_distance_to_target() -> float:
	if target == null or not is_inside_tree():
		return INF
	return absf(global_position.x - target.global_position.x)


## Get the move speed from enemy def or fall back to rusher speed.
func get_move_speed() -> float:
	if enemy_def:
		return enemy_def.move_speed * speed_multiplier
	return Constants.ENEMY_RUSHER_SPEED * speed_multiplier


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
		_stagger_timer = Constants.ENEMY_SHIELD_STAGGER_DURATION
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
	# Shield enemies can block frontal attacks.
	if is_blocking():
		var attacker_in_front := (attacker.global_position.x > global_position.x) == facing_right
		if attacker_in_front:
			var reduced_damage := attack_data.base_damage * (1.0 - Constants.ENEMY_SHIELD_BLOCK_REDUCTION)
			health.take_damage(reduced_damage)
			if not absorb_block_hit():
				state_machine.transition_to(&"stagger")
			return

	CombatSystem.process_hit(health, attack_data, attacker, self)

	# Apply knockback — horizontal only so characters slide back, not up/down.
	var kb_dir := attack_data.knockback_direction
	kb_dir.y = 0.0
	if attacker.global_position.x > global_position.x:
		kb_dir.x = -absf(kb_dir.x)
	else:
		kb_dir.x = absf(kb_dir.x)
	velocity.x = kb_dir.normalized().x * attack_data.knockback_force

	# Launcher check.
	if attack_data.is_launcher and not juggle.is_airborne():
		velocity.y = attack_data.launch_velocity if attack_data.launch_velocity > 0.0 else Constants.JUGGLE_LAUNCH_VELOCITY
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


func flash_mesh(color: Color) -> void:
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
	var mesh_instance := model_pivot.get_node_or_null("Mesh")
	if mesh_instance and mesh_instance is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		(mesh_instance as MeshInstance3D).material_override = mat


## Configure this enemy from an EnemyDef at runtime (for pool reuse).
func configure(def: EnemyDef, player_target: Node3D) -> void:
	enemy_def = def
	enemy_type = def.enemy_type
	health.reset(def.base_hp)
	juggle.land()
	target = player_target
	_block_hits_remaining = Constants.ENEMY_SHIELD_STAGGER_HITS if def.can_block else 0
	_is_blocking = false
	_stagger_timer = 0.0
	attack_cooldown_timer = 0.0
	boss_phase = 1
	speed_multiplier = 1.0
	boss_attack_override = null
	_apply_mesh_color(def.mesh_color)
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_ENVIRONMENT | Constants.LAYER_PLAYER | Constants.LAYER_PLATFORM
	state_machine.set_initial_state(&"idle")
