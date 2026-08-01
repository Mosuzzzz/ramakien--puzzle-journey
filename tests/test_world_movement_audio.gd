extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	var run_loop := audio.get_node("RunLoop") as AudioStreamPlayer
	var stage := Node2D.new()
	root.add_child(stage)
	var player := Node2D.new()
	player.name = "Player"
	stage.add_child(player)

	for scene_path: String in [
		"res://scenes/props/mob.tscn",
		"res://scenes/props/sida.tscn",
		"res://scenes/props/hanuman.tscn",
		"res://scenes/props/phalak.tscn",
	]:
		var actor := (load(scene_path) as PackedScene).instantiate()
		stage.add_child(actor)
		_expect(actor.has_method("_update_run_audio"), "%s exposes run lifecycle" % scene_path)
		if actor.has_method("_update_run_audio"):
			actor._update_run_audio(true)
			_expect(run_loop.playing, "%s starts shared run loop" % scene_path)
			actor._update_run_audio(false)
			_expect(not run_loop.playing, "%s stops shared run loop" % scene_path)
			actor._update_run_audio(true)
		actor.free()
		await process_frame
		_expect(not run_loop.playing, "%s releases run audio on exit" % scene_path)

	var thosakan := (load("res://scenes/props/thosakan.tscn") as PackedScene).instantiate()
	stage.add_child(thosakan)
	_expect(thosakan.has_method("_uses_shared_run_audio"), "Thosakan exposes run-audio policy")
	if thosakan.has_method("_uses_shared_run_audio"):
		_expect(not thosakan._uses_shared_run_audio(), "Thosakan keeps giant footsteps")
	if thosakan.has_method("_update_run_audio"):
		thosakan._update_run_audio(true)
		_expect(not run_loop.playing, "Thosakan does not start shared run loop")
	thosakan.free()
	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: world movement audio")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
