extends CanvasLayer

signal answered(correct: bool)

const BUTTON_FONT := preload("res://assets/fonts/Sarabun-Regular.ttf")

var _correct_index := -1

@onready var _question_label: Label = $Dim/Page/PageMargin/VBox/QuestionLabel
@onready var _choices: VBoxContainer = $Dim/Page/PageMargin/VBox/Choices


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func ask(question: String, choices: Array, correct_index: int) -> void:
	_correct_index = correct_index
	_question_label.text = question
	for c in _choices.get_children():
		c.queue_free()
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(360, 48)
		btn.add_theme_font_override("font", BUTTON_FONT)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices.add_child(btn)
	get_tree().paused = true
	show()


func _on_choice_pressed(index: int) -> void:
	get_tree().paused = false
	hide()
	answered.emit(index == _correct_index)
