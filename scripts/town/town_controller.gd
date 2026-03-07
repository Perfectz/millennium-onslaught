extends "res://scripts/ui/split_hub_screen.gd"

const TOWN_HUB_DATA_PATHS: Dictionary = {
	&"piata": "res://resources/ui/town_hub_screen.tres",
	&"zema": "res://resources/ui/zema_hub_screen.tres",
}
const DEFAULT_TOWN_HUB_DATA_PATH := "res://resources/ui/town_hub_screen.tres"
const ShopScreenScript = preload("res://scripts/ui/shop_screen.gd")

var _town_id: StringName = &"piata"
var _town_name: String = "Local Hub"
var _town_def: TownDef


func _ready() -> void:
	_load_town_identity()
	configure(_build_town_config())
	super._ready()
	GameManager.change_phase(GameManager.Phase.TOWN)
	InputManager.set_context(InputManager.InputContext.MENU)
	EventBus.emit_checked(&"town_entered", [_town_id], {"town_id": _town_id})


func _on_entry_activated(entry: Dictionary) -> void:
	var entry_id := str(entry.get("id", ""))
	match entry_id:
		"academy_shop", "zema_shop":
			_open_shop()
		"piata_inn", "zema_inn":
			_use_inn()
		_:
			ToastSystem.show_toast(
				"Service ready: %s" % str(entry.get("menu_label", "Unknown")),
				Color(0.65, 0.92, 1.0)
			)


func _on_cancel_requested() -> void:
	_leave_town()


func _open_shop() -> void:
	if _town_def == null:
		ToastSystem.show_toast("Shop data unavailable.", Color(1.0, 0.62, 0.62))
		return
	var shop := CanvasLayer.new()
	shop.set_script(ShopScreenScript)
	shop.setup(_town_def)
	shop.closed.connect(func() -> void:
		shop.queue_free()
		_restore_focus()
	)
	add_child(shop)


func _use_inn() -> void:
	if _town_def == null or not _town_def.has_inn:
		ToastSystem.show_toast("No inn available.", Color(1.0, 0.62, 0.62))
		return
	var cost: int = int(Constants.INN_COST_BASE * _town_def.inn_cost_multiplier)
	if GameState.gold < cost:
		AudioManager.play_sfx_variant(&"ui_deny", Constants.SFX_VOL_UI_DENY)
		ToastSystem.show_toast("Not enough gold! (%dG needed)" % cost, Color(1.0, 0.55, 0.45))
		return
	GameState.gold -= cost
	# Heal all active party members to full.
	for char_id: StringName in GameState.active_party:
		var data: Dictionary = GameState.character_data.get(char_id, {})
		data["hp"] = data.get("max_hp", Constants.PLAYER_MAX_HP)
		data["tp"] = Constants.TP_MAX
	EventBus.emit_checked(&"town_inn_used", [cost], {"cost": cost})
	EventBus.emit_checked(&"rpg_gold_changed", [GameState.gold], {"new_total": GameState.gold})
	AudioManager.play_sfx_variant(&"ui_confirm", Constants.SFX_VOL_UI_CONFIRM)
	ToastSystem.show_toast("Rested at the inn! HP & TP fully restored. (-%dG)" % cost, Color(0.55, 0.9, 0.75))


func _leave_town() -> void:
	EventBus.emit_checked(&"town_exited")
	SaveManager.save_game(GameState.active_save_slot)
	GameManager.go_to_overworld()


func _load_town_identity() -> void:
	if GameState.pending_town_id != &"":
		_town_id = GameState.pending_town_id

	var town_path: String = Constants.TOWN_DATA.get(String(_town_id), "")
	if town_path.is_empty() and not Constants.TOWN_DATA.is_empty():
		var first_key: Variant = Constants.TOWN_DATA.keys()[0]
		town_path = Constants.TOWN_DATA[first_key]

	if town_path.is_empty():
		return

	var loaded_def = load(town_path)
	if loaded_def == null:
		return

	_town_def = loaded_def as TownDef
	_town_id = _town_def.town_id
	_town_name = _town_def.town_name


func _build_town_config() -> Dictionary:
	var hub_path: String = TOWN_HUB_DATA_PATHS.get(_town_id, DEFAULT_TOWN_HUB_DATA_PATH)
	var data: Resource = load(hub_path)
	if data == null or not data.has_method("to_config"):
		push_warning("TownController: missing hub screen data resource at %s" % hub_path)
		return {}

	var config: Dictionary = data.call("to_config")
	var token_keys: PackedStringArray = [
		"screen_background_title",
		"screen_background_subtitle",
		"left_header",
		"info_header",
		"hint_text",
	]
	for key in token_keys:
		var value: Variant = config.get(key, "")
		if value is String:
			config[key] = (value as String).replace("%TOWN%", _town_name)
	config["back_button_label"] = "Leave Town"
	return config
