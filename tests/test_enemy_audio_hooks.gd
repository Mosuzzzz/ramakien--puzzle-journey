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
	var player := Node2D.new()
	player.name = "Player"
	stage.add_child(player)

	var mob := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
	stage.add_child(mob)
	_expect(mob.has_method("_attack_sound_key"), "generic enemy defines attack sound")
	if mob.has_method("_attack_sound_key"):
		_expect(mob._attack_sound_key() == &"enemy_attacking", "generic attack key")
	_events.clear()
	mob.apply_authorized_damage(1)
	_expect(_events == [&"enemy_hit"], "generic enemy hit plays once")
	mob.free()

	var thosakan := (load("res://scenes/props/thosakan.tscn") as PackedScene).instantiate()
	stage.add_child(thosakan)
	_expect(thosakan.has_method("_attack_sound_key"), "Thosakan overrides attack sound")
	if thosakan.has_method("_attack_sound_key"):
		_expect(thosakan._attack_sound_key() == &"giant_attack", "Thosakan normal attack key")
	_expect(thosakan.has_method("_special_sound_key"), "Thosakan maps special sounds")
	if thosakan.has_method("_special_sound_key"):
		_expect(thosakan._special_sound_key(&"Jump attack") == &"jump_throw", "jump cue")
		_expect(thosakan._special_sound_key(&"Skill") == &"heal_and_pull", "heal cue")
		_expect(thosakan._special_sound_key(&"pull attack") == &"heal_and_pull", "pull cue")
	_expect(thosakan.has_method("_is_footstep_frame"), "Thosakan footstep frames defined")
	if thosakan.has_method("_is_footstep_frame"):
		_expect(thosakan._is_footstep_frame(&"run", 1), "first Thosakan foot contact")
		_expect(thosakan._is_footstep_frame(&"run", 3), "second Thosakan foot contact")
		_expect(not thosakan._is_footstep_frame(&"idle", 1), "idle is silent")
	_events.clear()
	thosakan.take_damage(1)
	_expect(_events == [&"enemy_hit"], "Thosakan hit plays once")
	thosakan.free()

	var miyarap := (load("res://scenes/props/miyarap.tscn") as PackedScene).instantiate()
	stage.add_child(miyarap)
	_events.clear()
	miyarap.take_damage(1)
	_expect(_events == [&"enemy_hit"], "Miyarap hit plays once")
	_expect(miyarap.has_method("_play_slam_sound"), "Miyarap exposes impact cue")
	_expect(miyarap.has_method("_play_wave_sound"), "Miyarap exposes wave cue")
	if miyarap.has_method("_play_slam_sound") and miyarap.has_method("_play_wave_sound"):
		_events.clear()
		miyarap._play_slam_sound()
		miyarap._play_wave_sound()
		_expect(_events == [&"giant", &"wave"], "Miyarap cues play in impact order")
	miyarap.free()
	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: enemy audio hooks")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
