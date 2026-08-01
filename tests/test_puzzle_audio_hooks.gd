extends SceneTree

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))
	_test_question_quiz()
	_test_matching_puzzle()
	_test_left_chest()
	_test_right_jar()
	_test_right_code()
	paused = false
	_finish()


func _test_question_quiz() -> void:
	var quiz := _spawn("res://scenes/ui/question_quiz.tscn")
	quiz.ask("Q", ["A", "B"], 1)
	_events.clear()
	quiz._on_choice_pressed(1)
	_expect(_events == [&"answer_correct"], "shared quiz correct feedback")
	quiz.ask("Q", ["A", "B"], 1)
	_events.clear()
	quiz._on_choice_pressed(0)
	_expect(_events == [&"answer_wrong"], "shared quiz wrong feedback")
	quiz.ask("Q", ["A", "B"], 0)
	var first_button := quiz.get_node("Dim/Page/PageMargin/VBox/Choices").get_child(0) as Button
	_events.clear()
	first_button.button_down.emit()
	first_button.pressed.emit()
	_expect(
		_events == [&"button_click", &"answer_correct"],
		"dynamic answer click precedes correct feedback"
	)
	quiz.free()


func _test_matching_puzzle() -> void:
	var puzzle := _spawn("res://scenes/ui/matching_puzzle.tscn")
	puzzle.open("Match", [["L1", "R1"], ["L2", "R2"]])
	var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
	var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
	var matching: Button
	var wrong: Button
	for button: Button in right_column.get_children():
		if button.text == "R1":
			matching = button
		else:
			wrong = button
	_events.clear()
	puzzle._on_left_pressed(left, 0)
	puzzle._on_right_pressed(matching, 0)
	_expect(_events == [&"answer_correct"], "matching correct feedback")
	var second_left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(1) as Button
	_events.clear()
	puzzle._on_left_pressed(second_left, 1)
	puzzle._on_right_pressed(wrong, 0)
	_expect(_events == [&"answer_wrong"], "matching wrong feedback")
	puzzle.free()


func _test_left_chest() -> void:
	var puzzle := _spawn("res://scenes/chapter_6/chapter_6_left_chest_puzzle.tscn")
	puzzle.open()
	puzzle.begin_questions()
	_events.clear()
	puzzle._on_choice_pressed(1)
	_expect(_events == [&"answer_correct"], "left chest correct feedback")
	_events.clear()
	puzzle._on_choice_pressed(2)
	_expect(_events == [&"answer_wrong"], "left chest wrong feedback")
	puzzle.free()


func _test_right_jar() -> void:
	var definition := {
		"index": 0,
		"question": "Q",
		"choices": ["A", "B", "C"],
		"correct_index": 1,
	}
	var jar := _spawn("res://scenes/chapter_6/chapter_6_right_jar_modal.tscn")
	jar.open_jar(definition, false)
	_events.clear()
	jar._show_wrong_feedback(0)
	_expect(_events == [&"answer_wrong"], "jar wrong feedback")
	jar.free()
	jar = _spawn("res://scenes/chapter_6/chapter_6_right_jar_modal.tscn")
	jar.open_jar(definition, false)
	_events.clear()
	jar._show_correct_feedback(1)
	_expect(_events == [&"answer_correct"], "jar correct feedback")
	jar.free()


func _test_right_code() -> void:
	var discovered: Array[int] = [2, 7, 3]
	var code := _spawn("res://scenes/chapter_6/chapter_6_right_code_modal.tscn")
	code.open(discovered)
	_events.clear()
	code._append_digit(2)
	code._append_digit(7)
	code._append_digit(3)
	_expect(_events == [&"answer_correct"], "code correct feedback")
	code.free()
	code = _spawn("res://scenes/chapter_6/chapter_6_right_code_modal.tscn")
	code.open(discovered)
	_events.clear()
	code._append_digit(3)
	code._append_digit(7)
	code._append_digit(2)
	_expect(_events == [&"answer_wrong"], "code wrong feedback")
	code.free()


func _spawn(scene_path: String) -> Node:
	var node := (load(scene_path) as PackedScene).instantiate()
	root.add_child(node)
	return node


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: puzzle audio hooks")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
