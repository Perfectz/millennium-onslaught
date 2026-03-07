## Pooled floating damage numbers that rise and fade out.
## Uses ObjectPool for recycling. Listens to combat_hit_landed.
class_name DamageNumberSpawnerSingleton
extends Node


const SCENE_PATH: String = "res://scenes/vfx/damage_number.tscn"
const POOL_NAME: StringName = &"damage_number"
const WORLD_EFFECTS_ANCHOR_NAME: StringName = &"WorldEffects"

## Pre-built scene (generated at runtime if .tscn missing).
var _label_scene: PackedScene = null
var _pool_warmed: bool = false
var _active_labels: Array[Label3D] = []
var _label_tweens: Dictionary = {}


func _ready() -> void:
	# Defer pool warming until the tree is fully ready.
	call_deferred("_warm_pool")
	EventBus.combat_hit_event.connect(_on_hit_event)
	EventBus.scene_transition_started.connect(_on_scene_transition_started)


func _exit_tree() -> void:
	_reclaim_active_labels()


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

	var label := _checkout_label()
	if label == null:
		return

	label.text = str(int(amount))
	label.global_position = world_pos + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.1, 0.1))
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

	# Animate: rise + fade.
	var rise := Constants.HUD_DAMAGE_NUMBER_RISE_SPEED * 0.02
	var lifetime := Constants.HUD_DAMAGE_NUMBER_LIFETIME
	var tween := _start_label_tween(label)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + rise, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.4)
	if is_critical:
		# Scale punch for crits.
		tween.tween_property(label, "scale", Vector3.ONE * 0.6, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		_label_tweens.erase(label)
		_release_label(label)
	)


## Spawn a floating XP label at a world position.
func spawn_xp(world_pos: Vector3, amount: int) -> void:
	if amount <= 0:
		return
	if not _pool_warmed:
		_warm_pool()

	var label := _checkout_label()
	if label == null:
		return

	label.text = "+%d XP" % amount
	label.global_position = world_pos + Vector3(randf_range(-0.2, 0.2), 1.8, randf_range(-0.2, 0.2))
	label.font_size = 44
	label.modulate = Color(0.65, 1.0, 0.65, 1.0)
	label.outline_modulate = Color(0.05, 0.25, 0.05)
	label.scale = Vector3.ONE * 0.9
	label.visible = true
	label.process_mode = Node.PROCESS_MODE_INHERIT

	var lifetime := Constants.HUD_DAMAGE_NUMBER_LIFETIME * 1.1
	var tween := _start_label_tween(label)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.4)
	tween.chain().tween_callback(func() -> void:
		_label_tweens.erase(label)
		_release_label(label)
	)


func _on_hit_event(event: CombatHitEvent) -> void:
	var is_crit := event.damage >= Constants.HEAVY_ATTACK_DAMAGE
	spawn(event.hit_position, event.damage, is_crit)


func _checkout_label() -> Label3D:
	var instance := ObjectPool.get_instance(POOL_NAME)
	if instance == null:
		return null
	var label := instance as Label3D
	if label == null:
		ObjectPool.return_instance(instance)
		return null
	if not _mount_world_effect(label):
		_release_label(label)
		return null
	if label not in _active_labels:
		_active_labels.append(label)
	label.visible = false
	label.modulate.a = 1.0
	label.scale = Vector3.ONE
	return label


func _start_label_tween(label: Label3D) -> Tween:
	_stop_label_tween(label)
	var tween := create_tween()
	_label_tweens[label] = tween
	return tween


func _stop_label_tween(label: Label3D) -> void:
	var tween := _label_tweens.get(label) as Tween
	if tween != null and is_instance_valid(tween):
		tween.kill()
	_label_tweens.erase(label)


func _mount_world_effect(label: Label3D) -> bool:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return false
	var anchor := scene_root.get_node_or_null(String(WORLD_EFFECTS_ANCHOR_NAME)) as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = String(WORLD_EFFECTS_ANCHOR_NAME)
		scene_root.add_child(anchor)
	if label.get_parent() == null:
		anchor.add_child(label)
	elif label.get_parent() != anchor:
		label.reparent(anchor)
	return true


func _release_label(label: Label3D) -> void:
	_active_labels.erase(label)
	if not is_instance_valid(label):
		return
	_stop_label_tween(label)
	label.visible = false
	label.modulate.a = 1.0
	label.scale = Vector3.ONE
	if label.get_parent() != ObjectPool:
		label.reparent(ObjectPool)
	ObjectPool.return_instance(label)


func _reclaim_active_labels() -> void:
	for label in _active_labels.duplicate():
		_release_label(label)
	_active_labels.clear()


func _on_scene_transition_started(_target_scene: String) -> void:
	_reclaim_active_labels()


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
