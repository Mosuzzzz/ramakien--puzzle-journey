extends SceneTree

signal _scene_change_race_finished(changed_before_timeout: bool)

const CHAPTER_5 := "res://scenes/chapter_5/chapter_5.tscn"
const CHAPTER_6 := "res://scenes/chapter_6/chapter_6.tscn"
const CHAPTER_7 := "res://scenes/chapter_7/chapter_7.tscn"
const LEFT_ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const RIGHT_ROOM := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const SCENE_CHANGE_TIMEOUT_SECONDS := 3.0
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
		Vector2(627, 880)
	):
		return
	if not await _activate_portal(
		current_scene,
		"YSortRoot/ExitPortal",
		"viewport_click",
		CHAPTER_6,
		Vector2(380, 525),
		120.0
	):
		return
	if not await _verify_clear_return_spawn(
		current_scene,
		Vector2(380, 525),
		"YSortRoot/LeftTowerRoomPortal"
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
		Vector2(627, 930)
	):
		return
	if not await _activate_portal(
		current_scene,
		"YSortRoot/ExitPortal",
		"key",
		CHAPTER_6,
		Vector2(1068, 525),
		120.0
	):
		return
	if not await _verify_clear_return_spawn(
		current_scene,
		Vector2(1068, 525),
		"YSortRoot/RightTowerRoomPortal"
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
	GameState.chapter_6_gate_unlocked = true
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
		if not _verify_room_player_visuals(current_scene):
			return
		if not await _verify_room_movement_and_collisions(current_scene):
			return

	GameState.chapter_6_gate_unlocked = false
	print("Chapter 6 tower room automated playtest passed")
	quit(0)


func _change_scene(path: String) -> bool:
	var error := change_scene_to_file(path)
	if error != OK:
		_fail("Could not change to %s (error %d)" % [path, error])
		return false
	if not await _wait_for_scene_change("Changing to %s" % path):
		return false
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

	var detection_position := portal.global_position
	if portal_path.ends_with("LeftTowerRoomPortal"):
		detection_position += Vector2(140, 0)
	elif portal_path.ends_with("RightTowerRoomPortal"):
		detection_position += Vector2(-140, 0)
	player.global_position = detection_position
	for _frame: int in range(3):
		await physics_frame
		if portal.get("_player") == player:
			break
	if portal.get("_player") != player:
		_fail("%s did not detect the nearby player" % portal_path)
		return false

	if input_kind == "key":
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_E
		key_event.pressed = true
		portal.call("_input", key_event)
	elif input_kind == "viewport_click":
		var viewport := portal.get_viewport()
		var click_position := portal.get_global_transform_with_canvas().origin
		var click_event := InputEventMouseButton.new()
		click_event.button_index = MOUSE_BUTTON_LEFT
		click_event.button_mask = MOUSE_BUTTON_MASK_LEFT
		click_event.pressed = true
		click_event.position = click_position
		click_event.global_position = click_position
		viewport.push_input(click_event, true)
	else:
		var click_event := InputEventMouseButton.new()
		click_event.button_index = MOUSE_BUTTON_LEFT
		click_event.pressed = true
		portal.call("_on_input_event", root, click_event, 0)

	if not await _wait_for_scene_change("Activating %s" % portal_path):
		return false
	await process_frame
	if current_scene == null or current_scene.scene_file_path != expected_scene:
		_fail("%s did not activate its configured scene" % portal_path)
		return false
	var spawned_player := current_scene.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	if spawned_player == null:
		_fail("%s produced no destination player" % portal_path)
		return false
	var applied_spawn := spawned_player.global_position.distance_to(expected_spawn) <= spawn_tolerance
	var staged_spawn := (
		GameState.next_spawn.is_finite()
		and GameState.next_spawn.distance_to(expected_spawn) <= spawn_tolerance
	)
	if not applied_spawn and not staged_spawn:
		_fail("%s produced the wrong destination spawn" % portal_path)
		return false
	if staged_spawn:
		spawned_player.global_position = GameState.next_spawn
		GameState.next_spawn = Vector2.INF
	return true


func _wait_for_scene_change(context: String) -> bool:
	var race_state := {"settled": false}
	var timeout := create_timer(SCENE_CHANGE_TIMEOUT_SECONDS)
	var on_scene_changed := func() -> void:
		if race_state["settled"]:
			return
		race_state["settled"] = true
		_scene_change_race_finished.emit(true)
	var on_timeout := func() -> void:
		if race_state["settled"]:
			return
		race_state["settled"] = true
		_scene_change_race_finished.emit(false)

	scene_changed.connect(on_scene_changed, CONNECT_ONE_SHOT)
	timeout.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	var changed_before_timeout: bool = await _scene_change_race_finished
	if scene_changed.is_connected(on_scene_changed):
		scene_changed.disconnect(on_scene_changed)
	if timeout.timeout.is_connected(on_timeout):
		timeout.timeout.disconnect(on_timeout)
	if not changed_before_timeout:
		_fail(
			"%s timed out after %.1f seconds waiting for a scene change"
			% [context, SCENE_CHANGE_TIMEOUT_SECONDS]
		)
		return false
	return true


func _verify_clear_return_spawn(
	chapter: Node,
	expected_spawn: Vector2,
	tower_portal_path: String
) -> bool:
	await physics_frame
	var player := chapter.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	var tower_portal := chapter.get_node_or_null(tower_portal_path) as Area2D
	if player == null or tower_portal == null:
		_fail("Chapter 6 is missing the returned player or tower portal")
		return false

	var player_shape := CircleShape2D.new()
	player_shape.radius = 9.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player_shape
	query.transform = Transform2D(0.0, expected_spawn)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var space: PhysicsDirectSpaceState2D = chapter.get_world_2d().direct_space_state
	var hits: Array[Dictionary] = space.intersect_shape(query, 32)
	if not hits.is_empty():
		_fail("Chapter 6 return spawn overlaps static collision")
		return false
	if tower_portal.get("_player") == player:
		_fail("Chapter 6 return spawn immediately re-enters the tower trigger")
		return false
	return true


func _verify_room_player_visuals(room: Node) -> bool:
	var player := room.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	if player == null:
		_fail("%s is missing its player" % room.scene_file_path)
		return false

	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var shadow := player.get_node_or_null("Shadow") as Sprite2D
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if sprite == null or shadow == null or camera == null or collision == null:
		_fail("%s is missing a player visual, camera, or collision node" % room.scene_file_path)
		return false

	var base_player := preload("res://scenes/player/player.tscn").instantiate() as CharacterBody2D
	var base_sprite := base_player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var base_shadow := base_player.get_node("Shadow") as Sprite2D
	var expected_sprite_scale := base_sprite.scale * 1.5
	var expected_shadow_scale := base_shadow.scale * 1.5
	base_player.free()

	if not sprite.scale.is_equal_approx(expected_sprite_scale):
		_fail("%s player sprite is not enlarged to 1.5x" % room.scene_file_path)
		return false
	if not shadow.scale.is_equal_approx(expected_shadow_scale):
		_fail("%s player shadow is not enlarged to 1.5x" % room.scene_file_path)
		return false
	if not camera.position.is_equal_approx(Vector2.ZERO):
		_fail("%s camera is offset from the player physics origin" % room.scene_file_path)
		return false
	if not player.scale.is_equal_approx(Vector2.ONE):
		_fail("%s scales the player physics body instead of visuals only" % room.scene_file_path)
		return false
	if not collision.scale.is_equal_approx(Vector2.ONE):
		_fail("%s scales the player collision instead of visuals only" % room.scene_file_path)
		return false

	var frame_texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame_texture == null:
		_fail("%s player sprite has no current frame texture" % room.scene_file_path)
		return false
	var visual_foot_y := sprite.position.y + frame_texture.get_height() * sprite.scale.y * 0.5
	if visual_foot_y < -15.0 or visual_foot_y > -5.0:
		_fail(
			"%s player feet are misaligned with the physics origin (%.1f px)"
			% [room.scene_file_path, visual_foot_y]
		)
		return false
	return true


func _verify_room_movement_and_collisions(room: Node) -> bool:
	var player := room.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	if player == null:
		_fail("%s is missing its player" % room.scene_file_path)
		return false

	var spawn := Vector2(627, 880) if room.scene_file_path == LEFT_ROOM else Vector2(627, 930)
	var left_end := await _drive_player(player, spawn, Vector2(-300, 0), 12)
	if left_end.x > spawn.x - 25.0:
		_fail("%s player cannot move left from the entry spawn" % room.scene_file_path)
		return false
	var right_end := await _drive_player(player, spawn, Vector2(300, 0), 12)
	if right_end.x < spawn.x + 25.0:
		_fail("%s player cannot move right from the entry spawn" % room.scene_file_path)
		return false

	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var boundary_end := await _drive_player(player, spawn, direction * 600.0, 120)
		if (
			boundary_end.x < 0.0
			or boundary_end.x > 1254.0
			or boundary_end.y < 0.0
			or boundary_end.y > 1254.0
		):
			_fail("%s player escaped beyond the room artwork" % room.scene_file_path)
			return false
	return true


func _drive_player(
	player: CharacterBody2D,
	start: Vector2,
	auto_velocity: Vector2,
	frame_count: int
) -> Vector2:
	player.global_position = start
	await physics_frame
	for _frame: int in range(frame_count):
		player.move_and_collide(auto_velocity / 60.0)
		await physics_frame
	return player.global_position


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	paused = false
	push_error(message)
	quit(1)
