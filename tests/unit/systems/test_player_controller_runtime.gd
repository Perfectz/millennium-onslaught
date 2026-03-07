## Runtime regressions for PlayerController component replacement.
class_name TestPlayerControllerRuntime
extends GdUnitTestSuite


const PlayerScene := preload("res://scenes/characters/player.tscn")

var _spawned_nodes: Array[Node] = []


func after_test() -> void:
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_replace_health_component_disconnects_old_signal_handlers() -> void:
	GameState.start_new_game()
	var player: PlayerController = await _spawn_player()
	var old_health: HealthComponent = player.health
	var emitted := {"count": 0}
	var on_health_changed := func(_player_index: int, _new_hp: float, _max_hp: float) -> void:
		emitted["count"] += 1

	EventBus.player_health_changed.connect(on_health_changed)
	player._replace_health_component(150.0, 120.0)
	emitted["count"] = 0

	old_health.take_damage(10.0)
	assert_int(emitted["count"] as int).is_equal(0)

	player.health.take_damage(5.0)
	assert_int(emitted["count"] as int).is_equal(1)
	assert_float(player.health.get_current_hp()).is_equal(115.0)

	var alys := GameState.character_data.get(&"alys", {}) as Dictionary
	assert_float(alys.get("hp", 0.0) as float).is_equal(115.0)
	assert_float(alys.get("max_hp", 0.0) as float).is_equal(150.0)

	if EventBus.player_health_changed.is_connected(on_health_changed):
		EventBus.player_health_changed.disconnect(on_health_changed)


func test_parry_hit_emits_event_and_preserves_health() -> void:
	GameState.start_new_game()
	var player: PlayerController = await _spawn_player()
	var attacker := Node3D.new()
	player.get_parent().add_child(attacker)
	_spawned_nodes.append(attacker)
	attacker.global_position = player.global_position + Vector3(-1.0, 0.0, 0.0)

	var attack := AttackDef.new()
	attack.base_damage = 40.0
	attack.damage_multiplier = 1.0
	attack.knockback_force = 6.0

	player.health.take_damage(25.0)
	player.tp_tracker.set_current_tp(0.0)
	player._is_block_held = true
	player._parry_timer = 0.05

	var hp_before := player.health.get_current_hp()
	var parry_events := {"count": 0}
	var on_parry := func(_player: Node, _source: Node) -> void:
		parry_events["count"] += 1

	EventBus.combat_parry.connect(on_parry)
	player._on_hit_received(attack, attacker)

	assert_int(parry_events["count"] as int).is_equal(1)
	assert_float(player.health.get_current_hp()).is_equal(hp_before)
	assert_float(player.tp_tracker.get_current_tp()).is_equal(Constants.TP_PARRY_BONUS)
	assert_float(player._parry_timer).is_equal(0.0)

	if EventBus.combat_parry.is_connected(on_parry):
		EventBus.combat_parry.disconnect(on_parry)


func test_lock_on_selection_and_cycle_use_shared_target_selector() -> void:
	GameState.start_new_game()
	var player: PlayerController = await _spawn_player()

	var near_enemy := CharacterBody3D.new()
	near_enemy.add_to_group(&"enemies")
	player.get_parent().add_child(near_enemy)
	_spawned_nodes.append(near_enemy)
	near_enemy.position = player.position + Vector3(4.0, 0.0, 0.0)

	var far_enemy := CharacterBody3D.new()
	far_enemy.add_to_group(&"enemies")
	player.get_parent().add_child(far_enemy)
	_spawned_nodes.append(far_enemy)
	far_enemy.position = player.position + Vector3(9.0, 0.0, 0.0)

	var out_of_range_enemy := CharacterBody3D.new()
	out_of_range_enemy.add_to_group(&"enemies")
	player.get_parent().add_child(out_of_range_enemy)
	_spawned_nodes.append(out_of_range_enemy)
	out_of_range_enemy.position = player.position + Vector3(40.0, 0.0, 0.0)

	assert_object(player._find_nearest_enemy()).is_equal(near_enemy)

	player.lock_target = near_enemy
	player._cycle_lock_target()
	assert_object(player.lock_target).is_equal(far_enemy)


func test_physics_process_recovers_from_early_fall() -> void:
	GameState.start_new_game()
	var player: PlayerController = await _spawn_player()

	player.position = Vector3(0.0, -2.5, 0.0)
	player.velocity = Vector3(1.0, -9.0, 0.5)
	player._physics_process(0.016)

	assert_float(player.position.y).is_equal_approx(0.1, 0.0001)
	assert_float(player.velocity.y).is_equal(0.0)


func _spawn_player() -> PlayerController:
	var root := Node3D.new()
	add_child(root)
	_spawned_nodes.append(root)

	var player := PlayerScene.instantiate() as PlayerController
	root.add_child(player)
	_spawned_nodes.append(player)
	await get_tree().physics_frame
	return player
