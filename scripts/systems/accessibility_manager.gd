## Manages accessibility features: colorblind mode, difficulty scaling, input assists.
class_name AccessibilityManager
extends Node


## Colorblind mode types.
enum ColorblindMode {
	NONE,
	PROTANOPIA,   # Red-weak.
	DEUTERANOPIA, # Green-weak.
	TRITANOPIA,   # Blue-weak.
}

## Difficulty presets.
enum DifficultyPreset {
	EASY,
	NORMAL,
	HARD,
}

## Current colorblind mode.
var _colorblind_mode: ColorblindMode = ColorblindMode.NONE

## Current difficulty.
var _difficulty: DifficultyPreset = DifficultyPreset.NORMAL

## Difficulty modifiers applied to gameplay.
var _damage_taken_multiplier: float = 1.0
var _player_hp_multiplier: float = 1.0
var _enemy_hp_multiplier: float = 1.0

## Input assist: auto-combo (mash attack to get full combo).
var _auto_combo_enabled: bool = false

## Screen reader hint text.
var _screen_reader_enabled: bool = false


## Set colorblind mode.
func set_colorblind_mode(mode: ColorblindMode) -> void:
	_colorblind_mode = mode
	# Apply shader or color remap.
	EventBus.log_event(&"accessibility_colorblind_changed", {"mode": mode})


## Get current colorblind mode.
func get_colorblind_mode() -> ColorblindMode:
	return _colorblind_mode


## Set difficulty preset.
func set_difficulty(preset: DifficultyPreset) -> void:
	_difficulty = preset
	match preset:
		DifficultyPreset.EASY:
			_damage_taken_multiplier = 0.5
			_player_hp_multiplier = 1.5
			_enemy_hp_multiplier = 0.75
		DifficultyPreset.NORMAL:
			_damage_taken_multiplier = 1.0
			_player_hp_multiplier = 1.0
			_enemy_hp_multiplier = 1.0
		DifficultyPreset.HARD:
			_damage_taken_multiplier = 1.5
			_player_hp_multiplier = 0.8
			_enemy_hp_multiplier = 1.25
	EventBus.log_event(&"accessibility_difficulty_changed", {"preset": preset})


## Get current difficulty.
func get_difficulty() -> DifficultyPreset:
	return _difficulty


## Apply damage modifier for accessibility.
func apply_damage_modifier(damage: float) -> float:
	return damage * _damage_taken_multiplier


## Apply player HP modifier.
func apply_player_hp_modifier(base_hp: float) -> float:
	return base_hp * _player_hp_multiplier


## Apply enemy HP modifier.
func apply_enemy_hp_modifier(base_hp: float) -> float:
	return base_hp * _enemy_hp_multiplier


## Enable/disable auto-combo assist.
func set_auto_combo(enabled: bool) -> void:
	_auto_combo_enabled = enabled


## Check if auto-combo is enabled.
func is_auto_combo_enabled() -> bool:
	return _auto_combo_enabled


## Enable/disable screen reader hints.
func set_screen_reader(enabled: bool) -> void:
	_screen_reader_enabled = enabled


## Check if screen reader is enabled.
func is_screen_reader_enabled() -> bool:
	return _screen_reader_enabled


## Get all current settings as a dictionary (for save/load).
func get_settings() -> Dictionary:
	return {
		"colorblind_mode": _colorblind_mode,
		"difficulty": _difficulty,
		"auto_combo": _auto_combo_enabled,
		"screen_reader": _screen_reader_enabled,
	}


## Load settings from a dictionary.
func load_settings(settings: Dictionary) -> void:
	if "colorblind_mode" in settings:
		set_colorblind_mode(settings["colorblind_mode"] as ColorblindMode)
	if "difficulty" in settings:
		set_difficulty(settings["difficulty"] as DifficultyPreset)
	if "auto_combo" in settings:
		set_auto_combo(settings["auto_combo"])
	if "screen_reader" in settings:
		set_screen_reader(settings["screen_reader"])
