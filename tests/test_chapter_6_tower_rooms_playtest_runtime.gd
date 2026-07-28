extends SceneTree

const CHAPTER_5 := "res://scenes/chapter_5/chapter_5.tscn"
const CHAPTER_6 := "res://scenes/chapter_6/chapter_6.tscn"
const CHAPTER_7 := "res://scenes/chapter_7/chapter_7.tscn"
const LEFT_ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const RIGHT_ROOM := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const GameState := preload("res://scenes/core/game_state.gd")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.chapter_6_intro_played = false
	if not await _change_scene(CHAPTER_6):
		return

	var chapter := current_scene
	var cutscene := chapter.get_node_or_null("Chapter6CutsceneLayer/Chapter6Cutscene")
	if cutscene == null or not cutscene.is_visible_in_tree():
		_fail("Chapter 6 first-load cutscene is not effectively visible")
		return
	cutscene.call("_finish_cutscene")
	await process_frame
	if paused or not GameState.chapter_6_intro_played:
		_fail("Finishing the Chapter 6 cutscene did not unpause and persist its state")
		return

	if not await _activate_portal(
		chapter,
		"YSortRoot/LeftTowerRoomPortal",
		"key",
		LEFT_ROOM,
		Vector2(627, 1010)
	):
		return
	if not await _activate_portal(
		current_scene,
		"YSortRoot/ExitPortal",
		"click",
		CHAPTER_6,
		Vector2(190, 650),
		120.0
	):
		return
	if current_scene.get_node_or_null("Chapter6CutsceneLayer/Chapter6Cutscene") != null or paused:
		_fail("Chapter 6 cutscene replayed after returning from the left room")
		return

	if not await _activate_portal(
		current_scene,
		"YSortRoot/RightTowerRoomPortal",
		"click",
		RIGHT_ROOM,
		Vector2(627, 1010)
	):
		return
	if not await _activate_portal(
		current_scene,
		"YSortRoot/ExitPortal",
		"key",
		CHAPTER_6,
		Vector2(1258, 650),
		120.0
	):
		return
	if current_scene.get_node_or_null("Chapter6CutsceneLayer/Chapter6Cutscene") != null or paused:
		_fail("Chapter 6 cutscene replayed after returning from the right room")
		return

	if not await _activate_portal(
		current_scene,
		"YSortRoot/Chapter5Portal",
		"key",
		CHAPTER_5,
		Vector2(1700, 574)
	):
		return

	paused = false
	GameState.chapter_6_intro_played = true
	GameState.next_spawn = Vector2.INF
	if not await _change_scene(CHAPTER_6):
		return
	if not await _activate_portal(
		current_scene,
		"YSortRoot/Chapter7Portal",
		"click",
		CHAPTER_7,
		Vector2(1083, 1462.5)
	):
		return

	for room_path: String in [LEFT_ROOM, RIGHT_ROOM]:
		paused = false
		GameState.next_spawn = Vector2.INF
		if not await _change_scene(room_path):
			return
		if not await _verify_room_movement_and_collisions(current_scene):
			return

	print("Chapter 6 tower room automated playtest passed")
	quit(0)


func _change_scene(path: String) -> bool:
	var error := change_scene_to_file(path)
	if error != OK:
		_fail("Could not change to %s (error %d)" % [path, error])
		return false
	await scene_changed
	await process_frame
	if current_scene == null or current_scene.scene_file_path != path:
		_fail("Scene change did not reach %s" % path)
		return false
	return true


func _activate_portal(
	scene: Node,
	portal_path: String,
	input_kind: String,
	expected_scene: String,
	expected_spawn: Vector2,
	spawn_tolerance: float = 10.0
) -> bool:
	var player := scene.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	var portal := scene.get_node_or_null(portal_path) as Area2D
	if player == null or portal == null:
		_fail("%s is missing a player or portal %s" % [scene.name, portal_path])
		return false
	if Vector2(portal.get("target_spawn")) != expected_spawn:
		_fail("%s is configured with the wrong destination spawn" % portal_path)
		return false

	var approach_position := portal.global_position
	var approach_velocity := Vector2.ZERO
	if portal_path.ends_with("LeftTowerRoomPortal"):
		approach_position += Vector2(220, 0)
		approach_velocity = Vector2(-220, 0)
	elif portal_path.ends_with("RightTowerRoomPortal"):
		approach_position += Vector2(-220, 0)
		approach_velocity = Vector2(220, 0)
	elif portal_path.ends_with("ExitPortal"):
		approach_position += Vector2(0, -120)
		approach_velocity = Vector2(0, 220)
	elif portal_path.ends_with("Chapter5Portal"):
		approach_position += Vector2(0, -100)
		approach_velocity = Vector2(0, 220)
	elif portal_path.ends_with("Chapter7Portal"):
		approach_position += Vector2(0, 160)
		approach_velocity = Vector2(0, -220)
	player.global_position = approach_position
	player.set("auto_run_velocity", approach_velocity)
	for _frame: int in range(120):
		await physics_frame
		if portal.get("_player") == player:
			break
	player.set("auto_run_velocity", Vector2.ZERO)
	await physics_frame
	if portal.get("_player") != player:
		_fail("%s did not detect the nearby player" % portal_path)
		return false

	if input_kind == "key":
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_E
		key_event.pressed = true
		portal.call("_input", key_event)
	else:
		var click_event := InputEventMouseButton.new()
		click_event.button_index = MOUSE_BUTTON_LEFT
		click_event.pressed = true
		portal.call("_on_input_event", root, click_event, 0)

	await scene_changed
	await process_frame
	if current_scene == null or current_scene.scene_file_path != expected_scene:
		_fail("%s did not activate its configured scene" % portal_path)
		return false
	var spawned_player := current_scene.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	if (
		spawned_player == null
		or spawned_player.global_position.distance_to(expected_spawn) > spawn_tolerance
	):
		_fail("%s produced the wrong destination spawn" % portal_path)
		return false
	return true


func _verify_room_movement_and_collisions(room: Node) -> bool:
	var player := room.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	if player == null:
		_fail("%s is missing its player" % room.scene_file_path)
		return false

	var open_start := Vector2(400, 500)
	var open_end := await _drive_player(player, open_start, Vector2(300, 0), 12)
	if open_end.x < open_start.x + 30.0:
		_fail("%s player did not move across open floor" % room.scene_file_path)
		return false

	var top_end := await _drive_player(player, Vector2(627, 330), Vector2(0, -600), 30)
	if top_end.y < 258.0:
		_fail("%s player crossed the top wall" % room.scene_file_path)
		return false
	var left_end := await _drive_player(player, Vector2(340, 650), Vector2(-600, 0), 30)
	if left_end.x < 273.0:
		_fail("%s player crossed the left wall" % room.scene_file_path)
		return false
	var right_end := await _drive_player(player, Vector2(914, 650), Vector2(600, 0), 30)
	if right_end.x > 981.0:
		_fail("%s player crossed the right wall" % room.scene_file_path)
		return false
	var bottom_end := await _drive_player(player, Vector2(400, 1010), Vector2(0, 600), 30)
	if bottom_end.y > 1067.0:
		_fail("%s player crossed the bottom wall" % room.scene_file_path)
		return false

	var altar_hit := await _drive_player(player, Vector2(430, 680), Vector2(600, 0), 30)
	if altar_hit.x > 514.0:
		_fail("%s player crossed the central altar collision" % room.scene_file_path)
		return false
	var escape_end := await _drive_player(player, altar_hit, Vector2(0, 600), 18)
	if escape_end.y < altar_hit.y + 120.0:
		_fail("%s central altar collision trapped the player" % room.scene_file_path)
		return false
	var traverse_end := await _drive_player(player, Vector2(450, 850), Vector2(0, -600), 30)
	if traverse_end.y > 570.0:
		_fail("%s player could not traverse around the central altar" % room.scene_file_path)
		return false
	return true


func _drive_player(
	player: CharacterBody2D,
	start: Vector2,
	auto_velocity: Vector2,
	frame_count: int
) -> Vector2:
	player.global_position = start
	player.set("auto_run_velocity", auto_velocity)
	await physics_frame
	for _frame: int in range(frame_count):
		await physics_frame
	player.set("auto_run_velocity", Vector2.ZERO)
	await physics_frame
	return player.global_position


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	paused = false
	push_error(message)
	quit(1)
