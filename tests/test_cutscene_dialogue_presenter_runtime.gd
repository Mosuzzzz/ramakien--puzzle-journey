extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/ui/cutscene_dialogue_presenter.tscn") as PackedScene
	_expect(packed != null, "cutscene dialogue presenter scene exists")
	if packed == null:
		_finish()
		return

	var presenter := packed.instantiate()
	root.add_child(presenter)
	presenter.show_line({"speaker": "", "text": "พระรามเดินทางเข้าสู่ป่า"})
	var narration := presenter.get_node("Narration") as Label
	var box := presenter.get_node("Box") as NinePatchRect
	_expect(narration.visible, "narration mode shows the cinematic narration label")
	_expect(not box.visible, "narration mode hides the Chapter 1 dialogue box")
	_expect(narration.text == "พระรามเดินทางเข้าสู่ป่า", "narration keeps only its sentence")

	presenter.show_line({"speaker": "หนุมาน", "text": "ข้าจะตามพระองค์กลับมาให้ได้!"})
	var name_label := presenter.get_node("Box/NameTag/NameLabel") as Label
	var text_label := presenter.get_node("Box/Margin/TextLabel") as Label
	_expect(not narration.visible, "spoken mode hides the cinematic narration label")
	_expect(box.visible, "spoken mode shows the Chapter 1 dialogue box")
	_expect(name_label.text == "หนุมาน", "spoken mode shows the speaker in the name tag")
	_expect(
		text_label.text == "ข้าจะตามพระองค์กลับมาให้ได้!",
		"spoken mode shows only the sentence in the dialogue body"
	)
	_expect(presenter.mouse_filter == Control.MOUSE_FILTER_IGNORE, "presenter never consumes cutscene input")
	presenter.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: cutscene dialogue presenter runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
