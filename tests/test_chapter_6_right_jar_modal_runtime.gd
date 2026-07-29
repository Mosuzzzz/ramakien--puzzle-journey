extends SceneTree

const MODAL_SCENE := "res://scenes/chapter_6/chapter_6_right_jar_modal.tscn"
const AUTHORED_CHOICES := ["การ – กาล", "บ้าน – เรือน", "สูง – ต่ำ"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(MODAL_SCENE):
		_fail("Right jar modal scene does not exist")
		return
	var modal := (load(MODAL_SCENE) as PackedScene).instantiate()
	root.add_child(modal)
	var definition := {
		"index": 0,
		"question": "ข้อใดเป็นคำพ้องเสียง",
		"choices": AUTHORED_CHOICES,
		"correct_index": 0,
		"result_texture": load(
			"res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png"
		),
	}
	var state := {"searched": 0, "closed": 0, "index": -1}
	modal.searched.connect(func(index: int) -> void:
		state.searched += 1
		state.index = index
	)
	modal.closed.connect(func() -> void: state.closed += 1)

	modal.open_jar(definition, false)
	await process_frame
	if not paused or not modal.visible:
		_fail("Opening a jar did not show and pause the modal")
		return
	var cancel_button := modal.get_node_or_null("Dim/CancelButton") as Button
	if cancel_button == null or cancel_button.text != "ยกเลิก (Esc)":
		_fail("Jar modal has no upper-left cancel button")
		return
	if cancel_button.anchor_left != 0.0 or cancel_button.anchor_top != 0.0:
		_fail("Jar cancel button is not anchored upper-left")
		return
	if not modal.get_node("Dim/QuestionPanel").visible:
		_fail("Unsearched jar did not show its question")
		return
	var jar_panel := modal.get_node("Dim/JarPanel") as Control
	var question_panel := modal.get_node("Dim/QuestionPanel") as Control
	var jar_mouth_position := jar_panel.get_global_rect().get_center()
	if not question_panel.get_global_rect().has_point(jar_mouth_position):
		_fail("Jar question panel did not cover the jar mouth and hidden digit")
		return
	if not _choices_equal(modal, AUTHORED_CHOICES):
		_fail("First jar attempt did not use authored answer order")
		return

	var wrong_button := _find_choice(modal, "บ้าน – เรือน")
	if wrong_button == null:
		_fail("Could not find wrong jar choice")
		return
	wrong_button.pressed.emit()
	if not bool(modal.get("_feedback_locked")):
		_fail("Wrong jar answer did not lock feedback")
		return
	if wrong_button.self_modulate != Color("#e33a35"):
		_fail("Wrong jar answer did not begin with red feedback")
		return
	for button: Button in _choice_buttons(modal):
		if button != wrong_button and button.self_modulate != Color.WHITE:
			_fail("Wrong jar feedback colored an unselected choice")
			return
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	modal.call("_input", escape)
	if not modal.visible or not paused:
		_fail("Escape closed the jar during wrong-answer feedback")
		return
	await create_timer(0.3, true).timeout
	if wrong_button.self_modulate != Color.WHITE:
		_fail("Wrong jar answer did not blink back to neutral")
		return
	await create_timer(0.3, true).timeout
	if wrong_button.self_modulate != Color("#e33a35"):
		_fail("Wrong jar answer did not blink red a second time")
		return
	await create_timer(0.55, true).timeout
	if bool(modal.get("_feedback_locked")):
		_fail("Jar feedback stayed locked after one second")
		return
	if _choices_equal(modal, AUTHORED_CHOICES):
		_fail("Wrong jar answer did not shuffle choices after blinking")
		return
	var correct_button := _find_choice(modal, "การ – กาล")
	if correct_button == null:
		_fail("Could not find correct jar choice")
		return
	correct_button.pressed.emit()
	if correct_button.self_modulate != Color("#36c75b"):
		_fail("Correct jar answer did not show green feedback")
		return
	if not bool(modal.get("_feedback_locked")):
		_fail("Correct jar feedback did not lock input")
		return
	if int(state.searched) != 0 or not modal.get_node("Dim/QuestionPanel").visible:
		_fail("Correct jar answer revealed the contents before one second")
		return
	await create_timer(0.5, true).timeout
	if correct_button.self_modulate != Color("#36c75b"):
		_fail("Correct jar feedback did not stay green for one second")
		return
	await create_timer(0.6, true).timeout
	if int(state.searched) != 1 or int(state.index) != 0:
		_fail("Correct jar answer did not emit searched(0) after feedback")
		return
	if modal.get_node("Dim/QuestionPanel").visible:
		_fail("Correct jar answer did not reveal its contents after feedback")
		return
	if not modal.get_node("Dim/JarPanel/JarImage").visible:
		_fail("Jar result image was not visible")
		return

	var e_key := InputEventKey.new()
	e_key.keycode = KEY_E
	e_key.pressed = true
	modal.call("_input", e_key)
	await process_frame
	if modal.visible or paused or int(state.closed) != 1:
		_fail("E did not close a revealed jar result")
		return

	modal.open_jar(definition, true)
	await process_frame
	if modal.get_node("Dim/QuestionPanel").visible:
		_fail("Searched jar asked its question again")
		return
	cancel_button.pressed.emit()
	await process_frame
	if modal.visible or paused or int(state.closed) != 2:
		_fail("Cancel button did not close a searched jar result")
		return

	modal.open_jar(definition, false)
	await process_frame
	modal.call("cancel")
	await process_frame
	if int(state.searched) != 1:
		_fail("Cancelling before success marked a jar searched")
		return
	if modal.visible or paused or int(state.closed) != 3:
		_fail("Cancelling before success did not return to the room")
		return

	print("Chapter 6 right jar modal runtime passed")
	quit(0)


func _press_choice(modal: Node, text: String) -> void:
	var button := _find_choice(modal, text)
	if button != null:
		button.pressed.emit()
		return
	_fail("Could not find jar choice: " + text)


func _choice_buttons(modal: Node) -> Array:
	return modal.get_node("Dim/QuestionPanel/Margin/VBox/Choices").get_children()


func _find_choice(modal: Node, text: String) -> Button:
	for button: Button in _choice_buttons(modal):
		if button.text == text:
			return button
	return null


func _choices_equal(modal: Node, expected: Array) -> bool:
	var buttons := _choice_buttons(modal)
	if buttons.size() != expected.size():
		return false
	for index: int in range(buttons.size()):
		if buttons[index].text != String(expected[index]):
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
