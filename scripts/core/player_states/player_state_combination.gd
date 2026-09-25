## Combination attack (the battlefield "musou"): spends a full CombinationGauge for a
## multi-pulse radial sweep that clears crowds. Invincible throughout; final pulse launches.
## Element comes from the character's active technique so each hero's Combination feels distinct.
class_name PlayerStateCombination
extends State


const MAX_QUERY_RESULTS: int = 96

var _elapsed: float = 0.0
var _pulses_done: int = 0
var _pulse_attack: AttackDef = null
var _finisher_attack: AttackDef = null
var _query := PhysicsShapeQueryParameters3D.new()
var _sphere := SphereShape3D.new()


func _init() -> void:
	_sphere.radius = Constants.COMBINATION_ATTACK_RADIUS
	_query.shape = _sphere
	_query.collide_with_areas = true
	_query.collide_with_bodies = false
	_query.collision_mask = Constants.LAYER_ENEMY_HURTBOX


func enter(_previous_state: StringName) -> void:
	var player: PlayerController = entity as PlayerController
	_elapsed = 0.0
	_pulses_done = 0
	player.hurtbox.is_invincible = true
	player.combo_tracker.reset()
	entity.velocity = Vector3.ZERO
	_build_attacks(player)
	player.play_animation(&"attack_heavy", 0.8)
	player.flash_mesh(Color(1.0, 0.85, 0.35))
	EventBus.combat_combination_started.emit(player, _pulse_attack.element_type)


func exit() -> void:
	var player: PlayerController = entity as PlayerController
	player.hurtbox.is_invincible = false
	player.restore_mesh()
	EventBus.combat_combination_finished.emit(player)


func physics_process(delta: float) -> StringName:
	var player: PlayerController = entity as PlayerController
	_elapsed += delta
	# Let the player steer the sweep slowly through the crowd.
	var input := player.get_movement_input_vector()
	entity.velocity.x = input.x * Constants.PLAYER_MOVE_SPEED * 0.35
	entity.velocity.z = input.y * Constants.PLAYER_MOVE_SPEED * 0.35
	player.apply_gravity(delta)
	entity.move_and_slide()
	player.clamp_to_bounds()

	var pulses := maxi(Constants.COMBINATION_ATTACK_PULSES, 1)
	var interval := Constants.COMBINATION_ATTACK_DURATION / float(pulses + 1)
	while _pulses_done < pulses and _elapsed >= interval * float(_pulses_done + 1):
		_pulses_done += 1
		var is_last := _pulses_done == pulses
		_pulse(player, _finisher_attack if is_last else _pulse_attack)
		player.play_animation(&"attack_light_%d" % (((_pulses_done - 1) % 3) + 1), 1.6)

	if _elapsed >= Constants.COMBINATION_ATTACK_DURATION:
		return &"idle" if entity.is_on_floor() else &"fall"
	return &""


func _build_attacks(player: PlayerController) -> void:
	var element: StringName = &""
	var technique := player.get_active_technique()
	if technique != null:
		element = technique.element_type
	_pulse_attack = AttackDef.new()
	_pulse_attack.attack_name = &"combination"
	_pulse_attack.base_damage = Constants.COMBINATION_ATTACK_BASE_DAMAGE
	_pulse_attack.knockback_force = Constants.COMBINATION_ATTACK_KNOCKBACK * 0.5
	_pulse_attack.hitstop_duration = 0.0
	_pulse_attack.element_type = element
	_finisher_attack = _pulse_attack.duplicate()
	_finisher_attack.attack_name = &"combination_finisher"
	_finisher_attack.base_damage = Constants.COMBINATION_ATTACK_BASE_DAMAGE * 1.5
	_finisher_attack.knockback_force = Constants.COMBINATION_ATTACK_KNOCKBACK
	_finisher_attack.is_launcher = true
	_finisher_attack.hitstop_duration = 0.06


func _pulse(player: PlayerController, attack: AttackDef) -> void:
	var space := player.get_world_3d().direct_space_state
	_query.transform = Transform3D(Basis.IDENTITY, player.global_position + Vector3(0, 0.9, 0))
	var results := space.intersect_shape(_query, MAX_QUERY_RESULTS)
	for hit: Dictionary in results:
		var hurtbox := hit.get("collider") as Hurtbox
		if hurtbox == null or hurtbox.get_parent() == player:
			continue
		hurtbox.receive_hit(attack, player)
	EventBus.combat_combination_pulse.emit(player, player.global_position, Constants.COMBINATION_ATTACK_RADIUS)
