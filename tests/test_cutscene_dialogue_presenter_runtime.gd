extends SceneTree

const SHORT_DIALOGUE := "พี่น้องวานรทั้งหลาย!"
const LONG_DIALOGUE := (
	"พระรามและเหล่าวานรจะร่วมแรงร่วมใจกันสร้างสะพานข้ามมหาสมุทร "
	+ "เพื่อเดินทางไปยังกรุงลงกาและช่วยนางสีดาให้กลับมาอย่างปลอดภัย "
	+ "แม้หนทางข้างหน้าจะยาวไกลและเต็มไปด้วยอุปสรรคก็ตาม"
)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/ui/cutscene_dialogue_presenter.tscn") as PackedScene
	_expect(packed != null, "cutscene dialogue presenter scene exists")
	if packed == null:
		_finish()
		return

	var presenter := packed.instantiate()
	root.add_child(presenter)
	var prompt := Label.new()
	presenter.show_line({"speaker": "", "text": "พระรามเดินทางเข้าสู่ป่า"}, prompt)
	var narration := presenter.get_node("Narration") as Label
	var box := presenter.get_node("Box") as NinePatchRect
	_expect(narration.visible, "narration mode shows the cinematic narration label")
	_expect(not box.visible, "narration mode hides the Chapter 1 dialogue box")
	_expect(narration.text == "พระรามเดินทางเข้าสู่ป่า", "narration keeps only its sentence")
	_expect(
		prompt.get_theme_color("font_color").is_equal_approx(Color(0.9, 0.87, 0.78, 0.95)),
		"narration keeps a light prompt over the cinematic image"
	)

	prompt.text = "กด E เพื่อดำเนินเรื่องต่อ ▼"
	presenter.show_line({"speaker": "หนุมาน", "text": SHORT_DIALOGUE}, prompt)
	await process_frame
	var name_label := presenter.get_node("Box/NameTag/NameLabel") as Label
	var name_tag := presenter.get_node("Box/NameTag") as NinePatchRect
	var text_label := presenter.get_node_or_null("Box/Content/TextLabel") as Label
	var internal_prompt := presenter.get_node_or_null("Box/Content/ContinueLabel") as Label
	_expect(not narration.visible, "spoken mode hides the cinematic narration label")
	_expect(box.visible, "spoken mode shows the Chapter 1 dialogue box")
	_expect(name_label.text == "หนุมาน", "spoken mode shows the speaker in the name tag")
	_expect(text_label != null, "spoken box contains a vertical dialogue layout")
	_expect(internal_prompt != null, "spoken box owns its continue prompt")
	if text_label != null:
		_expect(text_label.text == SHORT_DIALOGUE, "spoken mode shows only the sentence")
		_expect(
			text_label.vertical_alignment == VERTICAL_ALIGNMENT_TOP,
			"dialogue body begins below the protruding name tag"
		)
		_expect(
			name_tag.get_global_rect().end.y <= text_label.get_global_rect().position.y,
			"name tag stays above the dialogue body instead of overlapping it"
		)
	_expect(not prompt.visible, "spoken mode hides the external prompt")
	if internal_prompt != null:
		_expect(internal_prompt.visible, "spoken mode shows the prompt inside the box")
		_expect(internal_prompt.text == prompt.text, "internal prompt mirrors dynamic prompt text")
		_expect(
			box.get_global_rect().encloses(internal_prompt.get_global_rect()),
			"spoken prompt stays inside the dialogue box"
		)
		_expect(
			internal_prompt.get_global_rect().end.y <= box.get_global_rect().end.y - 20.0,
			"spoken prompt keeps safe space above the bottom border"
		)
		_expect(
			absf(internal_prompt.get_global_rect().end.x - (box.get_global_rect().end.x - 28.0)) <= 1.0,
			"spoken prompt is anchored 28 px from the right frame edge"
		)
		_expect(
			absf(internal_prompt.get_global_rect().end.y - (box.get_global_rect().end.y - 22.0)) <= 1.0,
			"spoken prompt is anchored 22 px above the bottom frame edge"
		)

	var short_size := box.size
	presenter.show_line({"speaker": "หนุมาน", "text": LONG_DIALOGUE}, prompt)
	await process_frame
	await process_frame
	var long_size := box.size
	_expect(short_size.x < long_size.x, "short dialogue uses a narrower box")
	_expect(short_size.y < long_size.y, "wrapped dialogue uses a taller box")
	_expect(
		long_size.x <= presenter.size.x * 0.84 + 1.0,
		"dialogue box respects maximum viewport width"
	)
	_expect(
		absf(box.position.x + box.size.x * 0.5 - presenter.size.x * 0.5) <= 1.0,
		"dialogue box stays horizontally centered"
	)
	_expect(
		absf(box.get_global_rect().end.y - (presenter.get_global_rect().end.y - 24.0)) <= 1.0,
		"dialogue box keeps a 24 px bottom gap"
	)

	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	_expect(
		absf(box.position.x + box.size.x * 0.5 - presenter.size.x * 0.5) <= 1.0,
		"dialogue box remains centered after viewport resize"
	)
	_expect(
		box.get_global_rect().encloses(internal_prompt.get_global_rect()),
		"spoken prompt remains inside the frame after viewport resize"
	)

	presenter.show_line({"speaker": "", "text": "คำบรรยาย"}, prompt)
	_expect(prompt.visible, "narration restores the external prompt")
	if internal_prompt != null:
		_expect(not internal_prompt.visible, "narration hides the internal spoken prompt")
	_expect(presenter.mouse_filter == Control.MOUSE_FILTER_IGNORE, "presenter never consumes cutscene input")
	presenter.free()
	prompt.free()
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
