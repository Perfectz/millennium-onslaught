## Contract tests for canonical typed combat payloads and EventBus emission.
class_name TestCombatEventContracts
extends GdUnitTestSuite


var _attacker: Node3D
var _target: Node3D
var _attack: AttackDef
var _captured_hit_event: CombatHitEvent = null
var _captured_kill_event: CombatKillEvent = null


func before_test() -> void:
	_attacker = Node3D.new()
	_target = Node3D.new()
	add_child(_attacker)
	add_child(_target)
	_attacker.position = Vector3(-1.0, 0.0, 0.0)
	_target.position = Vector3(2.0, 0.0, 0.0)
	_attack = AttackDef.new()
	_attack.attack_name = &"contract_test"
	_attack.base_damage = 10.0
	_attack.damage_multiplier = 1.0
	_captured_hit_event = null
	_captured_kill_event = null


func after_test() -> void:
	if EventBus.combat_hit_event.is_connected(_capture_hit_event):
		EventBus.combat_hit_event.disconnect(_capture_hit_event)
	if EventBus.combat_kill_event.is_connected(_capture_kill_event):
		EventBus.combat_kill_event.disconnect(_capture_kill_event)
	if is_instance_valid(_attacker):
		_attacker.queue_free()
	if is_instance_valid(_target):
		_target.queue_free()
	_attacker = null
	_target = null
	_attack = null
	_captured_hit_event = null
	_captured_kill_event = null


func test_combat_hit_event_schema_v1_payload_is_explicit() -> void:
	var event := CombatHitEvent.from_values(_attacker, _target, 12.5, Vector3(1.0, 2.0, 3.0), _attack)
	assert_int(event.schema_version).is_equal(1)
	assert_object(event.attacker).is_same(_attacker)
	assert_object(event.target).is_same(_target)
	assert_float(event.damage).is_equal(12.5)
	assert_vector(event.hit_position).is_equal(Vector3(1.0, 2.0, 3.0))
	assert_object(event.attack_data).is_same(_attack)


func test_combat_kill_event_schema_v1_payload_is_explicit() -> void:
	var event := CombatKillEvent.from_values(_attacker, _target, Vector3(4.0, 5.0, 6.0), 30.0, _attack)
	assert_int(event.schema_version).is_equal(1)
	assert_object(event.attacker).is_same(_attacker)
	assert_object(event.target).is_same(_target)
	assert_vector(event.kill_position).is_equal(Vector3(4.0, 5.0, 6.0))
	assert_float(event.damage).is_equal(30.0)
	assert_object(event.attack_data).is_same(_attack)


func test_process_hit_emits_typed_and_legacy_hit_contracts() -> void:
	var health := HealthComponent.new(100.0)
	EventBus.combat_hit_event.connect(_capture_hit_event, CONNECT_ONE_SHOT)
	var monitor := monitor_signals(EventBus, false)

	CombatSystem.process_hit(health, _attack, _attacker, _target)

	assert_object(_captured_hit_event).is_not_null()
	var typed_event := _captured_hit_event
	assert_object(typed_event).is_not_null()
	assert_float(typed_event.damage).is_equal(10.0)
	assert_object(typed_event.attack_data).is_same(_attack)
	await assert_signal(monitor).is_emitted("combat_hit_event", [typed_event])
	await assert_signal(monitor).is_emitted("combat_hit_landed", [_attacker, _target, 10.0, _target.global_position, _attack])


func test_process_hit_emits_typed_and_legacy_kill_contracts() -> void:
	var health := HealthComponent.new(5.0)
	EventBus.combat_kill_event.connect(_capture_kill_event, CONNECT_ONE_SHOT)
	var monitor := monitor_signals(EventBus, false)

	CombatSystem.process_hit(health, _attack, _attacker, _target)

	assert_object(_captured_kill_event).is_not_null()
	var typed_event := _captured_kill_event
	assert_object(typed_event).is_not_null()
	assert_float(typed_event.damage).is_equal(10.0)
	assert_object(typed_event.attack_data).is_same(_attack)
	await assert_signal(monitor).is_emitted("combat_kill_event", [typed_event])
	await assert_signal(monitor).is_emitted("combat_kill", [_attacker, _target, _target.global_position])


func _capture_hit_event(event: CombatHitEvent) -> void:
	_captured_hit_event = event


func _capture_kill_event(event: CombatKillEvent) -> void:
	_captured_kill_event = event
