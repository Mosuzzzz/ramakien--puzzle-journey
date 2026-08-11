extends SceneTree

const SPOKEN_PATH := "/private/tmp/cutscene_dialogue_spoken_1920x1080.png"
const NARRATION_PATH := "/private/tmp/cutscene_dialogue_narration_1920x1080.png"
const NARROW_PATH := "/private/tmp/cutscene_dialogue_spoken_1024x768.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1920, 1080)
	var stage := Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(stage)

	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://assets/cutscene/chapter_2/deer_chase.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(background)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.34)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(dim)

	var presenter := (
		load("res://scenes/ui/cutscene_dialogue_presenter.tscn") as PackedScene
	).instantiate() as CutsceneDialoguePresenter
	stage.add_child(presenter)

	var prompt := Label.new()
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -300.0
	prompt.offset_top = -62.0
	prompt.offset_right = 300.0
	prompt.offset_bottom = -26.0
	prompt.text = "กด E เพื่อดำเนินเรื่องต่อ ▼"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", load("res://assets/fonts/Sarabun-Regular.ttf"))
	prompt.add_theme_font_size_override("font_size", 19)
	prompt.add_theme_color_override("font_color", Color(0.35, 0.24, 0.13, 0.75))
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(prompt)

	presenter.show_line({
		"speaker": "นางสีดา",
		"text": "พระสวามี กวางตัวนั้นงดงามนัก หากจับมาได้ ข้าจะเลี้ยงไว้เป็นเพื่อนนะเพคะ",
	}, prompt)
	for frame in 10:
		await process_frame
	root.get_texture().get_image().save_png(SPOKEN_PATH)

	presenter.show_line({
		"speaker": "",
		"text": "วันหนึ่ง มีกวางทองขนสีทองอร่ามวิ่งผ่านหน้าอาศรมไป งดงามจนทุกคนต่างพากันมอง",
	}, prompt)
	await process_frame
	root.get_texture().get_image().save_png(NARRATION_PATH)

	root.size = Vector2i(1024, 768)
	presenter.show_line({
		"speaker": "หนุมาน",
		"text": "ถึงเวลาช่วยพระราม และชิงพระนางสีดากลับคืนมาแล้ว! พวกเราจะสร้างสะพานข้ามไปยังกรุงลงกา!",
	}, prompt)
	for frame in 10:
		await process_frame
	root.get_texture().get_image().save_png(NARROW_PATH)
	print("CAPTURED: %s" % SPOKEN_PATH)
	print("CAPTURED: %s" % NARRATION_PATH)
	print("CAPTURED: %s" % NARROW_PATH)
	quit(0)
