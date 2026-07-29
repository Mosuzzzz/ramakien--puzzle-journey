extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
const PORTAL_SCENE := "res://scenes/props/portal.tscn"
const CHAPTER_SCENE := "res://scenes/chapter_6/chapter_6.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := root.get_node("Inv")
	var quest := root.get_node("Quest")
	inventory.reset_for_new_story()
	quest.clear()
	quest.set_hud_visible(true)
	GameState.chapter_6_gate_unlocked = false

	for item_id: String in Chapter6KeyQuest.FRAGMENT_IDS:
		inventory.add_item(item_id)
	if not Chapter6KeyQuest.has_all_fragments(self):
		_cleanup_fail("Three distinct fragments were not recognized as complete")
		return
	Chapter6KeyQuest.refresh(self)
	var detail: Label = quest.get_node("PageDim/Page/PageMargin/Columns/Detail/PageTextLabel")
	if not quest.is_completed() or detail.modulate != Color("#67d56b"):
		_cleanup_fail("The 3/3 fragment quest did not turn green")
		return
	if not "3/3" in detail.text or not "ประตูเมือง" in detail.text:
		_cleanup_fail("The 3/3 quest did not direct the player to the city gate")
		return

	GameState.chapter_6_gate_unlocked = true
	if not Chapter6KeyQuest.consume_fragments(self):
		_cleanup_fail("Complete fragments could not be consumed atomically")
		return
	for item_id: String in Chapter6KeyQuest.FRAGMENT_IDS:
		if inventory.count(item_id) != 0:
			_cleanup_fail("Fragment consumption left an item behind")
			return
	Chapter6KeyQuest.refresh(self)
	if not quest.is_completed() or "0/3" in detail.text:
		_cleanup_fail("Consumed fragments regressed the unlocked gate objective")
		return

	GameState.chapter_6_gate_unlocked = false
	inventory.reset_for_new_story()
	GameState.chapter_6_intro_played = true
	var chapter := (load(CHAPTER_SCENE) as PackedScene).instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	var gate := chapter.get_node("YSortRoot/Chapter7Portal")
	if not gate.locked:
		_cleanup_fail("Chapter 6 city gate was open with no fragments")
		return
	if gate.locked_prompt_text != "รวบรวมชิ้นส่วนกุญแจให้ครบ 3 ชิ้นก่อน":
		_cleanup_fail("Locked city gate has the wrong prompt")
		return
	inventory.add_item(Chapter6KeyQuest.SHAFT_FRAGMENT_ID)
	inventory.add_item(Chapter6KeyQuest.BAR_FRAGMENT_ID)
	await process_frame
	if not gate.locked:
		_cleanup_fail("Chapter 6 city gate opened with only two fragments")
		return
	inventory.add_item(Chapter6KeyQuest.RING_FRAGMENT_ID)
	await process_frame
	if gate.locked or gate.prompt_text != "กด E เพื่อใช้กุญแจเปิดประตูเมือง":
		_cleanup_fail("Three fragments did not prepare the city gate")
		return
	if gate.target_scene != "res://scenes/chapter_7/chapter_7.tscn":
		_cleanup_fail("Chapter 6 city gate does not target Chapter 7")
		return
	if not chapter.has_method("_on_chapter_7_portal_activated"):
		_cleanup_fail("Chapter 6 has no city-gate transaction handler")
		return
	chapter.call("_on_chapter_7_portal_activated", gate)
	if not GameState.chapter_6_gate_unlocked:
		_cleanup_fail("Using the prepared gate did not persist its unlock")
		return
	for item_id: String in Chapter6KeyQuest.FRAGMENT_IDS:
		if inventory.count(item_id) != 0:
			_cleanup_fail("Using the city gate did not consume every fragment")
			return
	chapter.call("_on_chapter_7_portal_activated", gate)
	for item_id: String in Chapter6KeyQuest.FRAGMENT_IDS:
		if inventory.count(item_id) != 0:
			_cleanup_fail("Repeated gate activation changed consumed inventory")
			return
	Chapter6KeyQuest.refresh(self)
	if not quest.is_completed() or "0/3" in detail.text:
		_cleanup_fail("Gate transaction regressed its completed quest")
		return

	chapter.queue_free()
	await process_frame
	chapter = (load(CHAPTER_SCENE) as PackedScene).instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	gate = chapter.get_node("YSortRoot/Chapter7Portal")
	if gate.locked:
		_cleanup_fail("Persisted city gate relocked after returning to Chapter 6")
		return
	if not quest.is_completed() or "0/3" in detail.text:
		_cleanup_fail("Returning to Chapter 6 restored a false 0/3 objective")
		return
	chapter.queue_free()
	await process_frame

	var portal := (load(PORTAL_SCENE) as PackedScene).instantiate()
	root.add_child(portal)
	portal.target_scene = "res://scenes/ending/ending.tscn"
	var activation_state := {"count": 0}
	portal.activated.connect(
		func(_used_portal: Area2D) -> void: activation_state.count += 1
	)
	portal.set_locked(true)
	portal.call("_use_portal")
	if int(activation_state.count) != 0:
		_cleanup_fail("Locked portal emitted a valid activation")
		return
	portal.set_locked(false)
	portal.call("_use_portal")
	if int(activation_state.count) != 1:
		_cleanup_fail("Unlocked portal did not emit exactly one activation")
		return

	GameState.chapter_6_intro_played = false
	quest.clear()
	print("Chapter 6 gate runtime passed")
	quit(0)


func _cleanup_fail(message: String) -> void:
	GameState.chapter_6_gate_unlocked = false
	GameState.chapter_6_intro_played = false
	var inventory := root.get_node_or_null("Inv")
	if inventory != null:
		inventory.reset_for_new_story()
	push_error(message)
	quit(1)
