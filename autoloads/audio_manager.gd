## SFX pool + music playlist player with crossfade. Event-driven via EventBus.
## Supports sound variation: random pitch, multiple variants, no-immediate-repeat.
class_name AudioManagerSingleton
extends Node


const SFX_POOL_SIZE: int = Constants.SFX_POOL_SIZE
const CROSSFADE_DURATION: float = 1.0
const SILENCE_DB: float = -80.0

const ACTION_MUSIC_STOP: StringName = &"music_stop"
const ACTION_MUSIC_NEXT: StringName = &"music_next"

## Pitch variation range for SFX (semitone-based).
const PITCH_VARIATION_MIN: float = 0.92
const PITCH_VARIATION_MAX: float = 1.08

const TRACK_PATHS: Dictionary = {
	&"title": "res://humandropbox/Beginning of the new millineium.mp3",
	&"stage_1": "res://assets/audio/music/stage_1.mp3",
	&"stage_2": "res://assets/audio/music/stage_2.mp3",
	&"stage_3": "res://assets/audio/music/stage_3.mp3",
	&"stage_4": "res://assets/audio/music/stage_4.mp3",
	&"stage_5": "res://assets/audio/music/stage_5.mp3",
	&"stage_6": "res://assets/audio/music/stage_6.mp3",
	&"stage_7": "res://assets/audio/music/stage_7.mp3",
	&"cutscene_intro": "res://assets/audio/music/cutscene_intro.mp3",
}

const PLAYLIST_ORDER: Array[StringName] = [
	&"title",
	&"stage_1",
	&"stage_2",
	&"stage_3",
	&"stage_4",
	&"stage_5",
	&"stage_6",
	&"stage_7",
	&"cutscene_intro",
]

const TRACK_DISPLAY_NAMES: Dictionary = {
	&"title": "Beginning of the New Millineium",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player_a: AudioStreamPlayer = null
var _music_player_b: AudioStreamPlayer = null
var _active_music_player: AudioStreamPlayer = null
var _music_fade_tween: Tween = null

var _is_muted: bool = false
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 0.8

var _music_library: Dictionary = {}
var _playlist: Array[StringName] = []
var _current_track_index: int = -1
var _music_enabled: bool = true

## Sound variation pools: sfx_name → Array[AudioStream].
var _sfx_library: Dictionary = {}
## Track last played variant index per sfx to avoid immediate repeats.
var _sfx_last_variant: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_init_sfx_pool()
	_load_sfx_library()
	_connect_events()
	_load_audio_settings()

	_playlist = PLAYLIST_ORDER.duplicate()
	_music_enabled = DisplayServer.get_name() != "headless"
	if _music_enabled:
		_init_music_players()
		_load_music_library()
	if _music_enabled and not _playlist.is_empty():
		_play_playlist_index(0, false, false)


func _exit_tree() -> void:
	_release_music_state()


func _input(event: InputEvent) -> void:
	if not _music_enabled:
		return
	if event.is_echo():
		return
	if event.is_action_pressed(ACTION_MUSIC_STOP):
		stop_music()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_MUSIC_NEXT):
		play_next_track(true)
		get_viewport().set_input_as_handled()


func _init_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


func _init_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = &"Music"
	_music_player_a.finished.connect(_on_music_finished.bind(_music_player_a))
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = &"Music"
	_music_player_b.finished.connect(_on_music_finished.bind(_music_player_b))
	add_child(_music_player_b)

	_active_music_player = _music_player_a


func _load_music_library() -> void:
	_music_library.clear()
	for track_id: StringName in TRACK_PATHS.keys():
		var path := str(TRACK_PATHS[track_id])
		var stream: AudioStream = null
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
		if stream == null and path.to_lower().ends_with(".mp3"):
			stream = _load_mp3_stream(path)
		if stream == null:
			push_error("AudioManager: Failed to load track '%s' from %s" % [track_id, path])
			continue
		_music_library[track_id] = stream


## Scan assets/audio/sfx/ subdirs and auto-register variant pools.
## Expects files named like: hit_light_001.wav .. hit_light_006.wav
func _load_sfx_library() -> void:
	var base_dir := "res://assets/audio/sfx"
	var root := DirAccess.open(base_dir)
	if root == null:
		push_warning("AudioManager: SFX directory not found: %s" % base_dir)
		return
	root.list_dir_begin()
	var subdir := root.get_next()
	while subdir != "":
		if root.current_is_dir() and not subdir.begins_with("."):
			_scan_sfx_subdir(base_dir.path_join(subdir))
		subdir = root.get_next()
	root.list_dir_end()


func _scan_sfx_subdir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	# Collect .wav files grouped by base name (strip _NNN suffix).
	var groups: Dictionary = {}  # base_name → Array[String] of paths
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.to_lower().ends_with(".wav"):
			var base := file.get_basename()  # e.g. "hit_light_001"
			# Strip trailing _NNN variant number to get the pool name.
			var underscore_idx := base.rfind("_")
			var pool_name := base
			if underscore_idx > 0:
				var suffix := base.substr(underscore_idx + 1)
				if suffix.is_valid_int():
					pool_name = base.substr(0, underscore_idx)
			if not groups.has(pool_name):
				groups[pool_name] = []
			groups[pool_name].append(dir_path.path_join(file))
		file = dir.get_next()
	dir.list_dir_end()

	# Register each group as a variant pool.
	for pool_name: String in groups.keys():
		var paths: Array = groups[pool_name]
		paths.sort()
		var streams: Array[AudioStream] = []
		for path: String in paths:
			var stream := load(path) as AudioStream
			if stream != null:
				streams.append(stream)
		if not streams.is_empty():
			register_sfx_variants(StringName(pool_name), streams)


func _connect_events() -> void:
	EventBus.audio_sfx_requested.connect(_on_sfx_requested)
	EventBus.audio_music_requested.connect(_on_music_requested)
	EventBus.audio_mute_toggled.connect(_on_mute_toggled)


## Play a sound effect from the SFX pool.
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if _is_muted:
		return

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db + _get_sfx_target_db()
			player.pitch_scale = 1.0
			player.play()
			return

	# All players busy - skip this SFX rather than interrupting.


## Play a sound effect with random pitch variation for organic feel.
func play_sfx_varied(stream: AudioStream, volume_db: float = 0.0) -> void:
	if _is_muted:
		return

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db + _get_sfx_target_db()
			player.pitch_scale = randf_range(PITCH_VARIATION_MIN, PITCH_VARIATION_MAX)
			player.play()
			return


## Register an SFX variant pool (multiple similar sounds for one logical sfx).
func register_sfx_variants(sfx_name: StringName, streams: Array[AudioStream]) -> void:
	_sfx_library[sfx_name] = streams
	_sfx_last_variant[sfx_name] = -1


## Play a random variant from a registered SFX pool with pitch variation.
## Avoids immediate repeat of the same variant.
func play_sfx_variant(sfx_name: StringName, volume_db: float = 0.0) -> void:
	if _is_muted:
		return
	if not _sfx_library.has(sfx_name):
		push_warning("AudioManager: No variant pool for '%s'" % sfx_name)
		return

	var variants: Array = _sfx_library[sfx_name]
	if variants.is_empty():
		return

	var index := _pick_variant_index(sfx_name, variants.size())
	play_sfx_varied(variants[index], volume_db)


## Play a random variant with an explicit pitch scale multiplier.
func play_sfx_variant_pitched(sfx_name: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if _is_muted:
		return
	if not _sfx_library.has(sfx_name):
		push_warning("AudioManager: No variant pool for '%s'" % sfx_name)
		return

	var variants: Array = _sfx_library[sfx_name]
	if variants.is_empty():
		return

	var index := _pick_variant_index(sfx_name, variants.size())
	var stream := variants[index] as AudioStream
	if stream == null:
		return

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db + _get_sfx_target_db()
			var random_pitch := randf_range(PITCH_VARIATION_MIN, PITCH_VARIATION_MAX)
			player.pitch_scale = clampf(pitch_scale * random_pitch, 0.6, 1.6)
			player.play()
			return


## Toggle mute state.
func toggle_mute() -> void:
	set_muted(not _is_muted)


## Set mute state explicitly.
func set_muted(muted: bool) -> void:
	if _is_muted == muted:
		return
	EventBus.emit_checked(&"audio_mute_toggled", [muted], {"muted": muted}, true)


## Get mute state.
func is_muted() -> bool:
	return _is_muted


## Set master volume [0.0..1.0].
func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_refresh_active_music_volume()
	_save_audio_settings()


## Set music volume [0.0..1.0].
func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_refresh_active_music_volume()
	_save_audio_settings()


## Set SFX volume [0.0..1.0].
func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_save_audio_settings()


## Get current master volume [0.0..1.0].
func get_master_volume() -> float:
	return _master_volume


## Get current music volume [0.0..1.0].
func get_music_volume() -> float:
	return _music_volume


## Get current SFX volume [0.0..1.0].
func get_sfx_volume() -> float:
	return _sfx_volume


## Get playlist track ids in display order.
func get_playlist_track_ids() -> Array[StringName]:
	return _playlist.duplicate()


## Get currently active track id from playlist.
func get_current_track_id() -> StringName:
	if _current_track_index < 0 or _current_track_index >= _playlist.size():
		return &""
	return _playlist[_current_track_index]


## Play a specific track id. Returns false if not found.
func play_track(track_id: StringName, crossfade: bool = true) -> bool:
	if not _music_enabled:
		return false
	var index := _playlist.find(track_id)
	if index >= 0:
		if index == _current_track_index and _active_music_player != null and _active_music_player.playing:
			return true
		_play_playlist_index(index, crossfade, true)
		return true

	if _play_track_by_id(track_id, crossfade):
		EventBus.log_event(&"audio_music_track_started", {"track_id": track_id, "index": -1})
		_emit_track_changed(track_id)
		return true
	return false


## Convert internal track id into a UI-friendly label.
func get_track_display_name(track_id: StringName) -> String:
	if TRACK_DISPLAY_NAMES.has(track_id):
		return str(TRACK_DISPLAY_NAMES[track_id])
	var raw := str(track_id).replace("_", " ")
	var words := raw.split(" ", false)
	for i in words.size():
		words[i] = words[i].capitalize()
	return " ".join(words)


func play_next_track(crossfade: bool = true) -> void:
	if not _music_enabled:
		return
	if _playlist.is_empty():
		return
	var next_index := (_current_track_index + 1) % _playlist.size()
	_play_playlist_index(next_index, crossfade, true)


func stop_music() -> void:
	if not _music_enabled:
		return
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null
	_music_player_a.stop()
	_music_player_b.stop()
	_music_player_a.stream = null
	_music_player_b.stream = null
	EventBus.log_event(&"audio_music_stopped", {})


func _on_sfx_requested(sfx_name: StringName) -> void:
	# Prefer variant pool if registered (covers .wav SFX libraries).
	if _sfx_library.has(sfx_name):
		play_sfx_variant(sfx_name)
		return
	var path := "res://assets/audio/sfx/%s.ogg" % [str(sfx_name)]
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: SFX not found: %s" % path)
		return
	play_sfx(stream)


func _on_music_requested(music_name: StringName, crossfade: bool) -> void:
	if not _music_enabled:
		return
	if music_name == &"":
		play_next_track(crossfade)
		return
	if not play_track(music_name, crossfade):
		push_warning("AudioManager: Unknown music track id: %s" % music_name)


func _on_mute_toggled(muted: bool) -> void:
	_is_muted = muted
	_refresh_active_music_volume()
	_save_audio_settings()


func _on_music_finished(player: AudioStreamPlayer) -> void:
	if not _music_enabled:
		return
	if player != _active_music_player:
		return
	play_next_track(true)


func _play_playlist_index(index: int, crossfade: bool, emit_signal: bool = true) -> void:
	if _playlist.is_empty():
		return
	if index < 0 or index >= _playlist.size():
		return

	_current_track_index = index
	var track_id := _playlist[_current_track_index]
	if _play_track_by_id(track_id, crossfade):
		EventBus.log_event(&"audio_music_track_started", {
			"track_id": track_id,
			"index": _current_track_index,
		})
		if emit_signal:
			_emit_track_changed(track_id)


func _play_track_by_id(track_id: StringName, crossfade: bool) -> bool:
	if not _music_enabled:
		return false
	var stream := _music_library.get(track_id) as AudioStream
	if stream == null:
		return false
	_play_music_stream(stream, crossfade)
	return true


func _play_music_stream(stream: AudioStream, crossfade: bool) -> void:
	if not _music_enabled:
		return
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null

	var target_db := _get_music_target_db()

	if crossfade and _active_music_player != null and _active_music_player.playing:
		var from_player := _active_music_player
		var to_player := _get_inactive_music_player()
		to_player.stop()
		to_player.stream = stream
		to_player.volume_db = SILENCE_DB
		to_player.play()
		_active_music_player = to_player

		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(from_player, "volume_db", SILENCE_DB, CROSSFADE_DURATION)
		_music_fade_tween.parallel().tween_property(to_player, "volume_db", target_db, CROSSFADE_DURATION)
		_music_fade_tween.finished.connect(func() -> void:
			from_player.stop()
			_music_fade_tween = null
		)
		return

	_music_player_a.stop()
	_music_player_b.stop()
	_active_music_player.stream = stream
	_active_music_player.volume_db = target_db
	_active_music_player.play()


func _get_inactive_music_player() -> AudioStreamPlayer:
	if _active_music_player == _music_player_a:
		return _music_player_b
	return _music_player_a


func _release_music_state() -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null
	if _music_player_a != null:
		_music_player_a.stop()
		_music_player_a.stream = null
	if _music_player_b != null:
		_music_player_b.stop()
		_music_player_b.stream = null
	_active_music_player = _music_player_a
	_current_track_index = -1
	_music_library.clear()


func _refresh_active_music_volume() -> void:
	if not _music_enabled:
		return
	if _active_music_player != null and _active_music_player.playing:
		_active_music_player.volume_db = _get_music_target_db()


func _get_music_target_db() -> float:
	if _is_muted:
		return SILENCE_DB
	return linear_to_db(clampf(_master_volume * _music_volume, 0.0001, 1.0))


func _get_sfx_target_db() -> float:
	return linear_to_db(clampf(_master_volume * _sfx_volume, 0.0001, 1.0))


func _pick_variant_index(sfx_name: StringName, variant_count: int) -> int:
	if variant_count <= 1:
		_sfx_last_variant[sfx_name] = 0
		return 0
	var last: int = _sfx_last_variant.get(sfx_name, -1)
	var index := randi() % variant_count
	if index == last:
		index = (index + 1) % variant_count
	_sfx_last_variant[sfx_name] = index
	return index


func _emit_track_changed(track_id: StringName) -> void:
	var display_name := get_track_display_name(track_id)
	EventBus.emit_checked(&"audio_track_changed", [
		track_id,
		display_name,
	], {
		"track_id": track_id,
		"display_name": display_name,
	})


func _load_mp3_stream(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var mp3 := AudioStreamMP3.new()
	mp3.data = bytes
	return mp3


## Save audio settings to disk.
func _save_audio_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", _master_volume)
	cfg.set_value("audio", "music_volume", _music_volume)
	cfg.set_value("audio", "sfx_volume", _sfx_volume)
	cfg.set_value("audio", "muted", _is_muted)
	cfg.save(Constants.AUDIO_SETTINGS_PATH)


## Load audio settings from disk.
func _load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Constants.AUDIO_SETTINGS_PATH) != OK:
		return
	_master_volume = cfg.get_value("audio", "master_volume", 1.0)
	_music_volume = cfg.get_value("audio", "music_volume", 0.8)
	_sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	_is_muted = cfg.get_value("audio", "muted", false)
	_refresh_active_music_volume()
