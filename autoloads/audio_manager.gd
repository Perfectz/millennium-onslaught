## SFX pool + music player with crossfade. Event-driven via EventBus.
class_name AudioManagerSingleton
extends Node


const SFX_POOL_SIZE: int = 8
const CROSSFADE_DURATION: float = 1.0

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player_a: AudioStreamPlayer = null
var _music_player_b: AudioStreamPlayer = null
var _active_music_player: AudioStreamPlayer = null
var _is_muted: bool = false
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_sfx_pool()
	_init_music_players()
	_connect_events()


func _init_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


func _init_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = &"Music"
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = &"Music"
	add_child(_music_player_b)

	_active_music_player = _music_player_a


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
			player.volume_db = volume_db
			player.play()
			return
	# All players busy — skip this SFX rather than interrupting.


## Toggle mute state.
func toggle_mute() -> void:
	_is_muted = not _is_muted
	EventBus.audio_mute_toggled.emit(_is_muted)
	EventBus.log_event(&"audio_mute_toggled", {"muted": _is_muted})


func _on_sfx_requested(sfx_name: StringName) -> void:
	# Stub: will load and play SFX by name once audio assets exist.
	pass


func _on_music_requested(music_name: StringName, crossfade: bool) -> void:
	# Stub: will load and crossfade music tracks once audio assets exist.
	pass


func _on_mute_toggled(muted: bool) -> void:
	_is_muted = muted
