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

	var chapter_9_source := FileAccess.get_file_as_string(
		"res://scenes/chapter_9/chapter_9.gd"
	)
	_expect(
		chapter_9_source.contains("AudioManager.play_boss_music()"),
		"Chapter 9 starts boss music for an undefeated Thotsakan"
	)
	_expect(
		chapter_9_source.contains("AudioManager.restore_background_music(0.0)"),
		"completed Chapter 9 save keeps normal music"
	)
	var defeated_handler_start := chapter_9_source.find(
		"func _on_thotsakan_defeated"
	)
	var defeated_handler := (
		chapter_9_source.substr(defeated_handler_start)
		if defeated_handler_start >= 0
		else ""
	)
	var save_flag_position := defeated_handler.find(
		"GameState.chapter_9_thotsakan_defeated = true"
	)
	var restore_position := defeated_handler.find(
		"AudioManager.restore_background_music()"
	)
	_expect(
		save_flag_position >= 0 and restore_position > save_flag_position,
		"Thotsakan defeat is saved before normal music is restored"
	)

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
