## Player CharacterBody3D — owns state machine, health, combo, hitbox/hurtbox.
## Bridges component signals to EventBus for cross-system communication.
class_name PlayerController
extends CharacterBody3D


@onready var state_machine: StateMachine = $StateMachine
@onready var model_pivot: Node3D = $ModelPivot
@onready var character_model: Node3D = $ModelPivot/CharacterModel
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var facing_right: bool = true
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var dodge_cooldown_timer: float = 0.0

## Player index for multiplayer. 0 = keyboard player.
var player_index: int = 0

var health: HealthComponent
var combo_tracker: ComboTracker
var tp_tracker: TPTracker


func _ready() -> void:
	health = HealthComponent.new(Constants.PLAYER_MAX_HP)
	combo_tracker = ComboTracker.new(Constants.PLAYER_COMBO_MAX_STEPS, Constants.COMBO_INPUT_WINDOW)
	tp_tracker = TPTracker.new()

	state_machine.entity = self
	state_machine.add_state(&"idle", PlayerStateIdle.new())
	state_machine.add_state(&"run", PlayerStateRun.new())
	state_machine.add_state(&"jump", PlayerStateJump.new())
	state_machine.add_state(&"fall", PlayerStateFall.new())
	state_machine.add_state(&"land", PlayerStateLand.new())
	state_machine.add_state(&"attack_light", PlayerStateAttackLight.new())
	state_machine.add_state(&"attack_heavy", PlayerStateAttackHeavy.new())
	state_machine.add_state(&"attack_launcher", PlayerStateAttackLauncher.new())
	var TechniqueScript := load("res://scripts/core/player_states/player_state_technique.gd")
	state_machine.add_state(&"technique", TechniqueScript.new())
	state_machine.add_state(&"dodge", PlayerStateDodge.new())
	state_machine.add_state(&"hurt", PlayerStateHurt.new())
	state_machine.add_state(&"dead", PlayerStateDead.new())
	state_machine.set_initial_state(&"idle")

	hurtbox.hit_received.connect(_on_hit_received)
	_bridge_eventbus_signals()


func _physics_process(delta: float) -> void:
	var capped := minf(delta, Constants.DELTA_CAP)
	was_on_floor = is_on_floor()

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = Constants.PLAYER_JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= capped

	combo_tracker.tick(capped)
	tp_tracker.tick_regen(capped)

	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= capped


## Apply gravity with fall multiplier.
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity := Constants.WORLD_GRAVITY
		if velocity.y < 0.0:
			gravity *= Constants.PLAYER_FALL_GRAVITY_MULTIPLIER
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -Constants.TERMINAL_VELOCITY)


## Apply belt-depth (Z-axis) movement from input.
func apply_belt_depth(delta: float) -> void:
	var z_input := Input.get_axis("move_up", "move_down")
	if absf(z_input) > Constants.INPUT_DEADZONE:
		velocity.z = z_input * Constants.PLAYER_BELT_DEPTH_SPEED
	else:
		velocity.z = move_toward(velocity.z, 0.0, Constants.PLAYER_BELT_DEPTH_SPEED * delta * Constants.BELT_DEPTH_DECEL_MULTIPLIER)


## Clamp position to belt-depth range and arena bounds.
func clamp_belt_depth() -> void:
	position.z = clampf(
		position.z,
		-Constants.PLAYER_BELT_DEPTH_RANGE,
		Constants.PLAYER_BELT_DEPTH_RANGE
	)
	if GameState.encounter_active:
		position.x = clampf(position.x, GameState.arena_lock_min_x, GameState.arena_lock_max_x)


## Get horizontal movement input axis.
func get_movement_input() -> float:
	return Input.get_axis("move_left", "move_right")


## Update facing direction based on input. Uses Y rotation (not scale) to avoid 3D culling issues.
func update_facing(x_input: float) -> void:
	if x_input > 0.0:
		facing_right = true
		model_pivot.rotation_degrees.y = 0.0
	elif x_input < 0.0:
		facing_right = false
		model_pivot.rotation_degrees.y = 180.0


## Consume the jump buffer after a successful jump.
func consume_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


## Check if dodge is off cooldown.
func can_dodge() -> bool:
	return dodge_cooldown_timer <= 0.0


## Start the dodge cooldown timer.
func start_dodge_cooldown() -> void:
	dodge_cooldown_timer = Constants.DODGE_COOLDOWN


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
	# Ignore hits while already dead.
	if health.is_dead():
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

	if health.is_dead():
		state_machine.transition_to(&"dead")
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
	EventBus.enemy_died.connect(func(_enemy: Node, _type: StringName, _pos: Vector3) -> void:
		if not health.is_dead():
			health.heal(Constants.PLAYER_KILL_HEAL)
	)
