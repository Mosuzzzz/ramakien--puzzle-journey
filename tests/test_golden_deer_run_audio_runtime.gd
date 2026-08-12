extends SceneTree

var _failures: Array[String] = []

const CHAPTER_2_SCENE_PATHS := [
	"res://scenes/chapter_2/chapter_2.tscn",
	"res://scenes/chapter_2/chapter_2_second.tscn",
]


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
	var deer := _spawn_deer(packed, stage)
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
		await process_frame
		run_audio.seek(2.0)
		deer.call("_play", "run")
		_expect(
			run_audio.get_playback_position() >= 1.9,
			"repeated run does not restart audio"
		)
		deer.call("_play", "idle")
		_expect(not run_audio.playing, "idle animation stops deer audio")

	var dying_deer := _spawn_deer(packed, stage)
	var dying_audio := dying_deer.get_node("RunAudio") as AudioStreamPlayer2D
	dying_deer.call("_play", "run")
	dying_deer.call("_die")
	_expect(not dying_audio.playing, "death stops deer run audio immediately")

	var exiting_deer := _spawn_deer(packed, stage)
	var exiting_audio := exiting_deer.get_node("RunAudio") as AudioStreamPlayer2D
	exiting_deer.call("_play", "run")
	stage.remove_child(exiting_deer)
	_expect(not exiting_audio.playing, "tree exit stops deer run audio")
	exiting_deer.free()
	for scene_path in CHAPTER_2_SCENE_PATHS:
		_verify_chapter_scene_run_audio(scene_path, stage)
	stage.free()
	_finish()


func _spawn_deer(packed: PackedScene, stage: Node2D) -> CharacterBody2D:
	var deer := packed.instantiate() as CharacterBody2D
	stage.add_child(deer)
	return deer


func _verify_chapter_scene_run_audio(scene_path: String, stage: Node2D) -> void:
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "%s loads" % scene_path)
	if packed == null:
		return
	var chapter_scene := packed.instantiate() as Node2D
	_expect(chapter_scene != null, "%s instantiates" % scene_path)
	if chapter_scene == null:
		return
	chapter_scene.process_mode = Node.PROCESS_MODE_DISABLED
	stage.add_child(chapter_scene)
	var deer := chapter_scene.get_node_or_null("YSortRoot/GoldenDeer") as CharacterBody2D
	_expect(deer != null, "%s embeds GoldenDeer" % scene_path)
	if deer == null:
		return
	var run_audio := deer.get_node_or_null("RunAudio") as AudioStreamPlayer2D
	_expect(run_audio != null, "%s deer owns RunAudio" % scene_path)
	if run_audio == null:
		return
	_expect(run_audio.bus == &"SFX", "%s deer audio uses SFX bus" % scene_path)
	_expect(run_audio.stream is AudioStreamMP3, "%s deer uses imported MP3 stream" % scene_path)
	if run_audio.stream is AudioStreamMP3:
		_expect((run_audio.stream as AudioStreamMP3).loop, "%s deer run stream loops" % scene_path)
	deer.call("_play", "run")
	_expect(run_audio.playing, "%s deer run starts audio" % scene_path)
	deer.call("_play", "idle")
	_expect(not run_audio.playing, "%s deer idle stops audio" % scene_path)


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
