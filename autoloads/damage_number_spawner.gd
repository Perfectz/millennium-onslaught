## Pooled floating damage numbers that rise and fade out.
## Uses ObjectPool for recycling. Listens to combat_hit_landed.
class_name DamageNumberSpawnerSingleton
extends Node


const SCENE_PATH: String = "res://scenes/vfx/damage_number.tscn"
const POOL_NAME: StringName = &"damage_number"

## Pre-built scene (generated at runtime if .tscn missing).
var _label_scene: PackedScene = null
var _pool_warmed: bool = false


func _ready() -> void:
	# Defer pool warming until the tree is fully ready.
	call_deferred("_warm_pool")
	EventBus.combat_hit_landed.connect(_on_hit_landed)


func _warm_pool() -> void:
	if _pool_warmed:
		return
	_label_scene = _create_damage_number_scene()
	ObjectPool.warm_pool(_label_scene, Constants.DAMAGE_NUMBER_POOL_SIZE, POOL_NAME)
	_pool_warmed = true


## Spawn a floating damage number at a world position.
func spawn(world_pos: Vector3, amount: float, is_critical: bool = false) -> void:
	if not _pool_warmed:
		_warm_pool()

	var instance: Node = ObjectPool.get_instance(POOL_NAME)
	if instance == null:
		return

	# Configure the label.
	var label: Label3D = instance as Label3D
	if label == null:
		ObjectPool.return_instance(instance)
		return

	label.text = str(int(amount))
	label.position = world_pos + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.1, 0.1))
	label.modulate.a = 1.0
	label.scale = Vector3.ONE * (1.3 if is_critical else 1.0)

	if is_critical:
		label.font_size = 72
		label.modulate = Color(1.0, 0.3, 0.2)
		label.outline_modulate = Color(0.2, 0.0, 0.0)
	else:
		label.font_size = 48
		label.modulate = Color(1.0, 1.0, 1.0)
		label.outline_modulate = Color(0.1, 0.1, 0.1)

	label.visible = true
	label.process_mode = Node.PROCESS_MODE_INHERIT

	# Add to scene tree if not already.
	if label.get_parent() == null:
		get_tree().current_scene.add_child(label)
	elif not label.is_inside_tree():
		# Re-parent orphaned pooled nodes.
		label.reparent(get_tree().current_scene)

	# Animate: rise + fade.
	var rise := Constants.HUD_DAMAGE_NUMBER_RISE_SPEED * 0.02
	var lifetime := Constants.HUD_DAMAGE_NUMBER_LIFETIME
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + rise, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.4)
	if is_critical:
		# Scale punch for crits.
		tween.tween_property(label, "scale", Vector3.ONE * 0.6, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		label.visible = false
		ObjectPool.return_instance(label)
	)


## Spawn a floating XP label at a world position.
func spawn_xp(world_pos: Vector3, amount: int) -> void:
	if amount <= 0:
		return
	if not _pool_warmed:
		_warm_pool()

	var instance: Node = ObjectPool.get_instance(POOL_NAME)
	if instance == null:
		return
	var label: Label3D = instance as Label3D
	if label == null:
		ObjectPool.return_instance(instance)
		return

	label.text = "+%d XP" % amount
	label.position = world_pos + Vector3(randf_range(-0.2, 0.2), 1.8, randf_range(-0.2, 0.2))
	label.font_size = 44
	label.modulate = Color(0.65, 1.0, 0.65, 1.0)
	label.outline_modulate = Color(0.05, 0.25, 0.05)
	label.scale = Vector3.ONE * 0.9
	label.visible = true
	label.process_mode = Node.PROCESS_MODE_INHERIT

	if label.get_parent() == null:
		get_tree().current_scene.add_child(label)
	elif not label.is_inside_tree():
		label.reparent(get_tree().current_scene)

	var lifetime := Constants.HUD_DAMAGE_NUMBER_LIFETIME * 1.1
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.4)
	tween.chain().tween_callback(func() -> void:
		label.visible = false
		ObjectPool.return_instance(label)
	)


func _on_hit_landed(_attacker: Node, _target: Node, damage: float, hit_position: Vector3, _attack_data: AttackDef) -> void:
	var is_crit := damage >= Constants.HEAVY_ATTACK_DAMAGE
	spawn(hit_position, damage, is_crit)


## Creates a Label3D PackedScene at runtime for pooling.
func _create_damage_number_scene() -> PackedScene:
	var label := Label3D.new()
	label.name = "DamageNumber"
	label.text = "0"
	label.font_size = 48
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.outline_size = 8
	label.modulate = Color.WHITE
	label.outline_modulate = Color(0.1, 0.1, 0.1)
	label.visible = false

	var scene := PackedScene.new()
	scene.pack(label)
	label.free()
	return scene
