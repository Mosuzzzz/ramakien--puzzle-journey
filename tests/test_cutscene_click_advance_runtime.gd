extends SceneTree

const CHAPTER_6_SCENE := "res://scenes/chapter_6/chapter_6.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load(CHAPTER_6_SCENE) as PackedScene
	if packed_scene == null:
		_fail("ไม่สามารถโหลด Chapter 6 เพื่อทดสอบคัตซีนได้")
		return

	var chapter := packed_scene.instantiate()
	root.add_child(chapter)
	await process_frame

	var cutscene := chapter.get_node_or_null("Chapter6CutsceneLayer/Chapter6Cutscene")
	if cutscene == null:
		_fail("ไม่พบ Chapter 6 cutscene")
		return

	cutscene.set("_transitioning", false)
	cutscene.set("_finished", false)
	cutscene.call("_show_dialogue", 0, false)

	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.pressed = true
	cutscene.call("_input", left_click)

	if int(cutscene.get("_dialogue_index")) != 1:
		_fail("คลิกซ้ายหนึ่งครั้งต้องเลื่อนบทพูด Chapter 6 จากบรรทัด 0 ไปบรรทัด 1")
		return

	chapter.queue_free()
	await process_frame
	print("PASS: คลิกซ้ายดำเนินบทพูดคัตซีนจริงได้หนึ่งขั้น")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
