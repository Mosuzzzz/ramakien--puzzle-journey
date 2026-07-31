extends CanvasLayer

signal solved
signal cancelled

const BUTTON_FONT := preload("res://assets/fonts/Sarabun-Regular.ttf")
const QUESTIONS := [
	{
		"question": "ใจความสำคัญของข้อความ “ต้นไม้ให้ร่มเงา ช่วยฟอกอากาศ และเป็นที่อยู่อาศัยของสัตว์” คือข้อใด",
		"choices": ["ต้นไม้มีสีเขียว", "ต้นไม้มีประโยชน์หลายอย่าง", "สัตว์ชอบอาศัยบนต้นไม้"],
		"correct_index": 1,
	},
	{
		"question": "ข้อใดเป็นประโยคที่มีความหมายโดยนัย",
		"choices": ["พ่อเป็นเสาหลักของครอบครัว", "บ้านหลังนี้มีเสาสี่ต้น", "ช่างกำลังซ่อมเสาไม้"],
		"correct_index": 0,
	},
	{
		"question": "ข้อใดใช้คำราชาศัพท์ได้ถูกต้อง",
		"choices": ["พระมหากษัตริย์กินอาหาร", "พระมหากษัตริย์เสวยพระกระยาหาร", "พระมหากษัตริย์ทานข้าว"],
		"correct_index": 1,
	},
]
const NEUTRAL := Color("#241a14")
const CORRECT := Color("#36c75b")
const WRONG := Color("#e33a35")

var _question_index := 0
var _feedback_locked := false
var _solved_emitted := false
var _cancel_emitted := false
var _choice_orders: Array = []

@onready var _dim: ColorRect = $Dim
@onready var _instruction: PanelContainer = $Dim/Instruction
@onready var _question_panel: PanelContainer = $Dim/QuestionPanel
@onready var _question_label: Label = $Dim/QuestionPanel/Margin/VBox/QuestionLabel
@onready var _choices: VBoxContainer = $Dim/QuestionPanel/Margin/VBox/Choices
@onready var _cancel_button: Button = $Dim/CancelButton
@onready var _slots: Array[ColorRect] = [
	$Dim/ChestPanel/Slots/Slot1,
	$Dim/ChestPanel/Slots/Slot2,
	$Dim/ChestPanel/Slots/Slot3,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cancel_button.pressed.connect(cancel)
	hide()


func open() -> void:
	_reset_attempt(false)
	_feedback_locked = false
	_solved_emitted = false
	_cancel_emitted = false
	_cancel_button.disabled = false
	_instruction.show()
	_question_panel.hide()
	_dim.modulate.a = 0.0
	show()
	get_tree().paused = true
	create_tween().tween_property(_dim, "modulate:a", 1.0, 0.25)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (
		event is InputEventKey
		and event.keycode == KEY_ESCAPE
		and event.pressed
		and not event.echo
	):
		cancel()
		get_viewport().set_input_as_handled()
		return
	if not _instruction.visible or _feedback_locked:
		return
	var begin: bool = (
		event is InputEventKey
		and event.keycode == KEY_E
		and event.pressed
		and not event.echo
	)
	begin = begin or (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	)
	if begin:
		begin_questions()
		get_viewport().set_input_as_handled()


func begin_questions() -> void:
	if _feedback_locked or not visible:
		return
	_instruction.hide()
	_question_panel.show()
	_show_question()


func _show_question() -> void:
	var data: Dictionary = QUESTIONS[_question_index]
	_question_label.text = data["question"]
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var order: Array = _choice_orders[_question_index]
	for source_index: int in order:
		var button := Button.new()
		button.text = data["choices"][source_index]
		button.custom_minimum_size = Vector2(620, 46)
		button.add_theme_font_override("font", BUTTON_FONT)
		button.add_theme_font_size_override("font_size", 18)
		_choices.add_child(button)
		button.pressed.connect(_on_choice_pressed.bind(source_index))


func _on_choice_pressed(index: int) -> void:
	if _feedback_locked or _question_index >= QUESTIONS.size():
		return
	var data: Dictionary = QUESTIONS[_question_index]
	if index != int(data["correct_index"]):
		AudioManager.play_sfx(AudioManager.ANSWER_WRONG)
		_flash_wrong_answer()
		return
	AudioManager.play_sfx(AudioManager.ANSWER_CORRECT)
	_slots[_question_index].color = CORRECT
	_question_index += 1
	if _question_index >= QUESTIONS.size():
		_finish_solved()
	else:
		_show_question()


func _flash_wrong_answer() -> void:
	_feedback_locked = true
	_set_buttons_disabled(true)
	_cancel_button.disabled = true
	var slot := _slots[_question_index]
	slot.color = WRONG
	var tween := create_tween()
	for _cycle: int in range(5):
		tween.tween_property(slot, "modulate:a", 0.2, 0.1)
		tween.tween_property(slot, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(1.0, true).timeout
	_reset_attempt(true)
	_feedback_locked = false
	_cancel_button.disabled = false
	_show_question()


func cancel() -> void:
	if not visible or _feedback_locked or _cancel_emitted or _solved_emitted:
		return
	_cancel_emitted = true
	_feedback_locked = true
	var fade := create_tween()
	fade.tween_property(_dim, "modulate:a", 0.0, 0.2)
	await fade.finished
	get_tree().paused = false
	hide()
	_reset_attempt(false)
	_feedback_locked = false
	cancelled.emit()


func _finish_solved() -> void:
	if _solved_emitted:
		return
	_solved_emitted = true
	_feedback_locked = true
	var fade := create_tween()
	fade.tween_property(_dim, "modulate:a", 0.0, 0.25)
	await fade.finished
	get_tree().paused = false
	hide()
	solved.emit()


func _set_buttons_disabled(disabled: bool) -> void:
	for button: Button in _choices.get_children():
		button.disabled = disabled


func _reset_attempt(shuffle_choices: bool) -> void:
	_question_index = 0
	for slot: ColorRect in _slots:
		slot.color = NEUTRAL
		slot.modulate = Color.WHITE
	_choice_orders.clear()
	for data: Dictionary in QUESTIONS:
		var order: Array[int] = []
		for index: int in range(data["choices"].size()):
			order.append(index)
		if shuffle_choices:
			var authored_order := order.duplicate()
			order.shuffle()
			if order == authored_order and order.size() > 1:
				order.push_back(order.pop_front())
		_choice_orders.append(order)
