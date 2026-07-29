extends SceneTree

const MODAL_SCENE := "res://scenes/chapter_6/chapter_6_right_code_modal.tscn"
const NEUTRAL := Color("#241a14")
const WRONG := Color("#e33a35")
const CORRECT := Color("#36c75b")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(MODAL_SCENE):
		_fail("Right code modal scene does not exist")
		return
	var modal := (load(MODAL_SCENE) as PackedScene).instantiate()
	root.add_child(modal)
	var state := {"solved": 0, "closed": 0}
	modal.solved.connect(func() -> void: state.solved += 1)
	modal.closed.connect(func() -> void: state.closed += 1)

	var only_two: Array[int] = [2]
	modal.open(only_two)
	await process_frame
	if not paused or not modal.visible:
		_fail("Opening the code modal did not pause and show")
		return
	var sources := _source_buttons(modal)
	var source_texts := _button_texts(sources)
	source_texts.sort()
	if source_texts != ["2", "?", "?"]:
		_fail("Partially discovered sources lost a digit while shuffling")
		return
	for button: Button in sources:
		var should_enable := button.text == "2"
		if button.disabled == should_enable:
			_fail("Shuffled source enabled state did not follow its displayed digit")
			return
	var cancel_button := modal.get_node("Dim/CancelButton") as Button
	if cancel_button.text != "ยกเลิก (Esc)" or cancel_button.anchor_left != 0.0:
		_fail("Code modal cancel button is not in the upper-left")
		return
	var pedestal_panel := modal.get_node("Dim/PedestalPanel") as Control
	var panel_rect := pedestal_panel.get_global_rect()
	var frame_rects := [
		Rect2(
			panel_rect.position + panel_rect.size * Vector2(0.347, 0.594),
			panel_rect.size * Vector2(0.082, 0.07)
		),
		Rect2(
			panel_rect.position + panel_rect.size * Vector2(0.457, 0.594),
			panel_rect.size * Vector2(0.086, 0.07)
		),
		Rect2(
			panel_rect.position + panel_rect.size * Vector2(0.573, 0.594),
			panel_rect.size * Vector2(0.081, 0.07)
		),
	]
	var slot_names: Array[String] = ["Slot1", "Slot2", "Slot3"]
	for index: int in slot_names.size():
		var slot_name := slot_names[index]
		var slot := modal.get_node("Dim/PedestalPanel/Slots/" + slot_name) as ColorRect
		var slot_rect := slot.get_global_rect()
		var frame_rect: Rect2 = frame_rects[index]
		if (
			not frame_rect.encloses(slot_rect)
			or slot_rect.size.distance_to(frame_rect.size) > 2.0
		):
			_fail(
				"Code slot overlay exceeded its gold frame: slot=%s band=%s"
				% [slot_rect, frame_rect]
			)
			return
	modal.cancel()
	await process_frame
	if modal.visible or paused or int(state.closed) != 1:
		_fail("Cancelling the code modal did not return to the room")
		return

	var all_digits: Array[int] = [2, 7, 3]
	modal.open(all_digits)
	await process_frame
	sources = _source_buttons(modal)
	var shuffled_order := _button_texts(sources)
	if shuffled_order == ["2", "7", "3"]:
		_fail("Code source buttons displayed the solution order")
		return
	var sorted_digits := shuffled_order.duplicate()
	sorted_digits.sort()
	if sorted_digits != ["2", "3", "7"]:
		_fail("Shuffled code sources lost or duplicated a digit")
		return
	_press_digit(modal, 2)
	_press_digit(modal, 7)
	_press_digit(modal, 2)
	if not bool(modal.get("_feedback_locked")):
		_fail("Wrong complete code did not lock feedback")
		return
	if not _all_slots_have_color(modal, WRONG):
		_fail("Wrong complete code did not turn every slot red")
		return
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	modal.call("_input", escape)
	if not modal.visible or not paused:
		_fail("Escape closed code modal during wrong feedback")
		return
	await create_timer(1.1, true).timeout
	if not _all_slots_have_color(modal, NEUTRAL):
		_fail("Wrong code did not restore neutral slots")
		return
	if not _slot_texts(modal) == ["", "", ""]:
		_fail("Wrong code did not clear all slots")
		return
	if _button_texts(_source_buttons(modal)) != shuffled_order:
		_fail("Wrong code changed the shuffled source order")
		return

	_press_digit(modal, 2)
	_press_digit(modal, 2)
	if modal.get("_entered_digits") != [2, 2]:
		_fail("Code modal did not allow a discovered digit to repeat")
		return
	modal.get_node("Dim/EntryPanel/Margin/VBox/ClearButton").pressed.emit()
	if not modal.get("_entered_digits").is_empty():
		_fail("Clear button did not clear a partial code")
		return
	if _button_texts(_source_buttons(modal)) != shuffled_order:
		_fail("Clearing code changed the shuffled source order")
		return

	_press_digit(modal, 2)
	_press_digit(modal, 7)
	_press_digit(modal, 3)
	if not _all_slots_have_color(modal, CORRECT):
		_fail("Correct 273 code did not turn every slot green")
		return
	if not bool(modal.get("_feedback_locked")):
		_fail("Correct feedback did not lock controls")
		return
	await create_timer(1.1, true).timeout
	if int(state.solved) != 1 or modal.visible or paused:
		_fail("Correct 273 code did not solve once and return to the room")
		return

	print("Chapter 6 right code modal runtime passed")
	quit(0)


func _source_buttons(modal: Node) -> Array:
	return modal.get_node("Dim/EntryPanel/Margin/VBox/DigitSources").get_children()


func _button_texts(buttons: Array) -> Array:
	var result := []
	for button: Button in buttons:
		result.append(button.text)
	return result


func _press_digit(modal: Node, digit: int) -> void:
	for button: Button in _source_buttons(modal):
		if button.text == str(digit):
			button.pressed.emit()
			return
	_fail("Could not find code source digit: %d" % digit)


func _slot_texts(modal: Node) -> Array:
	var result := []
	for slot_name: String in ["Slot1", "Slot2", "Slot3"]:
		result.append(modal.get_node("Dim/PedestalPanel/Slots/" + slot_name + "/Value").text)
	return result


func _all_slots_have_color(modal: Node, expected: Color) -> bool:
	for slot_name: String in ["Slot1", "Slot2", "Slot3"]:
		var slot := modal.get_node("Dim/PedestalPanel/Slots/" + slot_name) as ColorRect
		if slot.color != expected:
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
