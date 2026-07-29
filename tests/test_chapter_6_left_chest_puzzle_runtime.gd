extends SceneTree

const PUZZLE_SCENE := "res://scenes/chapter_6/chapter_6_left_chest_puzzle.tscn"
const QUESTIONS := [
	["ใจความสำคัญของข้อความ “ต้นไม้ให้ร่มเงา ช่วยฟอกอากาศ และเป็นที่อยู่อาศัยของสัตว์” คือข้อใด",
		["ต้นไม้มีสีเขียว", "ต้นไม้มีประโยชน์หลายอย่าง", "สัตว์ชอบอาศัยบนต้นไม้"], 1],
	["ข้อใดเป็นประโยคที่มีความหมายโดยนัย",
		["พ่อเป็นเสาหลักของครอบครัว", "บ้านหลังนี้มีเสาสี่ต้น", "ช่างกำลังซ่อมเสาไม้"], 0],
	["ข้อใดใช้คำราชาศัพท์ได้ถูกต้อง",
		["พระมหากษัตริย์กินอาหาร", "พระมหากษัตริย์เสวยพระกระยาหาร", "พระมหากษัตริย์ทานข้าว"], 1],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(PUZZLE_SCENE):
		_fail("Left chest puzzle scene does not exist")
		return
	var puzzle := (load(PUZZLE_SCENE) as PackedScene).instantiate()
	root.add_child(puzzle)
	puzzle.call("open")
	await create_timer(0.3, true).timeout
	if not paused or not puzzle.visible:
		_fail("Opening puzzle did not show and pause")
		return
	if not puzzle.has_signal("cancelled"):
		_fail("Puzzle does not expose a cancelled signal")
		return
	if puzzle.get_node_or_null("Dim/Instruction/VBox/StartHint") == null:
		_fail("Puzzle does not show the E start hint")
		return
	if puzzle.get_node("Dim/Instruction/VBox/Label").text != "ตอบคำถามให้ถูกต้องเพื่อปลดล็อกกล่องนี้":
		_fail("Puzzle instruction text is wrong")
		return
	if puzzle.get_node("Dim/Instruction/VBox/StartHint").text != "กด E เพื่อเริ่ม":
		_fail("Puzzle start hint text is wrong")
		return
	if not _slots_are_aligned(puzzle):
		return
	puzzle.call("begin_questions")
	if not _matches(puzzle, 0):
		return
	_press_choice_text(puzzle, "ต้นไม้มีประโยชน์หลายอย่าง")
	if int(puzzle.get("_question_index")) != 1:
		_fail("Correct first answer did not advance")
		return
	puzzle.call("_on_choice_pressed", 1)
	if not bool(puzzle.get("_feedback_locked")):
		_fail("Wrong answer did not lock feedback")
		return
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	puzzle.call("_input", escape)
	if not puzzle.visible or not paused:
		_fail("Puzzle cancelled while wrong-answer feedback was locked")
		return
	await create_timer(1.1, true).timeout
	if int(puzzle.get("_question_index")) != 0 or not _matches(puzzle, 0):
		_fail("Wrong answer did not restart from question 1")
		return
	if not _all_slots_are_neutral(puzzle):
		_fail("Wrong answer did not reset all slot progress")
		return
	if _choices_match_authored_order(puzzle, 0):
		_fail("Wrong answer did not shuffle the answer positions")
		return
	_press_choice_text(puzzle, "ต้นไม้มีประโยชน์หลายอย่าง")
	if int(puzzle.get("_question_index")) != 1:
		_fail("Shuffled correct answer was not evaluated by its original index")
		return

	var cancelled_state := {"count": 0}
	puzzle.cancelled.connect(func() -> void: cancelled_state["count"] += 1)
	puzzle.call("_input", escape)
	await create_timer(0.25, true).timeout
	if int(cancelled_state["count"]) != 1 or puzzle.visible or paused:
		_fail("Escape did not cancel and return to the room")
		return

	puzzle.call("open")
	await create_timer(0.3, true).timeout
	puzzle.call("begin_questions")
	var cancel_button := puzzle.get_node_or_null("Dim/CancelButton") as Button
	if cancel_button == null:
		_fail("Cancel button is not a direct child of the dim overlay")
		return
	if cancel_button.anchor_left != 0.0 or cancel_button.anchor_top != 0.0:
		_fail("Cancel button is not anchored to the upper-left viewport corner")
		return
	if cancel_button.offset_left != 24.0 or cancel_button.offset_top != 24.0:
		_fail("Cancel button does not keep the required 24-pixel margin")
		return
	cancel_button.pressed.emit()
	await create_timer(0.25, true).timeout
	if int(cancelled_state["count"]) != 2 or puzzle.visible or paused:
		_fail("On-screen cancel button did not return to the room")
		return

	puzzle.call("open")
	await create_timer(0.3, true).timeout
	puzzle.call("begin_questions")
	var solved_state := {"count": 0}
	puzzle.solved.connect(func() -> void: solved_state["count"] += 1)
	for index: int in range(QUESTIONS.size()):
		_press_choice_text(puzzle, String(QUESTIONS[index][1][QUESTIONS[index][2]]))
		if index < QUESTIONS.size() - 1 and not _matches(puzzle, index + 1):
			return
	await create_timer(0.35, true).timeout
	if int(solved_state["count"]) != 1 or paused or puzzle.visible:
		_fail("Three correct answers did not solve and close once")
		return
	print("Chapter 6 left chest puzzle runtime passed")
	quit(0)


func _matches(puzzle: Node, index: int) -> bool:
	var question: Label = puzzle.get_node("Dim/QuestionPanel/Margin/VBox/QuestionLabel")
	if question.text != String(QUESTIONS[index][0]):
		_fail("Question %d text is wrong" % (index + 1))
		return false
	var choices := puzzle.get_node("Dim/QuestionPanel/Margin/VBox/Choices").get_children()
	if choices.size() != 3:
		_fail("Question %d does not have three choices" % (index + 1))
		return false
	for choice: Button in choices:
		if not QUESTIONS[index][1].has(choice.text):
			_fail("Question %d has an unknown choice" % (index + 1))
			return false
	return true


func _choices_match_authored_order(puzzle: Node, index: int) -> bool:
	var choices := puzzle.get_node("Dim/QuestionPanel/Margin/VBox/Choices").get_children()
	for choice_index: int in range(choices.size()):
		if choices[choice_index].text != String(QUESTIONS[index][1][choice_index]):
			return false
	return true


func _press_choice_text(puzzle: Node, text: String) -> void:
	for button: Button in puzzle.get_node("Dim/QuestionPanel/Margin/VBox/Choices").get_children():
		if button.text == text:
			button.pressed.emit()
			return
	_fail("Could not find choice: %s" % text)


func _all_slots_are_neutral(puzzle: Node) -> bool:
	for slot_name: String in ["Slot1", "Slot2", "Slot3"]:
		var slot: ColorRect = puzzle.get_node("Dim/ChestPanel/Slots/" + slot_name)
		if slot.color != Color("#241a14"):
			return false
	return true


func _slots_are_aligned(puzzle: Node) -> bool:
	var expected := [
		Vector4(0.262, 0.515, 0.379, 0.622),
		Vector4(0.439, 0.515, 0.563, 0.622),
		Vector4(0.623, 0.515, 0.739, 0.622),
	]
	for index: int in range(3):
		var slot: ColorRect = puzzle.get_node("Dim/ChestPanel/Slots/Slot%d" % (index + 1))
		var actual := Vector4(slot.anchor_left, slot.anchor_top, slot.anchor_right, slot.anchor_bottom)
		if not actual.is_equal_approx(expected[index]):
			_fail("Slot %d is not aligned to the chest frame" % (index + 1))
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
