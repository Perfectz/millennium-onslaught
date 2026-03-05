## Tests for AccessibilityManager — difficulty modifiers, colorblind, assists.
extends GdUnitTestSuite


var _access: AccessibilityManager


func before_test() -> void:
	_access = AccessibilityManager.new()
	add_child(_access)


func after_test() -> void:
	_access.queue_free()


func test_default_difficulty_is_normal() -> void:
	assert_int(_access.get_difficulty()).is_equal(AccessibilityManager.DifficultyPreset.NORMAL)


func test_easy_reduces_damage_taken() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.EASY)
	var modified: float = _access.apply_damage_modifier(100.0)
	assert_float(modified).is_less(100.0)


func test_normal_no_damage_change() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.NORMAL)
	var modified: float = _access.apply_damage_modifier(100.0)
	assert_float(modified).is_equal(100.0)


func test_hard_increases_damage_taken() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.HARD)
	var modified: float = _access.apply_damage_modifier(100.0)
	assert_float(modified).is_greater(100.0)


func test_easy_increases_player_hp() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.EASY)
	var hp: float = _access.apply_player_hp_modifier(100.0)
	assert_float(hp).is_greater(100.0)


func test_easy_decreases_enemy_hp() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.EASY)
	var hp: float = _access.apply_enemy_hp_modifier(100.0)
	assert_float(hp).is_less(100.0)


func test_hard_decreases_player_hp() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.HARD)
	var hp: float = _access.apply_player_hp_modifier(100.0)
	assert_float(hp).is_less(100.0)


func test_colorblind_mode_default_none() -> void:
	assert_int(_access.get_colorblind_mode()).is_equal(AccessibilityManager.ColorblindMode.NONE)


func test_set_colorblind_mode() -> void:
	_access.set_colorblind_mode(AccessibilityManager.ColorblindMode.PROTANOPIA)
	assert_int(_access.get_colorblind_mode()).is_equal(AccessibilityManager.ColorblindMode.PROTANOPIA)


func test_auto_combo_default_off() -> void:
	assert_bool(_access.is_auto_combo_enabled()).is_false()


func test_auto_combo_toggle() -> void:
	_access.set_auto_combo(true)
	assert_bool(_access.is_auto_combo_enabled()).is_true()
	_access.set_auto_combo(false)
	assert_bool(_access.is_auto_combo_enabled()).is_false()


func test_settings_round_trip() -> void:
	_access.set_difficulty(AccessibilityManager.DifficultyPreset.EASY)
	_access.set_colorblind_mode(AccessibilityManager.ColorblindMode.DEUTERANOPIA)
	_access.set_auto_combo(true)
	var settings: Dictionary = _access.get_settings()
	var new_access := AccessibilityManager.new()
	add_child(new_access)
	new_access.load_settings(settings)
	assert_int(new_access.get_difficulty()).is_equal(AccessibilityManager.DifficultyPreset.EASY)
	assert_bool(new_access.is_auto_combo_enabled()).is_true()
	new_access.queue_free()
