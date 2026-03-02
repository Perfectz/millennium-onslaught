## Defeat screen — shown when player dies during a dungeon run.
extends CanvasLayer


signal retry_pressed

@onready var _retry_btn: Button = $Panel/VBox/RetryButton


func _ready() -> void:
	_retry_btn.pressed.connect(func() -> void: retry_pressed.emit())
	process_mode = Node.PROCESS_MODE_ALWAYS
