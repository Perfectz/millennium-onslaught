## Spawns visual effects in response to combat events.
class_name VFXSystem
extends Node


func _ready() -> void:
	EventBus.combat_hit_landed.connect(_on_hit_landed)
	EventBus.combat_kill.connect(_on_kill)
	EventBus.combat_dodge.connect(_on_dodge)


## Spawn hit particles at a position.
func spawn_hit_vfx(position: Vector3, intensity: float = 1.0) -> void:
	var vfx: Node = ObjectPool.get_instance(&"hit_vfx")
	if vfx == null:
		return
	if vfx is Node3D:
		(vfx as Node3D).global_position = position
	# VFX auto-returns to pool after animation finishes.


## Spawn death particles at a position.
func spawn_death_vfx(position: Vector3) -> void:
	var vfx: Node = ObjectPool.get_instance(&"death_vfx")
	if vfx == null:
		return
	if vfx is Node3D:
		(vfx as Node3D).global_position = position


## Spawn dodge trail effect.
func spawn_dodge_vfx(position: Vector3) -> void:
	var vfx: Node = ObjectPool.get_instance(&"dodge_vfx")
	if vfx == null:
		return
	if vfx is Node3D:
		(vfx as Node3D).global_position = position


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, hit_position: Vector3) -> void:
	var intensity: float = 1.0
	if damage >= Constants.HEAVY_ATTACK_DAMAGE:
		intensity = 2.0
	spawn_hit_vfx(hit_position, intensity)


func _on_kill(_attacker: Node, target: Node, kill_position: Vector3) -> void:
	spawn_death_vfx(kill_position)


func _on_dodge(player: Node) -> void:
	if player is Node3D:
		spawn_dodge_vfx((player as Node3D).global_position)
