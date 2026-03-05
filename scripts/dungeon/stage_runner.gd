## Manages dungeon room sequencing and the video background layer.
## CRITICAL: Video background renders on CanvasLayer(layer=-1) to stay BEHIND 3D content.
## 3D gameplay renders at the default viewport layer (0).
## UI CanvasLayer renders at layer 10 (on top of everything).
class_name StageRunner
extends Node3D


## The video background canvas layer — MUST be layer -1.
var _video_canvas: CanvasLayer = null

## The video stream player.
var _video_player: VideoStreamPlayer = null

## Current room index.
var _current_room_index: int = 0

## Total rooms in this stage.
var _total_rooms: int = 0

## Room scene references.
var _room_scenes: Array[PackedScene] = []

## Currently loaded room instance.
var _current_room: Node3D = null

## Wave system for the current room.
var _wave_system: WaveSystem = null


func _ready() -> void:
	_add_video_background()
	EventBus.dungeon_room_cleared.connect(_on_room_cleared)


## Initialize the stage with room scenes.
func setup(room_scenes: Array[PackedScene], wave_system: WaveSystem) -> void:
	_room_scenes = room_scenes
	_total_rooms = room_scenes.size()
	_wave_system = wave_system
	_current_room_index = 0


## Start the stage by loading the first room.
func start_stage() -> void:
	if _room_scenes.is_empty():
		push_error("StageRunner: No room scenes loaded")
		return
	_load_room(_current_room_index)
	GameState.current_dungeon_id = &"stage_01"
	GameState.current_room_index = _current_room_index
	EventBus.dungeon_entered.emit(&"stage_01")


## Load a specific room by index.
func _load_room(index: int) -> void:
	# Remove previous room.
	if _current_room != null:
		_current_room.queue_free()
		_current_room = null
	if index >= _room_scenes.size():
		push_error("StageRunner: Room index out of bounds: " + str(index))
		return
	_current_room = _room_scenes[index].instantiate() as Node3D
	add_child(_current_room)
	# Ensure room renders in front of video background (automatic — it's Node3D at layer 0).
	EventBus.dungeon_room_entered.emit(index)
	EventBus.log_event(&"dungeon_room_entered", {"room": index})


## Advance to the next room.
func advance_room() -> void:
	_current_room_index += 1
	GameState.current_room_index = _current_room_index
	if _current_room_index >= _total_rooms:
		_stage_completed()
	else:
		_load_room(_current_room_index)


## Set up the video background with CORRECT Z-ordering.
## This is the fix for the visibility bug: video renders BEHIND 3D content.
func _add_video_background() -> void:
	# Create CanvasLayer at layer -1 — this renders BEHIND the 3D viewport.
	# The 3D viewport renders at the default layer (between canvas layers).
	# Without this, the video would render ON TOP of 3D content, hiding players and enemies.
	_video_canvas = CanvasLayer.new()
	_video_canvas.layer = -1  # CRITICAL: negative layer = behind 3D
	_video_canvas.name = "VideoBackground"
	add_child(_video_canvas)
	# Create the video player filling the viewport.
	_video_player = VideoStreamPlayer.new()
	_video_player.name = "VideoStreamPlayer"
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.autoplay = true
	_video_player.loop = true
	# Set to stretch fill the screen.
	_video_player.custom_minimum_size = Vector2(1920, 1080)
	_video_canvas.add_child(_video_player)


## Set the video stream for the background.
func set_video_stream(stream: VideoStream) -> void:
	if _video_player:
		_video_player.stream = stream
		_video_player.play()


## Stop and hide the video background.
func hide_video_background() -> void:
	if _video_canvas:
		_video_canvas.visible = false


## Show the video background.
func show_video_background() -> void:
	if _video_canvas:
		_video_canvas.visible = true


func _on_room_cleared(_room_index: int) -> void:
	# When wave system says room is cleared, advance.
	advance_room()


func _stage_completed() -> void:
	GameState.bank_dungeon_rewards()
	EventBus.dungeon_completed.emit(GameState.current_dungeon_id)
	EventBus.log_event(&"dungeon_completed", {"dungeon": GameState.current_dungeon_id})
