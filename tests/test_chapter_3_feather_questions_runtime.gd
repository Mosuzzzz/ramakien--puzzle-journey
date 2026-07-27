extends SceneTree


const EXPECTED_QUESTIONS: Array[String] = [
	"คำใดอยู่ในมาตราตัวสะกดแม่กง",
	"คำว่า “วิ่ง” เป็นคำชนิดใด",
	"คำว่า “สามัคคี” หมายถึงข้อใด",
]

const EXPECTED_CHOICES: Array[Array] = [
	["ลิง", "ดาว", "เมฆ"],
	["คำนาม", "คำกริยา", "คำวิเศษณ์"],
	["การแข่งขันกัน", "การร่วมมือและพร้อมใจกัน", "การอยู่ตามลำพัง"],
]

const CORRECT_INDICES: Array[int] = [0, 1, 1]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inv := root.get_node("Inv")
	inv.call("reset_for_new_story")
	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	paused = false
	chapter.call("start_feather_quest")
	await process_frame

	var quiz := chapter.get_node("QuestionQuiz")
	for index: int in 3:
		var feather := chapter.get_node("YSortRoot/Feather%d" % (index + 1)) as Area2D
		chapter.call("_on_feather_collection_requested", feather)
		await process_frame
		if not _quiz_matches(quiz, index):
			return

		var wrong_index := (CORRECT_INDICES[index] + 1) % 3
		quiz.call("_on_choice_pressed", wrong_index)
		await create_timer(0.45).timeout

		chapter.call("_on_feather_collection_requested", feather)
		await process_frame
		if not _quiz_matches(quiz, index):
			_fail("Feather%d changed its assigned question after a wrong answer" % (index + 1))
			return
		quiz.call("_on_choice_pressed", CORRECT_INDICES[index])
		await process_frame

	print("Chapter 3 fixed feather questions runtime passed")
	quit(0)


func _quiz_matches(quiz: Node, index: int) -> bool:
	var question_label := quiz.get_node("Dim/Page/PageMargin/VBox/QuestionLabel") as Label
	if question_label.text != EXPECTED_QUESTIONS[index]:
		_fail("Feather%d showed the wrong assigned question" % (index + 1))
		return false
	var choices := quiz.get_node("Dim/Page/PageMargin/VBox/Choices")
	if choices.get_child_count() != 3:
		_fail("Feather%d did not show exactly three choices" % (index + 1))
		return false
	for choice_index: int in 3:
		var button := choices.get_child(choice_index) as Button
		if button.text != EXPECTED_CHOICES[index][choice_index]:
			_fail("Feather%d showed the wrong choice text" % (index + 1))
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
