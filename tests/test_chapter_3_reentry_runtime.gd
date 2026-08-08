extends SceneTree

class FakePortal extends Area2D:
	var locked := true

	func set_locked(value: bool) -> void:
		locked = value


class FakeFeather extends Area2D:
	signal collection_requested(feather: Area2D)

	func mark_collected() -> void:
		visible = false
		monitoring = false

	func activate_at(new_position: Vector2) -> void:
		global_position = new_position
		visible = true
		monitoring = true

	func set_interaction_enabled(enabled: bool) -> void:
		monitoring = enabled


class FakeQuiz extends CanvasLayer:
	signal answered(correct: bool)


class FakePostBattleCutscene extends Control:
	func show_cutscene() -> void:
		pass


const GameState := preload("res://scenes/core/game_state.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.chapter_3_intro_played = true
	GameState.chapter_3_post_battle_played = false
	await _check_feather_reentry(0)
	await _check_feather_reentry(1)
	await _check_feather_reentry(2)
	await _check_rest_quest_reentry()
	await _check_post_battle_reentry()
	_finish()


func _check_feather_reentry(collected: int) -> void:
	GameState.chapter_3_post_battle_played = false
	_set_feather_count(collected)
	var chapter := await _enter_chapter()
	var quest := root.get_node("Quest")
	var snapshot: Dictionary = quest.snapshot()
	_expect(snapshot.get("name") == "ตามหาขนนกพญาชฎายุ", "re-entry restores feather quest at %d/3" % collected)
	_expect(snapshot.get("detail") == "รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ %d/3" % collected, "re-entry restores feather detail at %d/3" % collected)
	_expect(quest.get_target_count() == 3 - collected, "re-entry restores %d active feather targets" % (3 - collected))
	_expect(_active_feather_count(chapter) == 3 - collected, "re-entry restores %d visible feathers" % (3 - collected))
	_expect(root.get_node("Inv").count("jatayu_feather") == collected, "re-entry does not change %d collected feathers" % collected)
	await _remove_chapter(chapter)


func _check_rest_quest_reentry() -> void:
	GameState.chapter_3_post_battle_played = false
	_set_feather_count(3)
	var chapter := await _enter_chapter()
	await process_frame
	var snapshot: Dictionary = root.get_node("Quest").snapshot()
	_expect(snapshot.get("name") == "พักผ่อนใต้ต้นไม้ใหญ่", "3/3 re-entry restores resting quest")
	_expect(_active_feather_count(chapter) == 0, "3/3 re-entry keeps every feather collected")
	_expect(root.get_node("Inv").count("jatayu_feather") == 3, "3/3 re-entry preserves inventory")
	await _remove_chapter(chapter)


func _check_post_battle_reentry() -> void:
	GameState.chapter_3_post_battle_played = true
	_set_feather_count(3)
	var chapter := await _enter_chapter()
	var snapshot: Dictionary = root.get_node("Quest").snapshot()
	var portal := chapter.get_node("YSortRoot/Chapter4Portal") as FakePortal
	_expect(snapshot.get("name") == "ตามรอยทศกัณฐ์", "post-battle re-entry restores exit quest")
	_expect(portal.locked == false, "post-battle re-entry unlocks Chapter 4 portal")
	_expect(root.get_node("Inv").count("jatayu_feather") == 3, "post-battle re-entry preserves inventory")
	await _remove_chapter(chapter)


func _enter_chapter() -> Node2D:
	var chapter := _build_chapter()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	var cutscene_layer := CanvasLayer.new()
	cutscene_layer.name = "ReentryCutsceneLayer"
	chapter.add_child(cutscene_layer)
	var cutscene := _build_intro_cutscene()
	cutscene_layer.add_child(cutscene)
	await process_frame
	await process_frame
	return chapter


func _build_chapter() -> Node2D:
	var chapter := Node2D.new()
	chapter.name = "Chapter3"
	chapter.set_script(load("res://scenes/chapter_3/chapter_3.gd"))

	var ysort := Node2D.new()
	ysort.name = "YSortRoot"
	chapter.add_child(ysort)
	var player := CharacterBody2D.new()
	player.name = "Player"
	ysort.add_child(player)
	var portal := FakePortal.new()
	portal.name = "Chapter4Portal"
	ysort.add_child(portal)
	for index in range(3):
		var feather := FakeFeather.new()
		feather.name = "Feather%d" % (index + 1)
		ysort.add_child(feather)

	var story_end := Marker2D.new()
	story_end.name = "StoryEndSpawn"
	chapter.add_child(story_end)
	var quiz := FakeQuiz.new()
	quiz.name = "QuestionQuiz"
	chapter.add_child(quiz)
	var spawns := Node2D.new()
	spawns.name = "FeatherSpawns"
	chapter.add_child(spawns)
	for index in range(6):
		var spawn := Marker2D.new()
		spawn.name = "Spawn%d" % (index + 1)
		spawn.position = Vector2(100.0 * index, 50.0 * index)
		spawns.add_child(spawn)
	var chapter_cutscene_layer := CanvasLayer.new()
	chapter_cutscene_layer.name = "Chapter3CutsceneLayer"
	chapter.add_child(chapter_cutscene_layer)
	var post_cutscene := FakePostBattleCutscene.new()
	post_cutscene.name = "PostBattleCutscene"
	chapter_cutscene_layer.add_child(post_cutscene)
	return chapter


func _build_intro_cutscene() -> Control:
	var cutscene := Control.new()
	cutscene.name = "Chapter3ReentryCutscene"
	cutscene.set_script(load("res://scenes/cutscene/chapter_3_cutscene.gd"))
	var cutscene_image := TextureRect.new()
	cutscene_image.name = "CutsceneImage"
	cutscene.add_child(cutscene_image)
	var title_banner := NinePatchRect.new()
	title_banner.name = "TitleBanner"
	cutscene.add_child(title_banner)
	for child_name in ["BackgroundDim", "FadeOverlay"]:
		var control := ColorRect.new()
		control.name = child_name
		cutscene.add_child(control)
	for child_name in ["Dialogue", "ContinuePrompt"]:
		var label := Label.new()
		label.name = child_name
		cutscene.add_child(label)
	return cutscene


func _remove_chapter(chapter: Node) -> void:
	current_scene = null
	chapter.queue_free()
	await process_frame


func _set_feather_count(count: int) -> void:
	var items := {"potion": 3}
	if count > 0:
		items["jatayu_feather"] = count
	root.get_node("Inv").restore_items(items)


func _active_feather_count(chapter: Node) -> int:
	var active := 0
	for feather_name in ["Feather1", "Feather2", "Feather3"]:
		var feather := chapter.get_node("YSortRoot/%s" % feather_name) as Area2D
		if feather.visible and feather.monitoring:
			active += 1
	return active


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: Chapter 3 re-entry runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
