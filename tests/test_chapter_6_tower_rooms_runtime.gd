extends SceneTree

const LEFT_ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const RIGHT_ROOM := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const CHAPTER_6 := "res://scenes/chapter_6/chapter_6.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var chapter_packed := load(CHAPTER_6) as PackedScene
	if chapter_packed == null:
		_fail("Could not load Chapter 6")
		return
	var chapter := chapter_packed.instantiate()
	root.add_child(chapter)
	var left_entrance := chapter.get_node_or_null("YSortRoot/LeftTowerRoomPortal")
	var right_entrance := chapter.get_node_or_null("YSortRoot/RightTowerRoomPortal")
	if left_entrance == null or right_entrance == null:
		_fail("Chapter 6 is missing tower room entrances")
		return
	if String(left_entrance.get("target_scene")) != LEFT_ROOM:
		_fail("Left tower targets the wrong room")
		return
	if String(right_entrance.get("target_scene")) != RIGHT_ROOM:
		_fail("Right tower targets the wrong room")
		return
	chapter.queue_free()

	for path: String in [LEFT_ROOM, RIGHT_ROOM]:
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("Could not load %s" % path)
			return
		var room := packed.instantiate()
		root.add_child(room)
		var player := room.get_node_or_null("YSortRoot/Player")
		var exit_portal := room.get_node_or_null("YSortRoot/ExitPortal")
		var background := room.get_node_or_null("Background")
		var walls := room.get_node_or_null("Walls")
		if player == null or exit_portal == null or background == null or walls == null:
			_fail("%s is missing required room nodes" % path)
			return
		if String(exit_portal.get("target_scene")) != CHAPTER_6:
			_fail("%s exit does not target Chapter 6" % path)
			return
		var expected_spawn := Vector2(190, 650) if path == LEFT_ROOM else Vector2(1258, 650)
		if Vector2(exit_portal.get("target_spawn")) != expected_spawn:
			_fail("%s exit has the wrong return spawn" % path)
			return
		room.queue_free()
	print("Chapter 6 tower room runtime passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
