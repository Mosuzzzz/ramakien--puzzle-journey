extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var chapter_5_source := FileAccess.get_file_as_string(
		"res://scenes/chapter_5/chapter_5.gd"
	)
	_expect(
		chapter_5_source.contains("AudioManager.play_boss_music()"),
		"Chapter 5 starts boss music for an undefeated Miyarap"
	)
	_expect(
		chapter_5_source.contains("func _on_post_boss_cutscene_finished()"),
		"Chapter 5 has a post-cutscene music restore hook"
	)
	_expect(
		chapter_5_source.contains("AudioManager.restore_background_music()"),
		"Chapter 5 restores normal music after the cutscene"
	)

	var cutscene_script := load(
		"res://scenes/cutscene/chapter_5_post_boss_cutscene.gd"
	) as GDScript
	var cutscene := Control.new()
	cutscene.set_script(cutscene_script)
	_expect(cutscene.has_signal(&"finished"), "post-boss cutscene exposes finished signal")
	if cutscene.has_signal(&"finished"):
		var finish_count := [0]
		cutscene.connect(&"finished", func(): finish_count[0] += 1)
		_add_cutscene_children(cutscene)
		root.add_child(cutscene)
		cutscene.call("_finish_cutscene")
		cutscene.call("_finish_cutscene")
		_expect(finish_count[0] == 1, "post-boss cutscene emits finished exactly once")
		cutscene.queue_free()

	_finish()


func _add_cutscene_children(cutscene: Control) -> void:
	for child_name in ["CutsceneImage", "LankaMarchImage"]:
		var texture_rect := TextureRect.new()
		texture_rect.name = child_name
		cutscene.add_child(texture_rect)
	for child_name in ["BackgroundDim", "FadeOverlay"]:
		var color_rect := ColorRect.new()
		color_rect.name = child_name
		cutscene.add_child(color_rect)
	var title_banner := NinePatchRect.new()
	title_banner.name = "TitleBanner"
	var title := Label.new()
	title.name = "Title"
	title_banner.add_child(title)
	cutscene.add_child(title_banner)
	for child_name in ["Dialogue", "ContinuePrompt"]:
		var label := Label.new()
		label.name = child_name
		cutscene.add_child(label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: boss music hooks")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
