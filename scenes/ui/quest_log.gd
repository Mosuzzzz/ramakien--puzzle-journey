extends CanvasLayer

@onready var _box: Control = $Box
@onready var _text_label: Label = $Box/Margin/TextLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box.hide()

func set_quest(text: String) -> void:
	_text_label.text = text
	_box.show()

func clear() -> void:
	_box.hide()
