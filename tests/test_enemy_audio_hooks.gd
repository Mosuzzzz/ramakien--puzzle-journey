extends SceneTree

var _failures: Array[String] = []
var _events: Array[StringName] = []


class DamageReceiver:
	extends Node2D
	var current_health := 100
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount
		current_health -= amount


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))
	var stage := Node2D.new()
	root.add_child(stage)
	var player := DamageReceiver.new()
	player.name = "Player"
	stage.add_child(player)

	var mob := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
	stage.add_child(mob)
	_expect(mob.has_method("_attack_sound_key"), "generic enemy defines attack sound")
	if mob.has_method("_attack_sound_key"):
		_expect(mob._attack_sound_key() == &"enemy_attacking", "generic attack key")
	_expect(mob.has_method("_is_footstep_frame"), "ordinary monster footstep frames defined")
	if mob.has_method("_is_footstep_frame"):
		_expect(mob._is_footstep_frame(&"walk", 2), "ordinary monster first foot contact")
		_expect(mob._is_footstep_frame(&"walk", 8), "ordinary monster second foot contact")
		_expect(
			not mob._is_footstep_frame(&"walk", 5),
			"ordinary monster non-contact frame is silent"
		)
		_expect(
			not mob._is_footstep_frame(&"idle", 2),
			"ordinary monster idle frame is silent"
		)
	_expect(
		mob.has_method("_on_sprite_frame_changed"),
		"ordinary monster exposes synchronized frame handler"
	)
	if mob.has_method("_on_sprite_frame_changed"):
		var mob_b := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
		stage.add_child(mob_b)
		_events.clear()
		for actor in [mob, mob_b]:
			var sprite := actor.get_node("Sprite") as AnimatedSprite2D
			sprite.animation = &"walk"
			sprite.frame = 2
			actor.velocity = Vector2.RIGHT * actor.speed
			actor.call("_on_sprite_frame_changed")
		_expect(
			_events == [&"monster_run", &"monster_run"],
			"two monsters emit overlapping contact cues"
		)
		mob.call("_on_sprite_frame_changed")
		_expect(_events.size() == 2, "same monster contact frame cannot duplicate")
		var mob_sprite := mob.get_node("Sprite") as AnimatedSprite2D
		mob_sprite.frame = 5
		mob_sprite.frame = 2
		_expect(_events.size() == 3, "next footstep cycle emits one new cue")
		mob_sprite.frame = 5
		mob.velocity = Vector2.ZERO
		mob_sprite.frame = 2
		_expect(_events.size() == 3, "stationary monster contact frame is silent")
		mob_b.free()
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
	thosakan._begin_jump_attack()
	_expect(not _events.has(&"jump_throw"), "Thosakan jump take-off is silent")
	var damage_before := player.damage_taken
	thosakan._begin_jump_impact()
	_expect(_events == [&"jump_throw"], "Thosakan jump cue plays at impact")
	_expect(
		player.damage_taken == damage_before + thosakan.jump_damage,
		"jump impact damages player"
	)
	thosakan._begin_jump_impact()
	_expect(_events == [&"jump_throw"], "jump impact cue cannot duplicate")
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
	_events.clear()
	for _cycle in 5:
		miyarap._start_summon()
	_expect(
		_events == [&"invite", &"invite", &"invite", &"invite", &"invite"],
		"five Miyarap summon starts produce five invite cues"
	)
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
