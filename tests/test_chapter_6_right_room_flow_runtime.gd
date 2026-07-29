extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const ROOM_SCENE := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const JAR_PATHS := [
	"JarInteractions/JarUpperLeft",
	"JarInteractions/JarUpperRight",
	"JarInteractions/JarLowerLeft",
	"JarInteractions/JarLowerRight",
]
const EXPECTED_POSITIONS := [
	Vector2(245, 390),
	Vector2(1005, 390),
	Vector2(245, 800),
	Vector2(1005, 800),
]
const ROOM_QUEST := "ค้นหาโค้ดลับเพื่อปลดล็อกชิ้นส่วนกุญแจ"
const RING_ID := "lanka_key_fragment_ring"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := root.get_node("Inv")
	var quest := root.get_node("Quest")
	inventory.reset_for_new_story()
	quest.clear()
	quest.set_hud_visible(true)
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false

	var room := (load(ROOM_SCENE) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	if not room.has_method("_is_jar_searched"):
		_cleanup_fail(room, "Right room has no jar interaction controller")
		return
	for index: int in range(JAR_PATHS.size()):
		var area := room.get_node_or_null(JAR_PATHS[index]) as Area2D
		if area == null:
			_cleanup_fail(room, "Right room is missing jar interaction %d" % index)
			return
		if area.position != EXPECTED_POSITIONS[index]:
			_cleanup_fail(room, "Jar interaction %d has the wrong authored position" % index)
			return
		if area.get_node("Prompt").text != "กด E เพื่อค้นหา":
			_cleanup_fail(room, "Unsearched jar %d has the wrong prompt" % index)
			return

	var quest_name: Label = quest.get_node(
		"PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel"
	)
	var quest_detail: Label = quest.get_node("PageDim/Page/PageMargin/Columns/Detail/PageTextLabel")
	if quest_name.text != ROOM_QUEST or quest_detail.text != "":
		_cleanup_fail(room, "Right room quest name or empty detail is wrong")
		return

	var player := room.get_node("YSortRoot/Player")
	room.call("_on_jar_body_entered", player, 0)
	var upper_left := room.get_node(JAR_PATHS[0])
	if not upper_left.get_node("Prompt").visible:
		_cleanup_fail(room, "Nearby unsearched jar did not show its prompt")
		return
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	room.call("_unhandled_input", event)
	var modal := room.get_node("RightJarModal")
	if not modal.visible or not paused:
		_cleanup_fail(room, "E did not open the nearby jar modal")
		return
	var definition: Dictionary = modal.get("_definition")
	if int(definition.get("index", -1)) != 0:
		_cleanup_fail(room, "Upper-left jar opened the wrong definition")
		return
	if int(definition.get("digit", -1)) != 7:
		_cleanup_fail(room, "Upper-left jar did not map to digit 7")
		return
	if String(definition.get("question", "")) != "ข้อใดเป็นคำพ้องเสียง":
		_cleanup_fail(room, "Upper-left jar opened the wrong fixed question")
		return

	modal.searched.emit(0)
	if GameState.chapter_6_right_jars_mask != 0b0001:
		_cleanup_fail(room, "Searching jar 0 did not persist its mask bit")
		return
	modal.cancel()
	await process_frame
	if upper_left.get_node("Prompt").text != "กด E เพื่อดูในโหล":
		_cleanup_fail(room, "Searched jar prompt did not change")
		return
	room.call("_unhandled_input", event)
	if modal.get_node("Dim/QuestionPanel").visible:
		_cleanup_fail(room, "Searched jar asked its question again")
		return
	modal.cancel()
	await process_frame

	GameState.chapter_6_right_jars_mask = 0b0101
	room.queue_free()
	await process_frame
	room = (load(ROOM_SCENE) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	if not bool(room.call("_is_jar_searched", 0)) or not bool(room.call("_is_jar_searched", 2)):
		_cleanup_fail(room, "Saved searched jars were not restored")
		return
	if bool(room.call("_is_jar_searched", 1)) or bool(room.call("_is_jar_searched", 3)):
		_cleanup_fail(room, "Unsearched jars were incorrectly restored as searched")
		return
	room.call("_on_jar_searched", 1)
	if GameState.chapter_6_right_jars_mask != 0b0111:
		_cleanup_fail(room, "Jar mask update erased another jar's progress")
		return

	var pedestal := room.get_node_or_null("PedestalInteraction") as Area2D
	if pedestal == null:
		_cleanup_fail(room, "Right room has no central pedestal interaction")
		return
	player = room.get_node("YSortRoot/Player")
	GameState.chapter_6_right_jars_mask = 0
	room.call("_on_pedestal_body_entered", player)
	if not pedestal.get_node("Prompt").visible:
		_cleanup_fail(room, "Nearby pedestal did not show its prompt")
		return
	room.call("_unhandled_input", event)
	var code_modal := room.get_node("RightCodeModal")
	if not code_modal.visible or not paused:
		_cleanup_fail(room, "Pedestal did not open before searching jars")
		return
	if _button_texts(code_modal) != ["?", "?", "?"]:
		_cleanup_fail(room, "Early pedestal did not hide undiscovered digits")
		return
	code_modal.cancel()
	await process_frame

	GameState.chapter_6_right_jars_mask = 0b1101
	room.call("_unhandled_input", event)
	var exposed_digits := _button_texts(code_modal)
	if exposed_digits == ["2", "7", "3"]:
		_cleanup_fail(room, "Pedestal exposed digits in solution order")
		return
	var sorted_exposed_digits := exposed_digits.duplicate()
	sorted_exposed_digits.sort()
	if sorted_exposed_digits != ["2", "3", "7"]:
		_cleanup_fail(room, "Pedestal did not expose the three numbered jars")
		return
	for button: Button in code_modal.get_node(
		"Dim/EntryPanel/Margin/VBox/DigitSources"
	).get_children():
		if button.disabled:
			_cleanup_fail(room, "A discovered code source stayed disabled")
			return
	for digit: int in [2, 7, 3]:
		if not _press_code_digit(code_modal, digit):
			_cleanup_fail(room, "Could not find pedestal digit: %d" % digit)
			return
	await create_timer(1.1, true).timeout
	if not GameState.chapter_6_right_pedestal_solved:
		_cleanup_fail(room, "Correct pedestal code was not persisted")
		return
	var pickup := room.get_node_or_null("YSortRoot/RightRoomKeyFragment")
	if pickup == null or inventory.count(RING_ID) != 0:
		_cleanup_fail(room, "Solving the pedestal did not create one waiting ring fragment")
		return
	if quest_name.text != "เก็บชิ้นส่วนกุญแจ" or quest_detail.text != "":
		_cleanup_fail(room, "Solved pedestal did not show the pickup quest")
		return

	room.queue_free()
	await process_frame
	room = (load(ROOM_SCENE) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	pickup = room.get_node_or_null("YSortRoot/RightRoomKeyFragment")
	if pickup == null:
		_cleanup_fail(room, "Uncollected ring fragment was not restored")
		return
	pickup.collection_requested.emit(pickup)
	await process_frame
	if inventory.count(RING_ID) != 1:
		_cleanup_fail(room, "Collecting the ring fragment did not add exactly one item")
		return
	if room.get_node_or_null("YSortRoot/RightRoomKeyFragment") != null:
		_cleanup_fail(room, "Collected ring fragment remained in the room")
		return
	if quest_name.text != "ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง":
		_cleanup_fail(room, "Collecting the ring did not restore the shared fragment quest")
		return

	room.queue_free()
	await process_frame
	room = (load(ROOM_SCENE) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	if room.get_node_or_null("YSortRoot/RightRoomKeyFragment") != null:
		_cleanup_fail(room, "Collected ring fragment respawned")
		return
	room.queue_free()
	await process_frame
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false
	inventory.reset_for_new_story()
	quest.clear()
	print("Chapter 6 right-room jar flow runtime passed")
	quit(0)


func _button_texts(code_modal: Node) -> Array:
	var result := []
	for button: Button in code_modal.get_node(
		"Dim/EntryPanel/Margin/VBox/DigitSources"
	).get_children():
		result.append(button.text)
	return result


func _press_code_digit(code_modal: Node, digit: int) -> bool:
	for button: Button in code_modal.get_node(
		"Dim/EntryPanel/Margin/VBox/DigitSources"
	).get_children():
		if button.text == str(digit):
			button.pressed.emit()
			return true
	return false


func _cleanup_fail(room: Node, message: String) -> void:
	paused = false
	if is_instance_valid(room):
		room.queue_free()
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false
	push_error(message)
	quit(1)
