extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const BAR_ID := "lanka_key_fragment_bar"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := root.get_node("Inv")
	var quest := root.get_node("Quest")
	inventory.call("reset_for_new_story")
	quest.call("clear")
	quest.call("set_hud_visible", true)
	GameState.chapter_6_intro_played = true
	GameState.chapter_6_left_chest_unlocked = false
	var room := (load(ROOM) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	if not room.has_method("_on_chest_puzzle_solved"):
		_cleanup_fail(room, "Left room has no chest controller")
		return
	var interaction := room.get_node_or_null("ChestInteraction")
	if interaction == null:
		_cleanup_fail(room, "Left room has no chest interaction")
		return
	var player := room.get_node("YSortRoot/Player")
	room.call("_on_chest_body_entered", player)
	if not interaction.get_node("ChestPrompt").visible:
		_cleanup_fail(room, "Chest prompt did not appear near Player")
		return
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	room.call("_unhandled_input", event)
	var puzzle: CanvasLayer = room.get_node("LeftChestPuzzle")
	if not puzzle.visible or not paused:
		_cleanup_fail(room, "E did not open the chest puzzle")
		return
	puzzle.call("begin_questions")
	puzzle.call("cancel")
	await create_timer(0.25, true).timeout
	if puzzle.visible or paused:
		_cleanup_fail(room, "Cancelling did not close the puzzle")
		return
	if not interaction.get_node("ChestPrompt").visible or bool(room.get("_opening")):
		_cleanup_fail(room, "Cancelling did not restore the chest interaction")
		return
	room.call("_unhandled_input", event)
	if not puzzle.visible or not paused:
		_cleanup_fail(room, "Chest puzzle could not be reopened after cancelling")
		return
	paused = false
	puzzle.hide()
	room.call("_on_chest_puzzle_solved")
	await process_frame
	var pickup := room.get_node_or_null("YSortRoot/LeftChestKeyFragment")
	if pickup == null or int(inventory.call("count", BAR_ID)) != 0:
		_cleanup_fail(room, "Solving did not create one uncollected bar fragment")
		return
	room.queue_free()
	await process_frame
	room = (load(ROOM) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	if room.get_node("ChestInteraction").monitoring:
		_cleanup_fail(room, "Unlocked chest interaction was restored")
		return
	pickup = room.get_node_or_null("YSortRoot/LeftChestKeyFragment")
	if pickup == null:
		_cleanup_fail(room, "Uncollected bar fragment was not restored")
		return
	pickup.collection_requested.emit(pickup)
	await process_frame
	if int(inventory.call("count", BAR_ID)) != 1:
		_cleanup_fail(room, "Bar fragment was not added to inventory")
		return
	if room.get_node_or_null("YSortRoot/LeftChestKeyFragment") != null:
		_cleanup_fail(room, "Collected bar fragment remained in the room")
		return
	var detail: Label = quest.get_node("PageDim/Page/PageMargin/Columns/Detail/PageTextLabel")
	if not "1/3" in detail.text:
		_cleanup_fail(room, "Quest did not refresh after collecting the bar")
		return
	room.queue_free()
	await process_frame
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_left_chest_unlocked = false
	inventory.call("reset_for_new_story")
	quest.call("clear")
	print("Chapter 6 left chest flow runtime passed")
	quit(0)


func _cleanup_fail(room: Node, message: String) -> void:
	paused = false
	if is_instance_valid(room):
		room.queue_free()
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_left_chest_unlocked = false
	push_error(message)
	quit(1)
