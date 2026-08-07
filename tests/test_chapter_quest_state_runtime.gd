extends SceneTree

const SaveGame := preload("res://scenes/core/save_game.gd")
const GameStateScript := preload("res://scenes/core/game_state.gd")
var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state_dyn = load("res://scenes/core/game_state.gd")
	_expect(state_dyn.get("chapter_7_defenders_cleared") == false, "Chapter 7 flag exists")
	_expect(state_dyn.get("chapter_8_sida_room_discovered") == false, "Chapter 8 flag exists")
	_expect("chapter_7_defenders_cleared" in SaveGame.STATE_KEYS, "Chapter 7 flag saves")
	_expect("chapter_8_sida_room_discovered" in SaveGame.STATE_KEYS, "Chapter 8 flag saves")
	state_dyn.set("chapter_7_defenders_cleared", true)
	state_dyn.set("chapter_8_sida_room_discovered", true)
	GameStateScript.reset_progress()
	_expect(not state_dyn.get("chapter_7_defenders_cleared"), "Chapter 7 flag resets")
	_expect(not state_dyn.get("chapter_8_sida_room_discovered"), "Chapter 8 flag resets")
	var portal := (load("res://scenes/props/portal.tscn") as PackedScene).instantiate()
	root.add_child(portal)
	await process_frame
	var events: Array[Area2D] = []
	portal.locked_interaction.connect(func(p: Area2D): events.append(p))
	portal.locked = true
	portal.call("_use_portal")
	_expect(events == [portal], "locked use emits once")
	portal.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("PASS: chapter quest state runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
