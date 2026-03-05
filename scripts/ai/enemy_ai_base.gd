## Base enemy AI with perception delay and attack token system.
class_name EnemyAIBase
extends Node


## AI states.
enum AIState {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	DEAD,
}

## Current AI state.
var _state: AIState = AIState.IDLE

## Target player reference.
var _target: Node3D = null

## Perception delay timer — enemies don't react instantly.
var _perception_timer: float = 0.0

## Whether this enemy holds an attack token.
var _has_attack_token: bool = false

## Attack cooldown timer.
var _attack_cooldown: float = 0.0

## Owner enemy node.
var _enemy: CharacterBody3D = null

## Pre-allocated velocity work vector.
var _velocity_work: Vector3 = Vector3.ZERO


## Set up the AI with its owner enemy.
func setup(enemy: CharacterBody3D) -> void:
	_enemy = enemy


## Process AI logic each physics frame.
func process_ai(delta: float) -> void:
	if _enemy == null:
		return
	var capped_delta: float = minf(delta, Constants.DELTA_CAP)
	_update_perception(capped_delta)
	_update_cooldowns(capped_delta)
	match _state:
		AIState.IDLE:
			_process_idle(capped_delta)
		AIState.CHASE:
			_process_chase(capped_delta)
		AIState.ATTACK:
			_process_attack(capped_delta)
		AIState.STAGGER:
			_process_stagger(capped_delta)
		AIState.DEAD:
			pass


## Set the target player.
func set_target(target: Node3D) -> void:
	_target = target


## Notify the AI of being hit (triggers stagger).
func on_hit() -> void:
	_change_state(AIState.STAGGER)


## Notify the AI of death.
func on_death() -> void:
	_change_state(AIState.DEAD)


## Grant an attack token to this enemy.
func grant_attack_token() -> void:
	_has_attack_token = true


## Revoke the attack token.
func revoke_attack_token() -> void:
	_has_attack_token = false


## Get current AI state.
func get_state() -> AIState:
	return _state


func _change_state(new_state: AIState) -> void:
	_state = new_state


func _update_perception(delta: float) -> void:
	if _perception_timer > 0.0:
		_perception_timer -= delta


func _update_cooldowns(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta


func _process_idle(_delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		_perception_timer = Constants.ENEMY_PERCEPTION_DELAY
		_change_state(AIState.CHASE)


func _process_chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_change_state(AIState.IDLE)
		return
	if _perception_timer > 0.0:
		return
	var to_target: Vector3 = _target.global_position - _enemy.global_position
	var dist: float = to_target.length()
	if dist <= Constants.ENEMY_RUSHER_ATTACK_RANGE and _has_attack_token and _attack_cooldown <= 0.0:
		_change_state(AIState.ATTACK)
		return
	# Move toward target.
	var direction: Vector3 = to_target.normalized()
	_velocity_work.x = direction.x * Constants.ENEMY_RUSHER_SPEED
	_velocity_work.z = direction.z * Constants.ENEMY_RUSHER_SPEED
	_enemy.velocity = _velocity_work
	_enemy.move_and_slide()


func _process_attack(_delta: float) -> void:
	# Attack animation handles damage. After attack, return to chase.
	_attack_cooldown = Constants.ENEMY_ATTACK_COOLDOWN
	_has_attack_token = false
	_change_state(AIState.CHASE)


func _process_stagger(_delta: float) -> void:
	# Brief stagger, then return to chase.
	_change_state(AIState.CHASE)
