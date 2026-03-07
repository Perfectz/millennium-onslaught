## Regression tests for stage encounter activation/tracking in WaveSystem.
class_name TestWaveSystem
extends GdUnitTestSuite


const PlayerScene := preload("res://scenes/characters/player.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy_rusher.tscn")
const RusherDef := preload("res://resources/enemies/rusher_def.tres")

var _wave_system: WaveSystem
var _player: PlayerController
var _spawned_nodes: Array[Node] = []


func before_test() -> void:
	_wave_system = WaveSystem.new()
	add_child(_wave_system)
	_spawned_nodes.append(_wave_system)

	_player = PlayerScene.instantiate() as PlayerController
	add_child(_player)
	_spawned_nodes.append(_player)

	_wave_system.player = _player
	_wave_system.enemy_container = self


func after_test() -> void:
	for idx in range(_spawned_nodes.size() - 1, -1, -1):
		var node := _spawned_nodes[idx]
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_spawned_nodes.clear()


func test_start_encounter_prescreened_wakes_dormant_enemies() -> void:
	var enemy := _spawn_enemy()
	assert_str(String(enemy.state_machine.current_state_name)).is_equal("dormant")

	_wave_system.start_encounter_prescreened(_make_encounter(), [enemy])

	assert_str(String(enemy.state_machine.current_state_name)).is_equal("idle")
	assert_int(_wave_system.get_enemies_alive()).is_equal(1)


func test_start_encounter_prescreened_resets_tracked_enemies_between_encounters() -> void:
	var first_a := _spawn_enemy()
	var first_b := _spawn_enemy()
	var second := _spawn_enemy()

	_wave_system.start_encounter_prescreened(_make_encounter(), [first_a, first_b])
	assert_int(_wave_system._spawned_enemies.size()).is_equal(2)

	_wave_system.start_encounter_prescreened(_make_encounter(), [second])

	assert_int(_wave_system._spawned_enemies.size()).is_equal(1)
	assert_bool(second in _wave_system._spawned_enemies).is_true()
	assert_bool(first_a in _wave_system._spawned_enemies).is_false()
	assert_bool(first_b in _wave_system._spawned_enemies).is_false()


func _spawn_enemy() -> EnemyController:
	var enemy := EnemyScene.instantiate() as EnemyController
	add_child(enemy)
	_spawned_nodes.append(enemy)
	enemy.configure(RusherDef, _player, true)
	return enemy


func _make_encounter() -> EncounterDef:
	var wave := WaveDef.new()
	var encounter := EncounterDef.new()
	encounter.waves = [wave]
	return encounter
