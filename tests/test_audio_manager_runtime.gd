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
			&"background", &"boss_fight", &"answer_correct", &"answer_wrong", &"button_click",
			&"enemy_attacking", &"enemy_hit", &"pickup", &"run",
			&"sword_attack", &"hurt", &"thrash", &"giant", &"wave",
			&"jump_throw", &"heal_and_pull", &"giant_attack", &"invite", &"door",
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
		for child in audio.get_children():
			if child is AudioStreamPlayer and child.name.begins_with("SFX"):
				child.stop()
		audio.play_sfx(&"door")
		var door_player: AudioStreamPlayer = null
		for child in audio.get_children():
			if (
				child is AudioStreamPlayer
				and child.stream != null
				and child.stream.resource_path.ends_with("door.mp3")
			):
				door_player = child
				break
		_expect(door_player != null, "door uses a pooled SFX player")
		if door_player != null:
			_expect(
				is_equal_approx(door_player.volume_db, linear_to_db(1.5)),
				"door cue uses 1.5 gain"
			)
		for child in audio.get_children():
			if child is AudioStreamPlayer and child.name.begins_with("SFX"):
				child.stop()
		audio.play_sfx(&"pickup")
		var pickup_player: AudioStreamPlayer = null
		for child in audio.get_children():
			if (
				child is AudioStreamPlayer
				and child.stream != null
				and child.stream.resource_path.ends_with("pickup.mp3")
			):
				pickup_player = child
				break
		_expect(pickup_player != null, "pickup uses a pooled SFX player")
		if pickup_player != null:
			_expect(
				is_equal_approx(pickup_player.volume_db, linear_to_db(1.0)),
				"non-door cues reset pooled player gain"
			)
		var owner_a := Node.new()
		var owner_b := Node.new()
		root.add_child(owner_a)
		root.add_child(owner_b)
		audio.set_run_active(owner_a, true)
		_expect(audio.get_node("RunLoop").playing, "run loop starts")
		audio.set_run_active(owner_b, true)
		audio.set_run_active(owner_a, false)
		_expect(audio.get_node("RunLoop").playing, "one stopped owner does not silence another")
		audio.set_run_active(owner_b, false)
		_expect(not audio.get_node("RunLoop").playing, "run loop stops after final owner")
		audio.set_run_active(owner_a, true)
		owner_a.free()
		await process_frame
		_expect(not audio.get_node("RunLoop").playing, "invalid owner is pruned")
		owner_b.free()
		if audio.has_method("sync_music_for_scene_path"):
			var sfx_bus := AudioServer.get_bus_index(&"SFX")
			var sfx_before := AudioServer.get_bus_volume_db(sfx_bus)
			audio.sync_music_for_scene_path("res://scenes/homepage/home_page.tscn")
			var music := audio.get_node("Music") as AudioStreamPlayer
			_expect(music.playing, "home page starts music")
			_expect(
				music.volume_db <= audio.SILENT_MUSIC_DB + 0.1,
				"first menu cycle begins silent"
			)
			await create_timer(audio.MUSIC_FADE_SECONDS + 0.1).timeout
			_expect(is_equal_approx(music.volume_db, linear_to_db(1.0)), "menu music fades to full gain")
			music.seek(2.0)
			audio.sync_music_for_scene_path("res://scenes/prologue/prologue.tscn")
			_expect(music.playing, "prologue keeps music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.3)),
				"prologue music uses gameplay gain"
			)
			_expect(music.get_playback_position() >= 1.9, "prologue does not restart music")
			audio.sync_music_for_scene_path("res://scenes/chapter_1/chapter_1.tscn")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.3)),
				"chapter music uses gameplay gain"
			)
			audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6_room_left.tscn")
			_expect(music.playing, "subroom keeps music")
			_expect(music.get_playback_position() >= 1.9, "subroom does not restart music")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.3)),
				"subroom music uses gameplay gain"
			)
			audio.sync_music_for_scene_path("res://scenes/cutscene/chapter_9_cutscene.tscn")
			_expect(
				is_equal_approx(music.volume_db, linear_to_db(0.3)),
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
			_expect(audio.has_method("play_boss_music"), "boss music start API exists")
			_expect(
				audio.has_method("restore_background_music"),
				"background restore API exists"
			)
			if (
				audio.has_method("play_boss_music")
				and audio.has_method("restore_background_music")
			):
				audio.sync_music_for_scene_path("res://scenes/chapter_5/chapter_5.tscn")
				audio.play_boss_music(0.0)
				await process_frame
				_expect(
					music.stream != null
					and music.stream.resource_path.ends_with("boss_fight.mp3"),
					"boss request selects boss track"
				)
				_expect(music.playing, "boss track starts playing")
				_expect(
					is_equal_approx(music.volume_db, linear_to_db(0.3)),
					"boss track uses gameplay gain"
				)
				_expect(
					music.stream is AudioStreamMP3 and not music.stream.loop,
					"boss MP3 uses AudioManager looping"
				)
				music.seek(2.0)
				audio.play_boss_music(0.0)
				_expect(
					music.get_playback_position() >= 1.9,
					"repeated boss request does not restart"
				)
				audio.restore_background_music(0.0)
				await process_frame
				_expect(
					music.stream != null
					and music.stream.resource_path.ends_with("background.mp3"),
					"restore request selects normal track"
				)
				_expect(
					music.get_playback_position() < 0.5,
					"restored normal track starts from beginning"
				)
				_expect(
					music.stream is AudioStreamMP3 and not music.stream.loop,
					"normal MP3 uses AudioManager looping"
				)
				audio.call("_on_music_finished")
				_expect(music.playing, "finished music restarts")
				_expect(
					music.volume_db <= audio.SILENT_MUSIC_DB + 0.1,
					"restarted cycle begins silent"
				)
				await create_timer(audio.MUSIC_FADE_SECONDS + 0.1).timeout
				_expect(
					is_equal_approx(music.volume_db, linear_to_db(0.3)),
					"restarted gameplay cycle fades to gameplay gain"
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
