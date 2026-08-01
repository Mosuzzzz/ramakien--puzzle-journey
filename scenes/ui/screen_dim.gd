extends CanvasLayer

@onready var _dim: ColorRect = $Dim

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 4000
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.color = Color(0, 0, 0, 0)

func set_brightness(value: float) -> void:
	if not is_instance_valid(_dim):
		return
	_dim.color.a = 1.0 - clampf(value, 0.0, 1.0)
