extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const CHAPTER_SCENE := "res://scenes/chapter_6/chapter_6.tscn"
const SHAFT_ID := "lanka_key_fragment_shaft"
const BAR_ID := "lanka_key_fragment_bar"
const RING_ID := "lanka_key_fragment_ring"
const QUEST_NAME := "ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := root.get_node_or_null("Inv")
	var quest := root.get_node_or_null("Quest")
	if inventory == null or quest == null:
		_fail("Chapter 6 quest test requires Inv and Quest autoloads")
		return
	inventory.call("reset_for_new_story")
	quest.call("clear")
	quest.call("set_hud_visible", true)
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_yak_fragment_position = Vector2.INF

	var chapter := (load(CHAPTER_SCENE) as PackedScene).instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	if not chapter.has_method("start_key_fragment_quest"):
		_cleanup_and_fail(chapter, "Chapter 6 has no key-fragment quest controller")
		return
	if quest.get_node("QuestButton").visible:
		_cleanup_and_fail(chapter, "Key-fragment quest appeared before the opening cutscene finished")
		return

	var cutscene := chapter.get_node_or_null("Chapter6CutsceneLayer/Chapter6Cutscene")
	if cutscene == null:
		_cleanup_and_fail(chapter, "Chapter 6 opening cutscene was missing")
		return
	cutscene.call("_finish_cutscene")
	await process_frame
	if not quest.get_node("QuestButton").visible:
		_cleanup_and_fail(chapter, "Quest did not appear after the opening cutscene")
		return
	if quest.get_node("PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel").text != QUEST_NAME:
		_cleanup_and_fail(chapter, "Chapter 6 quest used the wrong name")
		return
	if not "0/3" in quest.get_node("PageDim/Page/PageMargin/Columns/Detail/PageTextLabel").text:
		_cleanup_and_fail(chapter, "Chapter 6 quest did not start at 0/3")
		return

	var yak := chapter.get_node_or_null("YSortRoot/YakCaptain")
	if yak == null:
		_cleanup_and_fail(chapter, "Yak Captain was missing before defeat")
		return
	yak.call("apply_authorized_damage", 1)
	if chapter.get_node_or_null("YSortRoot/YakKeyFragmentPickup") != null:
		_cleanup_and_fail(chapter, "Nonlethal Yak damage spawned a key fragment")
		return
	var defeat_position: Vector2 = yak.global_position
	yak.call("apply_authorized_damage", 1000)
	await process_frame
	var pickup := chapter.get_node_or_null("YSortRoot/YakKeyFragmentPickup")
	if pickup == null:
		_cleanup_and_fail(chapter, "Yak defeat did not drop a key fragment")
		return
	if pickup.global_position.distance_to(defeat_position) > 0.1:
		_cleanup_and_fail(chapter, "Yak fragment did not drop at the Yak's position")
		return
	if int(inventory.call("count", SHAFT_ID)) != 0:
		_cleanup_and_fail(chapter, "Yak fragment entered inventory before the player collected it")
		return

	chapter.queue_free()
	await process_frame
	var returned_chapter := (load(CHAPTER_SCENE) as PackedScene).instantiate()
	root.add_child(returned_chapter)
	current_scene = returned_chapter
	await process_frame
	await process_frame
	if returned_chapter.get_node_or_null("YSortRoot/YakCaptain") != null:
		_cleanup_and_fail(returned_chapter, "Yak respawned after returning from a tower room")
		return
	pickup = returned_chapter.get_node_or_null("YSortRoot/YakKeyFragmentPickup")
	if pickup == null:
		_cleanup_and_fail(returned_chapter, "Uncollected Yak fragment was not restored")
		return

	var player := returned_chapter.get_node("YSortRoot/Player") as CharacterBody2D
	player.global_position = pickup.global_position
	for _frame: int in range(3):
		await physics_frame
	if not pickup.get_node("Prompt").visible:
		_cleanup_and_fail(returned_chapter, "Pickup prompt did not appear near the player")
		return
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	pickup.call("_input", key_event)
	await process_frame
	if int(inventory.call("count", SHAFT_ID)) != 1:
		_cleanup_and_fail(returned_chapter, "Collected Yak fragment was not added to inventory")
		return
	if int(inventory.call("count", BAR_ID)) != 0 or int(inventory.call("count", RING_ID)) != 0:
		_cleanup_and_fail(returned_chapter, "Yak pickup added more than its own inventory fragment")
		return
	if returned_chapter.get_node_or_null("YSortRoot/YakKeyFragmentPickup") != null:
		_cleanup_and_fail(returned_chapter, "Collected Yak fragment remained in the scene")
		return
	if not "1/3" in quest.get_node("PageDim/Page/PageMargin/Columns/Detail/PageTextLabel").text:
		_cleanup_and_fail(returned_chapter, "Quest progress did not update to 1/3")
		return

	returned_chapter.queue_free()
	await process_frame
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	inventory.call("reset_for_new_story")
	quest.call("clear")
	print("Chapter 6 key-fragment quest runtime passed")
	quit(0)


func _cleanup_and_fail(chapter: Node, message: String) -> void:
	if is_instance_valid(chapter):
		chapter.queue_free()
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
