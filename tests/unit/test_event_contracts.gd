## Tests for EventContracts — validation, required fields, serialization.
extends GdUnitTestSuite


func test_hit_event_valid_with_all_fields() -> void:
	var evt := EventContracts.HitEvent.new()
	evt.attacker = Node.new()
	evt.target = Node.new()
	evt.damage = 10.0
	evt.hit_position = Vector3(1, 2, 3)
	assert_bool(evt.is_valid()).is_true()
	evt.attacker.free()
	evt.target.free()


func test_hit_event_invalid_without_attacker() -> void:
	var evt := EventContracts.HitEvent.new()
	evt.target = Node.new()
	evt.damage = 10.0
	assert_bool(evt.is_valid()).is_false()
	evt.target.free()


func test_hit_event_invalid_without_target() -> void:
	var evt := EventContracts.HitEvent.new()
	evt.attacker = Node.new()
	evt.damage = 10.0
	assert_bool(evt.is_valid()).is_false()
	evt.attacker.free()


func test_hit_event_invalid_with_zero_damage() -> void:
	var evt := EventContracts.HitEvent.new()
	evt.attacker = Node.new()
	evt.target = Node.new()
	evt.damage = 0.0
	assert_bool(evt.is_valid()).is_false()
	evt.attacker.free()
	evt.target.free()


func test_kill_event_valid() -> void:
	var evt := EventContracts.KillEvent.new()
	evt.attacker = Node.new()
	evt.target = Node.new()
	evt.target_type = &"rusher"
	assert_bool(evt.is_valid()).is_true()
	evt.attacker.free()
	evt.target.free()


func test_spawn_event_valid() -> void:
	var evt := EventContracts.SpawnEvent.new()
	evt.enemy = Node.new()
	evt.enemy_type = &"rusher"
	assert_bool(evt.is_valid()).is_true()
	evt.enemy.free()


func test_spawn_event_invalid_without_type() -> void:
	var evt := EventContracts.SpawnEvent.new()
	evt.enemy = Node.new()
	evt.enemy_type = &""
	assert_bool(evt.is_valid()).is_false()
	evt.enemy.free()


func test_damage_event_valid() -> void:
	var evt := EventContracts.DamageEvent.new()
	evt.base_damage = 10.0
	evt.final_damage = 8.0
	assert_bool(evt.is_valid()).is_true()


func test_damage_event_invalid_zero_base() -> void:
	var evt := EventContracts.DamageEvent.new()
	evt.base_damage = 0.0
	evt.final_damage = 0.0
	assert_bool(evt.is_valid()).is_false()


func test_phase_change_event_valid() -> void:
	var evt := EventContracts.PhaseChangeEvent.new()
	evt.new_phase = &"dungeon"
	evt.old_phase = &"overworld"
	assert_bool(evt.is_valid()).is_true()


func test_phase_change_event_invalid_empty_phase() -> void:
	var evt := EventContracts.PhaseChangeEvent.new()
	assert_bool(evt.is_valid()).is_false()


func test_combo_event_valid() -> void:
	var evt := EventContracts.ComboEvent.new()
	evt.player = Node.new()
	evt.step = 2
	assert_bool(evt.is_valid()).is_true()
	evt.player.free()


func test_health_change_event_valid() -> void:
	var evt := EventContracts.HealthChangeEvent.new()
	evt.max_hp = 100.0
	evt.new_hp = 50.0
	evt.source = &"damage"
	assert_bool(evt.is_valid()).is_true()


func test_xp_event_valid() -> void:
	var evt := EventContracts.XPEvent.new()
	evt.amount = 10
	evt.source_type = &"kill"
	assert_bool(evt.is_valid()).is_true()


func test_xp_event_invalid_zero_amount() -> void:
	var evt := EventContracts.XPEvent.new()
	evt.amount = 0
	assert_bool(evt.is_valid()).is_false()


func test_base_event_has_timestamp() -> void:
	var evt := EventContracts.BaseEvent.new()
	assert_int(evt.timestamp).is_greater(0)


func test_hit_event_to_dict_contains_fields() -> void:
	var evt := EventContracts.HitEvent.new()
	evt.attacker = Node.new()
	evt.target = Node.new()
	evt.damage = 25.0
	evt.is_critical = true
	evt.element = &"fire"
	var d: Dictionary = evt.to_dict()
	assert_float(d["damage"]).is_equal(25.0)
	assert_bool(d["is_critical"]).is_true()
	assert_str(d["element"]).is_equal("fire")
	evt.attacker.free()
	evt.target.free()


func test_save_event_valid() -> void:
	var evt := EventContracts.SaveEvent.new()
	evt.slot = 0
	evt.success = true
	assert_bool(evt.is_valid()).is_true()


func test_gold_event_valid() -> void:
	var evt := EventContracts.GoldEvent.new()
	evt.new_total = 500
	evt.change_amount = 100
	evt.source = &"enemy_drop"
	assert_bool(evt.is_valid()).is_true()
