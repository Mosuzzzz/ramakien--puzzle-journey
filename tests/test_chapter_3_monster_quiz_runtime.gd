extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	paused = false

	var quiz := chapter.get_node("QuestionQuiz")
	var mob1 := chapter.get_node("YSortRoot/Mob1")
	var starting_health := int(mob1.get("_health"))
	if mob1.get("damage_gate") != null:
		_fail("Chapter 3 monster still had a quiz damage gate")
		return
	mob1.call("take_damage", 15)
	if quiz.visible:
		_fail("Shooting a monster still opened the quiz")
		return
	if int(mob1.get("_health")) != starting_health - 15:
		_fail("Chapter 3 monster did not take normal immediate damage")
		return
	mob1.call("take_damage", 15)
	await create_timer(0.2).timeout
	if is_instance_valid(mob1):
		_fail("Chapter 3 monster did not die from normal combat")
		return
	if bool(chapter.get("_post_battle_cutscene_started")):
		_fail("Killing a monster incorrectly started the follow-up cutscene")
		return

	print("Chapter 3 normal monster combat runtime passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
