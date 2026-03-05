## JSON-based configuration loader. Reads from local file, extensible to remote.
class_name RemoteConfig
extends RefCounted


## Loaded configuration values.
var _config: Dictionary = {}

## Default values used when config key is missing.
var _defaults: Dictionary = {}

## Whether config has been loaded.
var _loaded: bool = false


## Set default values (used as fallback when key not in config).
func set_defaults(defaults: Dictionary) -> void:
	_defaults = defaults


## Load configuration from a JSON file path.
func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("RemoteConfig: File not found, using defaults: " + path)
		_config = _defaults.duplicate(true)
		_loaded = true
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("RemoteConfig: Failed to open: " + path)
		_config = _defaults.duplicate(true)
		_loaded = true
		return false
	var json_str: String = file.get_as_text()
	file.close()
	return load_from_string(json_str)


## Load configuration from a JSON string.
func load_from_string(json_str: String) -> bool:
	var json := JSON.new()
	var err: int = json.parse(json_str)
	if err != OK:
		push_error("RemoteConfig: JSON parse error: " + json.get_error_message())
		_config = _defaults.duplicate(true)
		_loaded = true
		return false
	if not (json.data is Dictionary):
		push_error("RemoteConfig: Root element must be a Dictionary")
		_config = _defaults.duplicate(true)
		_loaded = true
		return false
	_config = json.data
	_loaded = true
	return true


## Get a string config value.
func get_string(key: String, default: String = "") -> String:
	var fallback: String = str(_defaults.get(key, default))
	return str(_config.get(key, fallback))


## Get an int config value.
func get_int(key: String, default: int = 0) -> int:
	var fallback: int = _defaults.get(key, default)
	return int(_config.get(key, fallback))


## Get a float config value.
func get_float(key: String, default: float = 0.0) -> float:
	var fallback: float = _defaults.get(key, default)
	return float(_config.get(key, fallback))


## Get a bool config value.
func get_bool(key: String, default: bool = false) -> bool:
	var fallback: bool = _defaults.get(key, default)
	return bool(_config.get(key, fallback))


## Get a dictionary config value.
func get_dict(key: String) -> Dictionary:
	var val = _config.get(key, _defaults.get(key, {}))
	if val is Dictionary:
		return val
	return {}


## Check if a key exists in config.
func has_key(key: String) -> bool:
	return key in _config


## Check if config is loaded.
func is_loaded() -> bool:
	return _loaded


## Get all config keys.
func get_all_keys() -> Array[String]:
	var keys: Array[String] = []
	for k: String in _config:
		keys.append(k)
	return keys
