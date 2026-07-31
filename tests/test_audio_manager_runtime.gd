extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node_or_null("AudioManager")
	_expect(audio != null, "AudioManager autoload exists")
	if audio != null:
		_expect(audio.has_signal("sfx_played"), "SFX is observable")
		_expect(audio.has_method("play_sfx"), "play_sfx API exists")
		_expect(audio.has_method("set_run_active"), "run-loop API exists")
		_expect(audio.has_method("sync_music_for_scene_path"), "scene music API exists")
		_expect(audio.get_node_or_null("Music") != null, "Music player exists")
		_expect(audio.get_node_or_null("RunLoop") != null, "RunLoop player exists")
		var keys: Array[StringName] = [
			&"answer_correct", &"answer_wrong", &"button_click",
			&"enemy_attacking", &"enemy_hit", &"pickup", &"run",
			&"sword_attack", &"hurt", &"thrash", &"giant", &"wave",
			&"jump_throw", &"heal_and_pull", &"giant_attack",
		]
		for key in keys:
			_expect(audio.has_sound(key), "sound key loads: %s" % key)
		var heard: Array[StringName] = []
		audio.sfx_played.connect(func(key: StringName): heard.append(key))
		audio.play_sfx(&"pickup")
		await process_frame
		_expect(heard == [&"pickup"], "valid SFX emits once")
		audio.play_sfx(&"missing_key")
		await process_frame
		_expect(heard == [&"pickup"], "unknown key is ignored")
		var owner := Node.new()
		root.add_child(owner)
		audio.set_run_active(owner, true)
		_expect(audio.get_node("RunLoop").playing, "run loop starts")
		audio.set_run_active(owner, false)
		_expect(not audio.get_node("RunLoop").playing, "run loop stops")
		owner.free()
		if audio.has_method("sync_music_for_scene_path"):
			audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6.tscn")
			var music := audio.get_node("Music") as AudioStreamPlayer
			_expect(music.playing, "chapter starts music")
			music.seek(2.0)
			audio.sync_music_for_scene_path("")
			_expect(music.playing, "transient empty scene keeps music")
			_expect(music.get_playback_position() >= 1.9, "empty scene does not restart music")
			audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6_room_left.tscn")
			_expect(music.playing, "subroom keeps music")
			_expect(music.get_playback_position() >= 1.9, "subroom does not restart music")
			audio.sync_music_for_scene_path("res://scenes/homepage/home_page.tscn")
			_expect(not music.playing, "non-chapter stops chapter music")
		heard.clear()
		var button := Button.new()
		root.add_child(button)
		await process_frame
		button.button_down.emit()
		await process_frame
		_expect(heard == [&"button_click"], "button-down plays click immediately")
		button.pressed.emit()
		await process_frame
		_expect(heard == [&"button_click"], "pressed does not duplicate click")
		button.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: audio manager runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
