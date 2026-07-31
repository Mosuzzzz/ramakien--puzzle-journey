extends SceneTree

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))
	var portal := (load("res://scenes/props/portal.tscn") as PackedScene).instantiate()
	root.add_child(portal)

	portal.target_scene = "res://scenes/chapter_1/throne_room.tscn"
	_events.clear()
	portal.play_transition_sound_for_scene_path("res://scenes/chapter_1/chapter_1.tscn")
	_expect(_events == [&"door"], "entering throne room sounds door")

	portal.target_scene = "res://scenes/chapter_6/chapter_6.tscn"
	_events.clear()
	portal.play_transition_sound_for_scene_path(
		"res://scenes/chapter_6/chapter_6_room_left.tscn"
	)
	_expect(_events == [&"door"], "leaving Chapter 6 room sounds door")

	portal.target_scene = "res://scenes/chapter_8/chapter_8_room_4.tscn"
	_events.clear()
	portal.play_transition_sound_for_scene_path("res://scenes/chapter_8/chapter_8.tscn")
	_expect(_events == [&"door"], "entering Chapter 8 room sounds door")

	portal.locked = true
	_events.clear()
	portal.play_transition_sound_for_scene_path("res://scenes/chapter_8/chapter_8.tscn")
	_expect(_events.is_empty(), "locked room portal stays silent")

	portal.locked = false
	portal.target_scene = "res://scenes/chapter_7/chapter_7.tscn"
	_events.clear()
	portal.play_transition_sound_for_scene_path("res://scenes/chapter_6/chapter_6.tscn")
	_expect(_events.is_empty(), "outdoor chapter portal stays silent")

	portal.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: portal audio")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
