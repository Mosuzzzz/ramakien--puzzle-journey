extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var quest_scene := load("res://scenes/ui/quest_log.tscn") as PackedScene
	var quest := quest_scene.instantiate()
	root.add_child(quest)
	await process_frame

	var target_one := Node2D.new()
	var target_two := Node2D.new()
	root.add_child(target_one)
	root.add_child(target_two)
	var targets: Array[Node2D] = [target_one, target_two]

	quest.call("set_quest", "กวาดล้างยักษ์ลาดตระเวน", "0/2")
	quest.call("set_targets", targets)
	if int(quest.call("get_target_count")) != 2:
		_fail("Quest Log did not create two target markers")
		return

	quest.call("set_completed", true)
	var name_label := quest.get_node(
		"PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel"
	) as Label
	if not name_label.modulate.is_equal_approx(Color("#67d56b")):
		_fail("Completed quest text did not turn green")
		return

	target_one.free()
	quest.call("_update_marker")
	if int(quest.call("get_target_count")) != 1:
		_fail("Removed target marker was not cleaned up")
		return

	quest.call("set_quest", "ตามรอยทศกัณฐ์", "เดินทางออกจากป่าเพื่อตามหานางสีดา", Vector2.ZERO)
	if int(quest.call("get_target_count")) != 0:
		_fail("Single-target quest did not clear multiple targets")
		return
	if quest.get("target_position") != Vector2.ZERO:
		_fail("Single-target quest compatibility was broken")
		return

	print("Chapter 3 patrol quest runtime passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
