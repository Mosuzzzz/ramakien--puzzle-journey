extends SceneTree

class FakeDefender extends CharacterBody2D:
	signal defeated(mob: CharacterBody2D)

const GameStateScript := preload("res://scenes/core/game_state.gd")
var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	GameStateScript.chapter_7_defenders_cleared = false
	var quest := root.get_node("Quest")
	quest.clear()
	var chapter := Node2D.new()
	chapter.set_script(load("res://scenes/chapter_7/chapter_7.gd"))
	var ysort := Node2D.new()
	ysort.name = "YSortRoot"
	chapter.add_child(ysort)
	var defenders: Array[FakeDefender] = []
	for index in range(3):
		var defender := FakeDefender.new()
		defender.name = "Mob%d" % (index + 1)
		ysort.add_child(defender)
		defenders.append(defender)
	root.add_child(chapter)
	await process_frame
	_expect(quest.snapshot().get("name") == "ปราบยักษ์ป้องกันเมือง", "starts defender quest")
	defenders[0].defeated.emit(defenders[0])
	defenders[1].defeated.emit(defenders[1])
	_expect(not GameStateScript.chapter_7_defenders_cleared, "two do not complete")
	defenders[2].defeated.emit(defenders[2])
	_expect(GameStateScript.chapter_7_defenders_cleared, "three complete")
	_expect(quest.snapshot().get("name") == "ลักลอบเข้าไปในวังทศกัณฐ์", "changes to infiltration quest")
	chapter.queue_free()
	await process_frame
	_check_source("res://scenes/chapter_5/chapter_5.gd", ["ปราบไมยราพ", "เดินทางไปยังกรุงลงกา", "Quest.set_quest"])
	_check_source("res://scenes/chapter_8/chapter_8.gd", ["สำรวจพระราชวังเพื่อหานางสีดา", "เดินทางไปปราบทศกัณฐ์", "กลับไปช่วยนางสีดา", "locked_interaction"])
	_check_source("res://scenes/chapter_8/chapter_8_room.gd", ["กลับไปช่วยนางสีดา", "Quest.set_completed(true)"])
	_check_source("res://scenes/chapter_9/chapter_9.gd", ["ปราบทศกัณฐ์", "กลับไปช่วยนางสีดา", "Quest.set_quest"])
	_finish()

func _check_source(path: String, required: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(path)
	for text in required:
		_expect(source.contains(text), "%s contains %s" % [path, text])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("PASS: chapter quest flows runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
