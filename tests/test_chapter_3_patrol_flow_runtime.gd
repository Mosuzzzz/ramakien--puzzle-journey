extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inv := root.get_node("Inv")
	inv.call("reset_for_new_story")
	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	paused = false

	var quest := root.get_node("Quest")
	chapter.call("start_feather_quest")
	await process_frame
	if int(quest.call("get_target_count")) != 3:
		_fail("Feather quest did not mark all three active feathers")
		return
	if _quest_detail(quest) != "รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ 0/3":
		_fail("Feather quest did not start at 0/3")
		return

	var feather1 := chapter.get_node("YSortRoot/Feather1") as Area2D
	chapter.call("_on_feather_collection_requested", feather1)
	chapter.call("_on_quiz_answered", true)
	await process_frame
	if int(inv.call("count", "jatayu_feather")) != 1:
		_fail("Correct answer did not put one feather in inventory")
		return
	if _quest_detail(quest) != "รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ 1/3":
		_fail("Feather quest did not update to 1/3")
		return
	if int(quest.call("get_target_count")) != 2:
		_fail("Collected feather kept its quest marker")
		return

	var feather2 := chapter.get_node("YSortRoot/Feather2") as Area2D
	var old_position := feather2.global_position
	chapter.call("_on_feather_collection_requested", feather2)
	await chapter.call("_on_quiz_answered", false)
	if feather2.global_position == old_position:
		_fail("Wrong answer did not relocate the feather")
		return
	if int(inv.call("count", "jatayu_feather")) != 1:
		_fail("Wrong answer added a feather to inventory")
		return
	if int(quest.call("get_target_count")) != 2:
		_fail("Relocated feather lost its quest marker")
		return

	for feather_name: String in ["Feather2", "Feather3"]:
		var feather := chapter.get_node("YSortRoot/%s" % feather_name) as Area2D
		chapter.call("_on_feather_collection_requested", feather)
		chapter.call("_on_quiz_answered", true)
		await process_frame
	if int(inv.call("count", "jatayu_feather")) != 3:
		_fail("All three feathers were not stored in inventory")
		return
	if _quest_detail(quest) != "รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ 3/3":
		_fail("Feather quest did not update to 3/3")
		return
	var detail_label := quest.get_node(
		"PageDim/Page/PageMargin/Columns/Detail/PageTextLabel"
	) as Label
	if not detail_label.modulate.is_equal_approx(Color("#67d56b")):
		_fail("Completed feather quest did not turn green")
		return
	await create_timer(0.5).timeout
	if not bool(chapter.get("_post_battle_cutscene_started")):
		_fail("Feather completion did not trigger the follow-up cutscene")
		return

	chapter.call("finish_chapter_3_story")
	if _quest_name(quest) != "ตามรอยทศกัณฐ์":
		_fail("Final Chapter 3 quest title was not set")
		return
	if not (quest.get("target_position") as Vector2).is_finite():
		_fail("Final Chapter 3 quest did not point to the Chapter 4 portal")
		return

	print("Chapter 3 feather quest flow runtime passed")
	quit(0)


func _quest_name(quest: Node) -> String:
	return (quest.get_node(
		"PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel"
	) as Label).text


func _quest_detail(quest: Node) -> String:
	return (quest.get_node(
		"PageDim/Page/PageMargin/Columns/Detail/PageTextLabel"
	) as Label).text


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
