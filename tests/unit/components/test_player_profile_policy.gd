## Pure regression coverage for player profile/runtime synchronization helpers.
class_name TestPlayerProfilePolicy
extends GdUnitTestSuite


const PlayerProfilePolicyScript := preload("res://scripts/components/player_profile_policy.gd")


func test_resolve_active_character_id_falls_back_and_clamps_index() -> void:
	assert_str(str(PlayerProfilePolicyScript.resolve_active_character_id([], 0, &"fallback"))).is_equal("fallback")

	var active_party: Array[StringName] = [&"alys", &"chaz"]
	assert_str(str(PlayerProfilePolicyScript.resolve_active_character_id(active_party, 8))).is_equal("chaz")


func test_build_restore_snapshot_clamps_saved_values_and_computes_max_hp() -> void:
	var snapshot := PlayerProfilePolicyScript.build_restore_snapshot(
		&"alys",
		{
			"xp": 42,
			"level": 3,
			"tp": 120.0,
			"hp": 999.0,
		},
		{&"alys": "res://resources/characters/alys.tres"},
		{&"defense": 8},
		100.0,
		75.0,
		5.0
	)

	assert_int(snapshot.get("xp", 0) as int).is_equal(42)
	assert_int(snapshot.get("level", 0) as int).is_equal(3)
	assert_float(snapshot.get("tp", 0.0) as float).is_equal(75.0)
	assert_float(snapshot.get("max_hp", 0.0) as float).is_equal(140.0)
	assert_float(snapshot.get("saved_hp", 0.0) as float).is_equal(140.0)
	assert_str(snapshot.get("character_def_path", "") as String).is_equal("res://resources/characters/alys.tres")


func test_build_runtime_sync_payload_clamps_runtime_values_and_keeps_stat_points() -> void:
	var payload := PlayerProfilePolicyScript.build_runtime_sync_payload(
		&"alys",
		120.0,
		110.0,
		-3.0,
		-5,
		0,
		75.0,
		4
	)

	assert_str(payload.get("character_id", "") as String).is_equal("alys")
	assert_float(payload.get("hp", 0.0) as float).is_equal(110.0)
	assert_float(payload.get("max_hp", 0.0) as float).is_equal(110.0)
	assert_float(payload.get("tp", 0.0) as float).is_equal(0.0)
	assert_int(payload.get("xp", 0) as int).is_equal(0)
	assert_int(payload.get("level", 0) as int).is_equal(1)
	assert_int(payload.get("stat_points_available", -1) as int).is_equal(4)


func test_build_level_up_record_applies_growth_and_stat_points() -> void:
	var updated := PlayerProfilePolicyScript.build_level_up_record(
		{
			"level": 2,
			"stat_points_available": 1,
			"stats": {
				&"strength": 5,
				&"magic": 4,
			},
		},
		&"alys",
		4,
		3,
		{
			&"alys": {
				&"strength": 2,
				&"agility": 1,
			},
		},
		{
			&"strength": 1,
		}
	)

	var stats := updated.get("stats", {}) as Dictionary
	assert_int(updated.get("level", 0) as int).is_equal(4)
	assert_int(updated.get("stat_points_available", 0) as int).is_equal(4)
	assert_int(stats.get(&"strength", 0) as int).is_equal(7)
	assert_int(stats.get(&"magic", 0) as int).is_equal(4)
	assert_int(stats.get(&"agility", 0) as int).is_equal(1)
