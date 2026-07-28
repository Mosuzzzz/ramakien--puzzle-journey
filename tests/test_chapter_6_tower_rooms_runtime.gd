extends SceneTree

const LEFT_ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const RIGHT_ROOM := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const CHAPTER_6 := "res://scenes/chapter_6/chapter_6.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
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
		if Vector2(exit_portal.get("target_spawn")) == Vector2.ZERO:
			_fail("%s exit has no return spawn" % path)
			return
		room.queue_free()
	print("Chapter 6 tower room runtime passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
