extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var player := Node2D.new()
	player.name = "Player"
	stage.add_child(player)
	var packed := load("res://scenes/props/golden_deer.tscn") as PackedScene
	_expect(packed != null, "GoldenDeer packed scene loads")
	if packed == null:
		stage.free()
		_finish()
		return
	var deer := packed.instantiate()
	stage.add_child(deer)
	var run_audio := deer.get_node_or_null("RunAudio") as AudioStreamPlayer2D
	_expect(run_audio != null, "GoldenDeer owns positional run audio")
	if run_audio != null:
		_expect(run_audio.bus == &"SFX", "deer run audio uses SFX bus")
		_expect(is_equal_approx(run_audio.max_distance, 900.0), "deer audio has bounded range")
		_expect(run_audio.stream is AudioStreamMP3, "deer uses imported MP3 stream")
		if run_audio.stream is AudioStreamMP3:
			_expect((run_audio.stream as AudioStreamMP3).loop, "deer run stream loops")
		deer.call("_play", "run")
		_expect(run_audio.playing, "run animation starts deer audio")
		var playback_position := run_audio.get_playback_position()
		deer.call("_play", "run")
		_expect(
			run_audio.get_playback_position() >= playback_position,
			"repeated run does not restart audio"
		)
		deer.call("_play", "idle")
		_expect(not run_audio.playing, "idle animation stops deer audio")
	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: golden deer run audio runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
