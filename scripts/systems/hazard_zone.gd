## Environmental hazard zone — damages entities that enter.
## Supports damage-over-time (fire), instant (spikes), and knockback (wind).
class_name HazardZone
extends Area3D


enum HazardType { DAMAGE_OVER_TIME, INSTANT, KNOCKBACK }

## Type of hazard behavior.
@export var hazard_type: HazardType = HazardType.DAMAGE_OVER_TIME

## Damage per tick for DAMAGE_OVER_TIME, or single hit for INSTANT.
@export var damage: float = Constants.HAZARD_FIRE_DAMAGE

## Time between damage ticks (DAMAGE_OVER_TIME only).
@export var tick_interval: float = Constants.HAZARD_FIRE_TICK_INTERVAL

## Force direction and magnitude (KNOCKBACK only).
@export var knockback_force: Vector3 = Vector3.ZERO

## Track entities inside and their tick timers.
var _entities_in_zone: Dictionary = {}  # Node -> float (time since last tick)

## Cached attack data to avoid per-tick allocation.
var _cached_attack: AttackDef = null


func _ready() -> void:
	# Pre-allocate reusable AttackDef for damage application.
	_cached_attack = AttackDef.new()
	_cached_attack.base_damage = damage
	_cached_attack.damage_multiplier = 1.0
	_cached_attack.knockback_force = 0.0
	_cached_attack.hitstop_duration = 0.0

	collision_layer = 0
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY
	monitoring = true
	monitorable = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if hazard_type != HazardType.DAMAGE_OVER_TIME:
		return

	var to_remove: Array[Node] = []
	for entity: Node in _entities_in_zone:
		if not is_instance_valid(entity):
			to_remove.append(entity)
			continue
		_entities_in_zone[entity] += delta
		if _entities_in_zone[entity] >= tick_interval:
			_entities_in_zone[entity] -= tick_interval
			_apply_damage(entity)

	for entity in to_remove:
		_entities_in_zone.erase(entity)


func _on_body_entered(body: Node3D) -> void:
	match hazard_type:
		HazardType.DAMAGE_OVER_TIME:
			_entities_in_zone[body] = 0.0
			# Apply first tick immediately.
			_apply_damage(body)
		HazardType.INSTANT:
			_apply_damage(body)
		HazardType.KNOCKBACK:
			_apply_knockback(body)


func _on_body_exited(body: Node3D) -> void:
	_entities_in_zone.erase(body)


## Apply damage to an entity via its hurtbox if available.
func _apply_damage(entity: Node) -> void:
	if not is_instance_valid(entity):
		return
	# Try to find a hurtbox on the entity.
	var hurtbox := _find_hurtbox(entity)
	if hurtbox:
		_cached_attack.base_damage = damage
		hurtbox.hit_received.emit(_cached_attack, self)


## Apply knockback force to an entity.
func _apply_knockback(entity: Node) -> void:
	if entity is CharacterBody3D:
		(entity as CharacterBody3D).velocity += knockback_force


## Find a Hurtbox child on the given node.
func _find_hurtbox(entity: Node) -> Hurtbox:
	for child in entity.get_children():
		if child is Hurtbox:
			return child as Hurtbox
	return null
