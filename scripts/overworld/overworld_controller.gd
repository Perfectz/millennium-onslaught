extends "res://scripts/ui/split_hub_screen.gd"

const OVERWORLD_HUB_DATA_PATH := "res://resources/ui/overworld_hub_screen.tres"

var _node_defs: Dictionary = {}


func _ready() -> void:
	_load_overworld_nodes()
	selection_changed.connect(_on_selection_changed)
	configure(_build_overworld_config())
	super._ready()
	GameManager.change_phase(GameManager.Phase.OVERWORLD)


func _on_entry_activated(entry: Dictionary) -> void:
	var node_id := StringName(entry.get("node_id", ""))
	if node_id == &"" or node_id not in _node_defs:
		ToastSystem.show_toast("Route data unavailable for this entry.", Color(1.0, 0.62, 0.62))
		return

	var node_def = _node_defs[node_id]
	if _is_node_locked(node_def):
		ToastSystem.show_toast("Route locked. Clear previous objective first.", Color(1.0, 0.62, 0.62))
		return
	if node_def.scene_path.is_empty():
		ToastSystem.show_toast("Route discovered, but destination scene is not configured.", Color(1.0, 0.84, 0.4))
		return

	GameState.current_overworld_node = node_id
	EventBus.overworld_node_entered.emit(node_id)

	var action := str(entry.get("action", ""))
	var target_id := StringName(entry.get("action_target", String(node_id)))
	match action:
		"go_town":
			GameManager.go_to_town(target_id)
		"go_dungeon":
			GameManager.go_to_character_select(target_id)
		_:
			if node_def.node_type == &"town":
				GameManager.go_to_town(node_id)
			elif node_def.node_type == &"dungeon":
				GameManager.go_to_character_select(node_id)
			else:
				ToastSystem.show_toast(
					"Stage intel synchronized: %s" % str(entry.get("menu_label", "Unknown")),
					Color(0.45, 0.9, 1.0)
				)


func _on_selection_changed(_index: int, entry: Dictionary) -> void:
	var node_id := StringName(entry.get("node_id", ""))
	if node_id == &"" or node_id not in _node_defs:
		return
	GameState.current_overworld_node = node_id
	EventBus.overworld_node_selected.emit(node_id)


func _build_overworld_config() -> Dictionary:
	var data: Resource = load(OVERWORLD_HUB_DATA_PATH)
	if data == null or not data.has_method("to_config"):
		push_warning("OverworldController: missing hub screen data resource at %s" % OVERWORLD_HUB_DATA_PATH)
		return {}

	var config: Dictionary = data.call("to_config")
	var entries_variant: Variant = config.get("entries", [])
	if entries_variant is Array:
		var entries: Array = entries_variant
		config["initial_index"] = _find_entry_index_for_node(entries, GameState.current_overworld_node)
	return config


func _load_overworld_nodes() -> void:
	_node_defs.clear()
	for path in Constants.OVERWORLD_NODES:
		var node_def = load(path)
		if node_def != null:
			_node_defs[node_def.node_id] = node_def


func _is_node_locked(node_def) -> bool:
	if node_def == null or node_def.requires_flag == &"":
		return false
	return not GameState.story_flags.get(String(node_def.requires_flag), false)


func _find_entry_index_for_node(entries: Array, node_id: StringName) -> int:
	if node_id == &"":
		return 0
	for i in entries.size():
		var entry_variant: Variant = entries[i]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if StringName(entry.get("node_id", "")) == node_id:
			return i
	return 0
