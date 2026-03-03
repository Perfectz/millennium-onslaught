## File-based save/load with atomic writes.
## Writes to temp file first, then renames to final path.
class_name SaveManagerSingleton
extends Node


const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_PREFIX: String = "save_slot_"
const SAVE_FILE_EXT: String = ".json"
const BACKUP_EXT: String = ".backup"

## Holds parsed JSON data from the last successful _try_load_file call.
var _last_parsed_data: Dictionary = {}


func _ready() -> void:
	_ensure_save_dir()


## Save persistent game state to a slot.
func save_game(slot: int = 0) -> bool:
	var data := GameState.serialize_persistent()
	var json_string := JSON.stringify(data, "\t")
	var final_path := get_save_path(slot)
	var temp_path := final_path + ".tmp"
	var backup_path := final_path + BACKUP_EXT

	# Write to temp file first.
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		var error_msg := "Failed to open temp save file: " + str(FileAccess.get_open_error())
		push_error(error_msg)
		EventBus.save_failed.emit(slot, error_msg)
		EventBus.log_event(&"save_failed", {"slot": slot, "error": error_msg})
		return false

	file.store_string(json_string)
	file.close()

	# Backup existing save if it exists.
	if FileAccess.file_exists(final_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(final_path, backup_path)

	# Atomic rename temp to final.
	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		var error_msg := "Failed to rename temp save to final: " + str(rename_err)
		push_error(error_msg)
		EventBus.save_failed.emit(slot, error_msg)
		EventBus.log_event(&"save_failed", {"slot": slot, "error": error_msg})
		return false

	EventBus.save_completed.emit(slot)
	EventBus.log_event(&"save_completed", {"slot": slot})
	return true


## Load persistent game state from a slot. Falls back to backup if primary is corrupt.
func load_game(slot: int = 0) -> bool:
	var path := get_save_path(slot)
	var backup_path := path + BACKUP_EXT

	# Try primary file first.
	var result := _try_load_file(path)
	if result == OK:
		var success := GameState.deserialize_persistent(_last_parsed_data)
		if success:
			EventBus.load_completed.emit(slot)
			EventBus.log_event(&"load_completed", {"slot": slot})
			return true

	# Primary failed — try backup.
	if FileAccess.file_exists(backup_path):
		push_warning("SaveManager: Primary save corrupt for slot %d, trying backup." % slot)
		result = _try_load_file(backup_path)
		if result == OK:
			var success := GameState.deserialize_persistent(_last_parsed_data)
			if success:
				EventBus.load_completed.emit(slot)
				EventBus.log_event(&"load_completed", {"slot": slot, "from_backup": true})
				return true

	var error_msg := "Failed to load save data for slot " + str(slot)
	push_error(error_msg)
	EventBus.load_failed.emit(slot, error_msg)
	EventBus.log_event(&"load_failed", {"slot": slot, "error": error_msg})
	return false


## Load save metadata for slot preview without applying to GameState.
func load_save_metadata(slot: int) -> Dictionary:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false}
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {"exists": false}
	if not json.data is Dictionary:
		return {"exists": false}
	return GameState.get_save_metadata(json.data)


## Check if a save file exists for a slot.
func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


## Delete a save file for a slot.
func delete_save(slot: int = 0) -> void:
	var path := get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var backup := path + BACKUP_EXT
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)


## Get the file path for a save slot.
func get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXT


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## Try to read and parse a JSON save file. Returns OK on success.
## Stores parsed data in _last_parsed_data.
func _try_load_file(path: String) -> int:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ERR_FILE_CANT_OPEN
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return ERR_PARSE_ERROR
	if not json.data is Dictionary:
		return ERR_INVALID_DATA
	_last_parsed_data = json.data
	return OK
