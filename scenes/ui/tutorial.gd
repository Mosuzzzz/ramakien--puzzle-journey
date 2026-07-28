extends CanvasLayer

@onready var _dim: Control = $Dim

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim.visible = false

## show the how-to-play overlay and pause the game until dismissed
func show_tutorial() -> void:
	_dim.visible = true
	get_tree().paused = true

func _close() -> void:
	_dim.visible = false
	get_tree().paused = false

func _on_start_pressed() -> void:
	_close()

func _input(event: InputEvent) -> void:
	if not _dim.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and \
			event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_SPACE, KEY_E]:
		_close()
		get_viewport().set_input_as_handled()
