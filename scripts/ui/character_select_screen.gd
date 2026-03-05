## Character selection screen shown before entering a dungeon.
## Builds entries from GameState.party_roster and lets the player pick who to play as.
extends "res://scripts/ui/split_hub_screen.gd"


func _ready() -> void:
	configure(_build_character_select_config())
	super._ready()


func _on_entry_activated(entry: Dictionary) -> void:
	var char_id := StringName(entry.get("character_id", ""))
	if char_id == &"":
		return
	# Set selected character as the active party lead.
	if char_id in GameState.active_party:
		GameState.active_party.erase(char_id)
	GameState.active_party.push_front(char_id)
	# Proceed to dungeon.
	var dungeon_id := GameState.pending_dungeon_id
	if dungeon_id != &"":
		GameManager.go_to_dungeon(dungeon_id)
	else:
		GameManager.go_to_overworld()


func _on_cancel_requested() -> void:
	GameState.pending_dungeon_id = &""
	GameManager.go_to_overworld()


func _build_character_select_config() -> Dictionary:
	var entries: Array[Dictionary] = []
	for char_id in GameState.party_roster:
		var def_path: String = Constants.CHARACTER_DEFS.get(char_id, "")
		if def_path.is_empty():
			continue
		var def := load(def_path) as CharacterDef
		if def == null:
			continue
		var char_data: Dictionary = GameState.character_data.get(char_id, {})
		var level: int = char_data.get("level", 1)
		var stats: Dictionary = def.base_stats
		var stat_text := "STR %d  MAG %d  DEF %d  AGI %d" % [
			stats.get("strength", 0), stats.get("magic", 0),
			stats.get("defense", 0), stats.get("agility", 0),
		]
		var accent := _character_accent(char_id)
		entries.append({
			"character_id": String(char_id),
			"menu_label": def.display_name,
			"title": def.display_name,
			"level": "Lv %d  •  %s" % [level, def.role],
			"description": stat_text,
			"accent": accent,
			"speaker": def.display_name,
			"dialogue": _character_dialogue(char_id),
			"portrait_code": "%s / %s" % [def.display_name.to_upper(), def.role.to_upper()],
			"portrait_image": "res://assets/textures/portraits/%s_portrait.png" % String(char_id),
			"context_title": "CHARACTER PROFILE",
			"context_subtitle": def.role.to_upper(),
			"story_title": "TECHNIQUES",
			"story_subtitle": _techniques_summary(def),
		})
	# Pre-select the current active character.
	var initial_index := 0
	if not GameState.active_party.is_empty():
		var active_id := GameState.active_party[0]
		for i in entries.size():
			if StringName(entries[i].get("character_id", "")) == active_id:
				initial_index = i
				break
	return {
		"screen_background_title": "PARTY FORMATION",
		"screen_background_subtitle": "SELECT OPERATIVE FOR DEPLOYMENT",
		"left_header": "Roster",
		"info_header": "Operative Profile",
		"hint_text": "UP/DOWN: SELECT  |  ENTER: DEPLOY  |  ESC: CANCEL",
		"default_accent": Color(0.37, 0.92, 1.0, 1.0),
		"dialogue_header": "OPERATIVE",
		"back_button_label": "Cancel",
		"initial_index": initial_index,
		"entries": entries,
	}


## Accent color per character.
func _character_accent(char_id: StringName) -> Color:
	match char_id:
		&"alys":
			return Color(0.42, 0.68, 1.0, 1.0)
		&"chaz":
			return Color(0.3, 0.5, 1.0, 1.0)
		&"rune":
			return Color(0.6, 0.35, 0.9, 1.0)
		&"wren":
			return Color(0.4, 0.85, 0.5, 1.0)
	return Color(0.37, 0.92, 1.0, 1.0)


## Flavour dialogue per character.
func _character_dialogue(char_id: StringName) -> String:
	match char_id:
		&"alys":
			return "Ready for another job. Let's make it quick and clean."
		&"chaz":
			return "I've been training hard. I won't let you down!"
		&"rune":
			return "Stand aside. I'll handle this with a flick of my wrist."
		&"wren":
			return "Combat systems online. Awaiting deployment orders."
	return "Standing by."


## Summarize techniques for the info panel.
func _techniques_summary(def: CharacterDef) -> String:
	if def.techniques.is_empty():
		return "NO TECHNIQUES AVAILABLE"
	var names: PackedStringArray = []
	for tech in def.techniques:
		if tech and not tech.display_name.is_empty():
			names.append(tech.display_name)
	if names.is_empty():
		return "TECHNIQUES CLASSIFIED"
	return " / ".join(names)
