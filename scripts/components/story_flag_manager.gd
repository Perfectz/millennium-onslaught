## Story flag manager. Key-value store of completed events for gating progression.
class_name StoryFlagManager
extends RefCounted


signal flag_set(flag_name: StringName)

var _flags: Dictionary = {}


## Set a story flag. Defaults to true for boolean flags.
func set_flag(flag_name: StringName, value: Variant = true) -> void:
	_flags[flag_name] = value
	flag_set.emit(flag_name)


## Check if a flag exists.
func has_flag(flag_name: StringName) -> bool:
	return _flags.has(flag_name)


## Get a flag value with a default fallback.
func get_flag(flag_name: StringName, default: Variant = false) -> Variant:
	return _flags.get(flag_name, default)


## Remove a flag.
func clear_flag(flag_name: StringName) -> void:
	_flags.erase(flag_name)


## Get all flags as a dictionary.
func get_all_flags() -> Dictionary:
	return _flags.duplicate()


## Replace all flags from a dictionary (e.g., loaded save data).
func load_from(flags: Dictionary) -> void:
	_flags = flags.duplicate()


## Check if a node is accessible given its required flag.
func is_node_accessible(required_flag: StringName) -> bool:
	if required_flag == &"":
		return true
	return has_flag(required_flag)
