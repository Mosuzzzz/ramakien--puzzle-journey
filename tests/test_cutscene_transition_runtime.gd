extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const Chapter3CutsceneScript := preload("res://scenes/cutscene/chapter_3_cutscene.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.chapter_3_intro_played = false
	var transition := root.get_node("SceneTransition")
	transition.fade_duration = 0.01
	var fades: Array[float] = []
	transition.fade_started.connect(func(alpha: float): fades.append(alpha))

	var cutscene := _build_chapter_3_cutscene()
	root.add_child(cutscene)
	while transition.is_busy():
		await process_frame
	await process_frame
	_expect(fades == [1.0, 0.0], "cutscene entry uses one shared fade pair")
	_expect(paused, "cutscene keeps gameplay paused after entry reveal")

	cutscene.call("_finish_cutscene")
	while transition.is_busy():
		await process_frame
	await process_frame
	_expect(fades == [1.0, 0.0, 1.0, 0.0], "cutscene exit uses one shared fade pair")
	_expect(not paused, "cutscene restores gameplay after exit reveal")

	var button := Button.new()
	root.add_child(button)
	var skipped := {"called": false}
	var child_count_before := root.get_child_count()
	CutsceneSkip._skip_with_fade(button, func(): skipped.called = true)
	await process_frame
	_expect(skipped.called, "skip delegates immediately to the cutscene finish path")
	_expect(
		root.get_child_count() == child_count_before,
		"skip does not create a second transition overlay"
	)
	button.free()
	transition.fade_duration = 1.0
	_finish()


func _build_chapter_3_cutscene() -> Control:
	var cutscene := Control.new()
	cutscene.name = "Chapter3Cutscene"
	cutscene.set_script(Chapter3CutsceneScript)

	var image := TextureRect.new()
	image.name = "CutsceneImage"
	cutscene.add_child(image)
	var dim := ColorRect.new()
	dim.name = "BackgroundDim"
	cutscene.add_child(dim)
	var banner := NinePatchRect.new()
	banner.name = "TitleBanner"
	cutscene.add_child(banner)
	var title := Label.new()
	title.name = "Title"
	banner.add_child(title)
	var dialogue := Label.new()
	dialogue.name = "Dialogue"
	cutscene.add_child(dialogue)
	var prompt := Label.new()
	prompt.name = "ContinuePrompt"
	cutscene.add_child(prompt)
	var fade_overlay := ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	cutscene.add_child(fade_overlay)
	return cutscene


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	if _failures.is_empty():
		print("PASS: cutscene transition runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
