extends SceneTree

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))
	var stage := Node2D.new()
	root.add_child(stage)

	var rama := (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	stage.add_child(rama)
	_expect(rama.has_method("_update_run_audio"), "Rama exposes run lifecycle helper")
	if rama.has_method("_update_run_audio"):
		rama._update_run_audio(true)
		_expect((audio.get_node("RunLoop") as AudioStreamPlayer).playing, "Rama starts run loop")
		rama._update_run_audio(false)
		_expect(not (audio.get_node("RunLoop") as AudioStreamPlayer).playing, "Rama stops run loop")
	_events.clear()
	rama._shoot()
	_expect(_events.has(&"sword_attack"), "Rama attack uses sword sound")
	rama.take_damage(1)
	_expect(_events.has(&"hurt"), "Rama damage uses hurt sound")
	rama.free()

	var hanuman := (load("res://scenes/player/hanuman_player.tscn") as PackedScene).instantiate()
	stage.add_child(hanuman)
	_expect(hanuman.has_method("_update_run_audio"), "Hanuman exposes run lifecycle helper")
	if hanuman.has_method("_update_run_audio"):
		hanuman._update_run_audio(true)
		_expect((audio.get_node("RunLoop") as AudioStreamPlayer).playing, "Hanuman starts run loop")
		hanuman._update_run_audio(false)
		_expect(not (audio.get_node("RunLoop") as AudioStreamPlayer).playing, "Hanuman stops run loop")
	_events.clear()
	hanuman._attack()
	_expect(_events.has(&"thrash"), "Hanuman attack uses thrash sound")
	hanuman.take_damage(1)
	_expect(_events.has(&"hurt"), "Hanuman damage uses hurt sound")
	hanuman.free()
	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: player audio hooks")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
