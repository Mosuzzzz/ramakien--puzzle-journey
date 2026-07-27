extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame

	var player := chapter.get_node("YSortRoot/Player") as CharacterBody2D
	var return_portal := chapter.get_node("YSortRoot/Chapter2Portal") as Area2D
	if not return_portal.global_position.is_equal_approx(player.global_position):
		_fail("Chapter 2 return portal is not at the Chapter 3 starting point")
		return
	if String(return_portal.get("prompt_text")) != "กด E เพื่อกลับไปด่านก่อนหน้า":
		_fail("Chapter 2 return portal lost its interaction prompt")
		return

	print("Chapter 3 return portal spawn runtime passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
