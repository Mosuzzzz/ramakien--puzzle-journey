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
			var sfx_bus := AudioServer.get_bus_index(&"SFX")
			var sfx_before := AudioServer.get_bus_volume_db(sfx_bus)
			audio.sync_music_for_scene_path("res://scenes/homepage/home_page.tscn")
			var music := audio.get_node("Music") as AudioStreamPlayer
			_expect(music.playing, "home page starts music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(1.0)),
				"menu music uses full gain"
			)
			music.seek(2.0)
			audio.sync_music_for_scene_path("res://scenes/prologue/prologue.tscn")
			_expect(music.playing, "prologue keeps music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.4)),
				"prologue music uses gameplay gain"
			)
			_expect(music.get_playback_position() >= 1.9, "prologue does not restart music")
			audio.sync_music_for_scene_path("res://scenes/chapter_1/chapter_1.tscn")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.4)),
				"chapter music uses gameplay gain"
			)
			audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6_room_left.tscn")
			_expect(music.playing, "subroom keeps music")
			_expect(music.get_playback_position() >= 1.9, "subroom does not restart music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.4)),
				"subroom music uses gameplay gain"
			)
			audio.sync_music_for_scene_path("res://scenes/cutscene/chapter_9_cutscene.tscn")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.4)),
				"chapter cutscene uses gameplay gain"
			)
			var gain_before_transition := music.volume_db
			audio.sync_music_for_scene_path("")
			_expect(music.playing, "transient empty scene keeps music")
			_expect(music.get_playback_position() >= 1.9, "empty scene does not restart music")
			_expect(
				is_equal_approx(music.volume_db, gain_before_transition),
				"empty scene preserves music gain"
			)
			audio.sync_music_for_scene_path("res://scenes/homepage/settings_page.tscn")
			_expect(music.playing, "returning to menu keeps music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(1.0)),
				"returning to menu restores full gain"
			)
			_expect(
				is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), sfx_before),
				"scene music sync leaves SFX bus unchanged"
			)
			audio.sync_music_for_scene_path("res://scenes/ending/ending.tscn")
			_expect(not music.playing, "unrelated scene stops music")
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
