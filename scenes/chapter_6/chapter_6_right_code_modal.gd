extends CanvasLayer

signal solved
signal closed

const SOURCE_DIGITS: Array[int] = [2, 7, 3]
const SOLUTION: Array[int] = [2, 7, 3]
const NEUTRAL := Color("#241a14")
const WRONG := Color("#e33a35")
const CORRECT := Color("#36c75b")

var _entered_digits: Array[int] = []
var _source_order: Array[int] = SOURCE_DIGITS.duplicate()
var _feedback_locked := false
var _solved_emitted := false

@onready var _cancel_button: Button = $Dim/CancelButton
@onready var _clear_button: Button = $Dim/EntryPanel/Margin/VBox/ClearButton
@onready var _source_buttons: Array[Button] = [
	$Dim/EntryPanel/Margin/VBox/DigitSources/Digit2,
	$Dim/EntryPanel/Margin/VBox/DigitSources/Digit7,
	$Dim/EntryPanel/Margin/VBox/DigitSources/Digit3,
]
@onready var _slots: Array[ColorRect] = [
	$Dim/PedestalPanel/Slots/Slot1,
	$Dim/PedestalPanel/Slots/Slot2,
	$Dim/PedestalPanel/Slots/Slot3,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_cancel_button.pressed.connect(cancel)
	_clear_button.pressed.connect(_clear_code)
	for index: int in range(_source_buttons.size()):
		_source_buttons[index].pressed.connect(_append_source_at.bind(index))


func open(discovered_digits: Array[int]) -> void:
	_entered_digits.clear()
	_feedback_locked = false
	_solved_emitted = false
	_shuffle_source_order()
	_render_sources(discovered_digits)
	_render_slots(NEUTRAL)
	_set_controls_locked(false)
	show()
	get_tree().paused = true


func cancel() -> void:
	if _feedback_locked or not visible:
		return
	_entered_digits.clear()
	hide()
	get_tree().paused = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or _feedback_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()


func _render_sources(discovered_digits: Array[int]) -> void:
	for index: int in range(_source_buttons.size()):
		var digit := _source_order[index]
		var discovered := discovered_digits.has(digit)
		_source_buttons[index].text = str(digit) if discovered else "?"
		_source_buttons[index].disabled = not discovered
		_source_buttons[index].set_meta("digit", digit)
		_source_buttons[index].set_meta("discovered", discovered)


func _shuffle_source_order() -> void:
	_source_order = SOURCE_DIGITS.duplicate()
	_source_order.shuffle()
	if _source_order == SOLUTION:
		_source_order = [7, 3, 2]


func _append_source_at(slot_index: int) -> void:
	var button := _source_buttons[slot_index]
	if _feedback_locked or not bool(button.get_meta("discovered", false)):
		return
	_append_digit(int(button.get_meta("digit", -1)))


func _append_digit(digit: int) -> void:
	if _feedback_locked or _entered_digits.size() >= 3:
		return
	_entered_digits.append(digit)
	_render_slots(NEUTRAL)
	if _entered_digits.size() == 3:
		_evaluate()


func _clear_code() -> void:
	if _feedback_locked:
		return
	_entered_digits.clear()
	_render_slots(NEUTRAL)


func _evaluate() -> void:
	_feedback_locked = true
	_set_controls_locked(true)
	if _entered_digits == SOLUTION:
		AudioManager.play_sfx(AudioManager.ANSWER_CORRECT)
		_render_slots(CORRECT)
		await get_tree().create_timer(1.0, true).timeout
		if not is_instance_valid(self):
			return
		if not _solved_emitted:
			_solved_emitted = true
			solved.emit()
		hide()
		get_tree().paused = false
		return
	AudioManager.play_sfx(AudioManager.ANSWER_WRONG)
	_render_slots(WRONG)
	await get_tree().create_timer(1.0, true).timeout
	if not is_instance_valid(self):
		return
	_entered_digits.clear()
	_feedback_locked = false
	_render_slots(NEUTRAL)
	_set_controls_locked(false)


func _render_slots(color: Color) -> void:
	for index: int in range(_slots.size()):
		_slots[index].color = color
		var label := _slots[index].get_node("Value") as Label
		label.text = str(_entered_digits[index]) if index < _entered_digits.size() else ""


func _set_controls_locked(locked: bool) -> void:
	_cancel_button.disabled = locked
	_clear_button.disabled = locked
	for button: Button in _source_buttons:
		button.disabled = locked or not bool(button.get_meta("discovered", false))
