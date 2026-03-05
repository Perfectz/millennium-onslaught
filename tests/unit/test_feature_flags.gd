## Tests for FeatureFlags — enable/disable, defaults, overrides.
extends GdUnitTestSuite


var _flags: FeatureFlags


func before_test() -> void:
	_flags = FeatureFlags.new()
	_flags.set_defaults({
		"new_combat_system": false,
		"daily_challenge": true,
		"max_enemies": 20,
	})


func test_flag_default_false() -> void:
	assert_bool(_flags.is_enabled("new_combat_system")).is_false()


func test_flag_default_true() -> void:
	assert_bool(_flags.is_enabled("daily_challenge")).is_true()


func test_unknown_flag_returns_false() -> void:
	assert_bool(_flags.is_enabled("nonexistent_flag")).is_false()


func test_load_from_dict_overrides_defaults() -> void:
	_flags.load_from_dict({"new_combat_system": true})
	assert_bool(_flags.is_enabled("new_combat_system")).is_true()


func test_override_flag() -> void:
	_flags.override_flag("new_combat_system", true)
	assert_bool(_flags.is_enabled("new_combat_system")).is_true()


func test_clear_override_reverts_to_default() -> void:
	_flags.override_flag("new_combat_system", true)
	assert_bool(_flags.is_enabled("new_combat_system")).is_true()
	_flags.clear_override("new_combat_system")
	assert_bool(_flags.is_enabled("new_combat_system")).is_false()


func test_get_int_value() -> void:
	assert_int(_flags.get_int("max_enemies")).is_equal(20)


func test_get_string_value() -> void:
	_flags.override_flag("mode", "hard")
	assert_str(_flags.get_string("mode")).is_equal("hard")


func test_has_flag_from_defaults() -> void:
	assert_bool(_flags.has_flag("daily_challenge")).is_true()


func test_has_flag_unknown() -> void:
	assert_bool(_flags.has_flag("nonexistent")).is_false()


func test_get_all_flags_includes_both() -> void:
	_flags.override_flag("custom_flag", true)
	var all_flags: Array[String] = _flags.get_all_flags()
	assert_int(all_flags.size()).is_greater_equal(4)  # 3 defaults + 1 override


func test_get_value_with_default_fallback() -> void:
	var val: Variant = _flags.get_value("nonexistent", "fallback")
	assert_str(str(val)).is_equal("fallback")


func test_load_from_config() -> void:
	var config := RemoteConfig.new()
	config.load_from_string('{"feature_flags": {"new_combat_system": true, "beta_mode": true}}')
	_flags.load_from_config(config)
	assert_bool(_flags.is_enabled("new_combat_system")).is_true()
	assert_bool(_flags.is_enabled("beta_mode")).is_true()
