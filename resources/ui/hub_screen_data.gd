class_name HubScreenData
extends Resource


@export var screen_background_title: String = "BACKGROUND FEED"
@export var screen_background_subtitle: String = "NO IMAGE ATTACHED"
@export var left_header: String = "LOCATIONS"
@export var info_header: String = "MISSION BRIEF"
@export var hint_text: String = "UP/DOWN: SELECT  |  ENTER: CONFIRM  |  START: PAUSE"
@export var default_accent: Color = Color(0.37, 0.92, 1.0, 1.0)
@export var dialogue_header: String = "COMMS"
@export var entries: Array[Dictionary] = []


func to_config() -> Dictionary:
	return {
		"screen_background_title": screen_background_title,
		"screen_background_subtitle": screen_background_subtitle,
		"left_header": left_header,
		"info_header": info_header,
		"hint_text": hint_text,
		"default_accent": default_accent,
		"dialogue_header": dialogue_header,
		"entries": entries.duplicate(true),
	}
