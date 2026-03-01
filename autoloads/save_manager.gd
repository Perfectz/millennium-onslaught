## File-based save/load with atomic writes.
## Writes to temp file first, then renames to final path.
class_name SaveManagerSingleton
extends Node


const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_PREFIX: String = "save_slot_"
const SAVE_FILE_EXT: String = ".json"
const BACKUP_EXT: String = ".backup"


func _ready() -> void:
	_ensure_save_dir()


## Save persistent game state to a slot.
func save_game(slot: int = 0) -> bool:
	var data := GameState.serialize_persistent()
	var json_string := JSON.stringify(data, "\t")
	var final_path := _get_save_path(slot)
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


## Load persistent game state from a slot.
func load_game(slot: int = 0) -> bool:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		var error_msg := "Save file does not exist: " + path
		push_error(error_msg)
		EventBus.load_failed.emit(slot, error_msg)
		EventBus.log_event(&"load_failed", {"slot": slot, "error": error_msg})
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error_msg := "Failed to open save file: " + str(FileAccess.get_open_error())
		push_error(error_msg)
		EventBus.load_failed.emit(slot, error_msg)
		EventBus.log_event(&"load_failed", {"slot": slot, "error": error_msg})
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(json_string)
	if parse_err != OK:
		var error_msg := "Failed to parse save JSON: " + json.get_error_message()
		push_error(error_msg)
		EventBus.load_failed.emit(slot, error_msg)
		EventBus.log_event(&"load_failed", {"slot": slot, "error": error_msg})
		return false

	GameState.deserialize_persistent(json.data)
	EventBus.load_completed.emit(slot)
	EventBus.log_event(&"load_completed", {"slot": slot})
	return true


## Check if a save file exists for a slot.
func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## Delete a save file for a slot.
func delete_save(slot: int = 0) -> void:
	var path := _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var backup := path + BACKUP_EXT
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)


func _get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXT


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
