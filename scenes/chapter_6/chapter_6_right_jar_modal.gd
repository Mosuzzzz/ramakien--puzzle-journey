extends CanvasLayer

signal searched(jar_index: int)
signal closed

const WRONG := Color("#e33a35")
const CORRECT := Color("#36c75b")

var _definition: Dictionary = {}
var _feedback_locked := false
var _searched_emitted := false
var _result_revealed := false
var _current_order: Array[int] = [0, 1, 2]

@onready var _cancel_button: Button = $Dim/CancelButton
@onready var _jar_image: TextureRect = $Dim/JarPanel/JarImage
@onready var _question_panel: PanelContainer = $Dim/QuestionPanel
@onready var _question_label: Label = $Dim/QuestionPanel/Margin/VBox/QuestionLabel
@onready var _choice_buttons: Array[Button] = [
	$Dim/QuestionPanel/Margin/VBox/Choices/Choice1,
	$Dim/QuestionPanel/Margin/VBox/Choices/Choice2,
	$Dim/QuestionPanel/Margin/VBox/Choices/Choice3,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_cancel_button.pressed.connect(cancel)
	for slot_index: int in range(_choice_buttons.size()):
		_choice_buttons[slot_index].pressed.connect(_on_choice_pressed.bind(slot_index))


func open_jar(definition: Dictionary, already_searched: bool) -> void:
	_definition = definition
	_feedback_locked = false
	_searched_emitted = false
	_result_revealed = already_searched
	_current_order = [0, 1, 2]
	_jar_image.texture = definition.get("result_texture") as Texture2D
	_question_label.text = String(definition.get("question", ""))
	_render_choices()
	_set_controls_disabled(false)
	_question_panel.visible = not already_searched
	show()
	get_tree().paused = true


func cancel() -> void:
	if _feedback_locked or not visible:
		return
	hide()
	get_tree().paused = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or _feedback_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or (event.keycode == KEY_E and _result_revealed):
			cancel()
			get_viewport().set_input_as_handled()


func _on_choice_pressed(slot_index: int) -> void:
	if _feedback_locked or _result_revealed:
		return
	var original_index := int(_choice_buttons[slot_index].get_meta("original_index", -1))
	if original_index == int(_definition.get("correct_index", -2)):
		_show_correct_feedback(slot_index)
		return
	_show_wrong_feedback(slot_index)


func _show_wrong_feedback(slot_index: int) -> void:
	_feedback_locked = true
	_set_controls_disabled(true)
	var selected_button := _choice_buttons[slot_index]
	for blink_index: int in range(4):
		selected_button.self_modulate = WRONG if blink_index % 2 == 0 else Color.WHITE
		await get_tree().create_timer(0.25, true).timeout
		if not is_instance_valid(self):
			return
	selected_button.self_modulate = Color.WHITE
	_shuffle_to_changed_order()
	_render_choices()
	_feedback_locked = false
	_set_controls_disabled(false)


func _show_correct_feedback(slot_index: int) -> void:
	_feedback_locked = true
	_set_controls_disabled(true)
	var selected_button := _choice_buttons[slot_index]
	selected_button.self_modulate = CORRECT
	await get_tree().create_timer(1.0, true).timeout
	if not is_instance_valid(self):
		return
	selected_button.self_modulate = Color.WHITE
	_reveal_result()
	_feedback_locked = false
	_set_controls_disabled(false)


func _shuffle_to_changed_order() -> void:
	var previous := _current_order.duplicate()
	_current_order.shuffle()
	if _current_order == previous:
		_current_order = [previous[1], previous[2], previous[0]]


func _render_choices() -> void:
	var choices: Array = _definition.get("choices", [])
	for slot_index: int in range(_choice_buttons.size()):
		var original_index := _current_order[slot_index]
		_choice_buttons[slot_index].text = String(choices[original_index])
		_choice_buttons[slot_index].set_meta("original_index", original_index)
		_choice_buttons[slot_index].self_modulate = Color.WHITE


func _set_controls_disabled(disabled: bool) -> void:
	_cancel_button.disabled = disabled
	for button: Button in _choice_buttons:
		button.disabled = disabled


func _reveal_result() -> void:
	_result_revealed = true
	_question_panel.hide()
	if not _searched_emitted:
		_searched_emitted = true
		searched.emit(int(_definition.get("index", -1)))
