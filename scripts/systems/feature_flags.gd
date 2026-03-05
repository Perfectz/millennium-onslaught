## Feature flag system — gates code paths at runtime.
## Reads flags from RemoteConfig, with fallback defaults.
class_name FeatureFlags
extends RefCounted


## Flag storage.
var _flags: Dictionary = {}

## Default flag values.
var _defaults: Dictionary = {}


## Set default flag values.
func set_defaults(defaults: Dictionary) -> void:
	_defaults = defaults


## Load flags from a RemoteConfig instance.
func load_from_config(config: RemoteConfig) -> void:
	var flags_dict: Dictionary = config.get_dict("feature_flags")
	for key: String in flags_dict:
		_flags[key] = flags_dict[key]


## Load flags from a dictionary directly.
func load_from_dict(flags: Dictionary) -> void:
	_flags = flags.duplicate()


## Check if a boolean feature flag is enabled.
func is_enabled(flag_name: String) -> bool:
	if flag_name in _flags:
		return bool(_flags[flag_name])
	if flag_name in _defaults:
		return bool(_defaults[flag_name])
	return false


## Get a variant flag value.
func get_value(flag_name: String, default: Variant = null) -> Variant:
	if flag_name in _flags:
		return _flags[flag_name]
	if flag_name in _defaults:
		return _defaults[flag_name]
	return default


## Get a string flag value.
func get_string(flag_name: String, default: String = "") -> String:
	return str(get_value(flag_name, default))


## Get an int flag value.
func get_int(flag_name: String, default: int = 0) -> int:
	return int(get_value(flag_name, default))


## Override a flag value at runtime (for testing).
func override_flag(flag_name: String, value: Variant) -> void:
	_flags[flag_name] = value


## Clear a runtime override.
func clear_override(flag_name: String) -> void:
	_flags.erase(flag_name)


## Check if a flag exists (in flags or defaults).
func has_flag(flag_name: String) -> bool:
	return flag_name in _flags or flag_name in _defaults


## Get all flag names.
func get_all_flags() -> Array[String]:
	var names: Dictionary = {}
	for k: String in _flags:
		names[k] = true
	for k: String in _defaults:
		names[k] = true
	var result: Array[String] = []
	for k: String in names:
		result.append(k)
	return result


## Get a report of all flags and their values.
func get_report() -> String:
	var report: String = "=== Feature Flags ===\n"
	for flag: String in get_all_flags():
		var value: Variant = get_value(flag)
		var source: String = "config" if flag in _flags else "default"
		report += "  %s = %s [%s]\n" % [flag, str(value), source]
	return report
