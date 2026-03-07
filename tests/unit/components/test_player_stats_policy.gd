## Pure regression coverage for player stat/equipment policy helpers.
class_name TestPlayerStatsPolicy
extends GdUnitTestSuite


const PlayerStatsPolicyScript := preload("res://scripts/components/player_stats_policy.gd")


func test_resolve_base_stats_prefers_persistent_character_record() -> void:
	var resolved := PlayerStatsPolicyScript.resolve_base_stats(
		&"alys",
		{
			&"alys": {
				"stats": {
					"strength": 9,
					"defense": 7,
				},
			},
		},
		{
			"strength": 4,
			"defense": 4,
		}
	)

	assert_int(resolved.get("strength", 0) as int).is_equal(9)
	assert_int(resolved.get("defense", 0) as int).is_equal(7)


func test_resolve_base_stats_uses_fallback_then_defaults() -> void:
	var fallback := {
		"magic": 8,
		"agility": 6,
	}

	var from_fallback := PlayerStatsPolicyScript.resolve_base_stats(&"rune", {}, fallback)
	var from_defaults := PlayerStatsPolicyScript.resolve_base_stats(&"rune", {})

	assert_int(from_fallback.get("magic", 0) as int).is_equal(8)
	assert_int(from_fallback.get("agility", 0) as int).is_equal(6)
	assert_int(from_defaults.get("strength", 0) as int).is_equal(5)
	assert_int(from_defaults.get("defense", 0) as int).is_equal(5)


func test_build_derived_stats_applies_equipment_and_defense_bonus() -> void:
	var derived := PlayerStatsPolicyScript.build_derived_stats(
		{
			"strength": 5,
			"defense": 4,
		},
		{
			"strength": 3,
			"defense": 2,
		},
		2.8
	)

	assert_int(derived.get("strength", 0) as int).is_equal(8)
	assert_int(derived.get("defense", 0) as int).is_equal(8)


func test_build_health_refresh_scales_max_hp_and_clamps_current_hp() -> void:
	var refresh := PlayerStatsPolicyScript.build_health_refresh(
		200.0,
		{
			"defense": 6,
		},
		100.0,
		5.0
	)

	assert_float(refresh.get("max_hp", 0.0) as float).is_equal(130.0)
	assert_float(refresh.get("current_hp", 0.0) as float).is_equal(130.0)
