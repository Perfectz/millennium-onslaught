## Unified input-intent buffer. Accepts inputs slightly before they become valid,
## then executes on the first legal frame. Prevents "eaten inputs" across states,
## hitstop, and recovery windows. Pure logic — no scene tree dependency.
##
## Categories: attack_light, attack_heavy, dodge, technique
## Policy: last-intent-wins within category, expired intents are ignored,
## clear_all on knockdown/hard-stun/death/menu.
class_name InputIntentBuffer
extends RefCounted


## One buffered intent per category. Value is the real-time timestamp (usec)
## when the intent was recorded. 0 = no intent buffered.
var _intents: Dictionary = {}

## Buffer window per category (seconds). Looked up on consume.
var _windows: Dictionary = {}

## Injectable clock function for testability. Returns microseconds.
## Defaults to Time.get_ticks_usec in production.
var _clock_func: Callable


func _init(clock: Callable = Callable()) -> void:
	if clock.is_valid():
		_clock_func = clock
	else:
		_clock_func = Time.get_ticks_usec
	_windows = {
		&"attack_light": Constants.ACTION_BUFFER_WINDOW,
		&"attack_heavy": Constants.ACTION_BUFFER_WINDOW,
		&"dodge": Constants.DODGE_BUFFER_WINDOW,
		&"technique": Constants.TECHNIQUE_BUFFER_WINDOW,
		&"spell": Constants.SPELL_BUFFER_WINDOW,
	}
	clear_all()


## Record an intent. Last-intent-wins: overwrites any previous buffered input
## in the same category. Uses real-time ticks so it survives hitstop.
func record(category: StringName) -> void:
	_intents[category] = _clock_func.call()


## Try to consume a buffered intent. Returns true if a valid (non-expired)
## intent exists for the category, then clears it. Returns false otherwise.
func consume(category: StringName) -> bool:
	var timestamp: int = _intents.get(category, 0)
	if timestamp == 0:
		return false
	var window: float = _windows.get(category, Constants.ACTION_BUFFER_WINDOW)
	var now: int = _clock_func.call()
	var age_sec := (now - timestamp) / 1_000_000.0
	if age_sec <= window:
		_intents[category] = 0
		return true
	# Expired — clear it.
	_intents[category] = 0
	return false


## Check if a buffered intent exists and is still valid, without consuming it.
func has_buffered(category: StringName) -> bool:
	var timestamp: int = _intents.get(category, 0)
	if timestamp == 0:
		return false
	var window: float = _windows.get(category, Constants.ACTION_BUFFER_WINDOW)
	var now: int = _clock_func.call()
	var age_sec := (now - timestamp) / 1_000_000.0
	return age_sec <= window


## Clear all buffered intents. Call on knockdown, hard stun, death, menu open.
func clear_all() -> void:
	_intents = {
		&"attack_light": 0,
		&"attack_heavy": 0,
		&"dodge": 0,
		&"technique": 0,
		&"spell": 0,
	}


## Clear a single category.
func clear(category: StringName) -> void:
	_intents[category] = 0
