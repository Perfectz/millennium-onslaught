## Manages string localization with language switching and fallback.
class_name LocalizationManager
extends Node


## Current language code.
var _current_language: String = "en"

## String tables: language_code → { key → translated_string }
var _string_tables: Dictionary = {}

## Fallback language if key not found in current language.
const FALLBACK_LANGUAGE: String = "en"


## Load a string table for a language from a dictionary.
func load_language(language_code: String, strings: Dictionary) -> void:
	_string_tables[language_code] = strings


## Set the active language.
func set_language(language_code: String) -> void:
	if language_code not in _string_tables:
		push_warning("LocalizationManager: Language not loaded: " + language_code)
		return
	_current_language = language_code
	EventBus.log_event(&"language_changed", {"language": language_code})


## Get current language code.
func get_language() -> String:
	return _current_language


## Look up a localized string by key.
func tr_key(key: StringName) -> String:
	# Try current language.
	if _current_language in _string_tables:
		var table: Dictionary = _string_tables[_current_language]
		if key in table:
			return table[key]
	# Try fallback language.
	if FALLBACK_LANGUAGE in _string_tables and FALLBACK_LANGUAGE != _current_language:
		var fallback_table: Dictionary = _string_tables[FALLBACK_LANGUAGE]
		if key in fallback_table:
			return fallback_table[key]
	# Return key itself as last resort.
	push_warning("LocalizationManager: Missing key '%s' in language '%s'" % [str(key), _current_language])
	return str(key)


## Look up a localized string with format arguments.
func tr_format(key: StringName, args: Array = []) -> String:
	var template: String = tr_key(key)
	if args.is_empty():
		return template
	return template % args


## Get all available language codes.
func get_available_languages() -> Array[String]:
	var languages: Array[String] = []
	for lang: String in _string_tables:
		languages.append(lang)
	return languages


## Check if a key exists in the current language.
func has_key(key: StringName) -> bool:
	if _current_language in _string_tables:
		return key in _string_tables[_current_language]
	return false


## Get all keys in the current language.
func get_all_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	if _current_language in _string_tables:
		for k: StringName in _string_tables[_current_language]:
			keys.append(k)
	return keys


## Get count of loaded strings for a language.
func get_string_count(language_code: String = "") -> int:
	var lang: String = language_code if language_code != "" else _current_language
	if lang in _string_tables:
		return _string_tables[lang].size()
	return 0
