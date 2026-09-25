## Lightweight pooled horde enemy. Owns health + hurtbox; HordeDirector drives all movement/AI
## in one batched loop so hundreds can be alive at once. Every existing player attack
## (combo hitbox, projectiles, spells, Combination) hits it through the normal Hurtbox path.
class_name HordeGrunt
extends Node3D


signal defeated(grunt: HordeGrunt, attacker: Node3D)

enum GruntState { INACTIVE, IDLE, ADVANCE, WINDUP, STRIKE, RECOVER, STAGGER, AIRBORNE, DEAD }

const HURTBOX_HEIGHT: float = 1.0

var def: HordeUnitDef = null
var health: HealthComponent = HealthComponent.new(1.0)
var state: GruntState = GruntState.INACTIVE
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
## Knockback / launch velocity (world space). Decays on the ground.
var velocity: Vector3 = Vector3.ZERO
var facing: Vector2 = Vector2.RIGHT
var home: Vector2 = Vector2.ZERO
var base_id: StringName = &""
var slot: int = 0
var anim_phase: float = 0.0
var is_officer_guard: bool = false
## Last computed crowd-separation push (refreshed every other frame by the director).
var sep_cache: Vector2 = Vector2.ZERO

var _body: MeshInstance3D
var _hurtbox: Hurtbox
var _hurt_shape: CollisionShape3D
var _flash_timer: float = 0.0
static var _flash_material: StandardMaterial3D = null


func _init() -> void:
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.monitorable = false
	_hurt_shape = CollisionShape3D.new()
	_hurt_shape.shape = CapsuleShape3D.new()
	_hurtbox.add_child(_hurt_shape)
	add_child(_hurtbox)
	_hurtbox.hit_received.connect(_on_hit_received)
	visible = false


## Bring the grunt to life at `pos` with the given definition.
func activate(unit_def: HordeUnitDef, pos: Vector3, garrison_base: StringName = &"") -> void:
	def = unit_def
	health = HealthComponent.new(unit_def.max_hp)
	state = GruntState.IDLE
	state_timer = 0.0
	attack_cooldown = randf() * Constants.HORDE_ATTACK_COOLDOWN
	velocity = Vector3.ZERO
	base_id = garrison_base
	home = Vector2(pos.x, pos.z)
	anim_phase = randf() * TAU
	sep_cache = Vector2.ZERO
	position = pos
	_body.mesh = HordeMeshFactory.get_mesh(unit_def)
	_body.material_override = null
	_body.position = Vector3.ZERO
	_body.scale = Vector3.ONE
	_body.rotation = Vector3.ZERO
	var capsule := _hurt_shape.shape as CapsuleShape3D
	capsule.radius = unit_def.radius
	capsule.height = maxf(HURTBOX_HEIGHT * unit_def.body_scale, unit_def.radius * 2.0)
	_hurt_shape.position = Vector3(0, capsule.height * 0.5, 0)
	_hurtbox.collision_layer = Constants.LAYER_ENEMY_HURTBOX
	_hurtbox.monitorable = true
	_hurtbox.is_invincible = false
	visible = true
	add_to_group(&"enemies")
	add_to_group(&"horde")
	EventBus.enemy_spawned.emit(self, unit_def.unit_id)


## Return to the pool-idle state (invisible, not hittable).
func deactivate() -> void:
	state = GruntState.INACTIVE
	visible = false
	_hurtbox.set_deferred("monitorable", false)
	_hurtbox.collision_layer = 0
	if is_in_group(&"enemies"):
		remove_from_group(&"enemies")
	if is_in_group(&"horde"):
		remove_from_group(&"horde")


## True while the grunt is alive and participating.
func is_alive() -> bool:
	return state != GruntState.INACTIVE and state != GruntState.DEAD


## True for any pooled-in-use state, including the short corpse phase.
func is_active() -> bool:
	return state != GruntState.INACTIVE


## Used by lock-on and other systems that read enemy stats.
func get_enemy_type() -> StringName:
	return def.unit_id if def else &""


## Mesh node, for the director's procedural animation.
func get_body() -> MeshInstance3D:
	return _body


## Tick the hit flash (called by the director).
func tick_flash(delta: float) -> void:
	if _flash_timer <= 0.0:
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_body.material_override = null


func _on_hit_received(attack_data: AttackDef, attacker: Node3D) -> void:
	if not is_alive() or not is_instance_valid(attacker):
		return
	var elem_mult := 1.0
	if attack_data.element_type != &"":
		elem_mult = ElementCalculator.get_multiplier(attack_data.element_type, def.weakness, def.resistance)
	var attacker_str := 0
	if attacker.has_method("get_derived_stats"):
		attacker_str = StatCalculator.get_stat(attacker.get_derived_stats(), &"strength")
	CombatSystem.process_hit(
		health, attack_data, attacker, self,
		0.0, attacker_str, Constants.STRENGTH_DAMAGE_SCALE, elem_mult, 1.0
	)
	_flash()
	# Knockback away from the attacker; launchers pop grunts into the air.
	var push := global_position - attacker.global_position
	push.y = 0.0
	if push.length_squared() < 0.0001:
		push = Vector3(-facing.x, 0.0, -facing.y)
	push = push.normalized()
	var kb := attack_data.knockback_force * (1.0 - clampf(def.knockback_resistance, 0.0, 0.95))
	velocity.x = push.x * kb
	velocity.z = push.z * kb
	if attack_data.is_launcher or state == GruntState.AIRBORNE:
		var launch := attack_data.launch_velocity if attack_data.launch_velocity > 0.0 else Constants.JUGGLE_LAUNCH_VELOCITY
		velocity.y = launch * (0.6 if state == GruntState.AIRBORNE else 1.0)
		state = GruntState.AIRBORNE
	elif health.is_dead():
		# Dead grunts get a satisfying pop into the air before they fade.
		velocity.y = Constants.JUGGLE_LAUNCH_VELOCITY * 0.45
	if health.is_dead():
		state = GruntState.DEAD
		state_timer = Constants.HORDE_CORPSE_TIME
		_hurtbox.set_deferred("monitorable", false)
		EventBus.enemy_died.emit(self, def.unit_id, global_position)
		defeated.emit(self, attacker)
		return
	if state != GruntState.AIRBORNE:
		state = GruntState.STAGGER
		state_timer = Constants.HORDE_STAGGER_TIME


func _flash() -> void:
	if _flash_material == null:
		_flash_material = StandardMaterial3D.new()
		_flash_material.albedo_color = Color(1.0, 0.95, 0.8)
		_flash_material.emission_enabled = true
		_flash_material.emission = Color(1.0, 0.9, 0.7)
		_flash_material.emission_energy_multiplier = 1.5
	_body.material_override = _flash_material
	_flash_timer = Constants.HORDE_FLASH_TIME
