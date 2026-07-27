extends SceneTree


const EXPECTED_QUESTIONS: Array[String] = [
	"คำใดสะกดถูกต้อง",
	"ข้อใดใช้ภาษาได้สุภาพที่สุด",
	"ข้อใดเป็นคำอุทาน",
	"คำว่า “เขา” ในประโยค “เขากำลังเล่นฟุตบอล” เป็นคำชนิดใด",
]

const EXPECTED_CHOICES: Array[Array] = [
	["อนุญาติ", "อนุญาต", "อนุยาต"],
	["เฮ้ย เอาของมาให้หน่อย", "ช่วยหยิบหนังสือให้ฉันหน่อยได้ไหม", "เอาหนังสือมาเดี๋ยวนี้"],
	["โอ๊ย! เจ็บจัง", "ฉันเดินไปโรงเรียน", "น้องอ่านหนังสือ"],
	["คำนาม", "คำสรรพนาม", "คำกริยา"],
]

const CORRECT_INDICES: Array[int] = [1, 1, 0, 1]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var chapter_scene := load("res://scenes/chapter_4/chapter_4.tscn") as PackedScene
	if chapter_scene == null:
		_fail("Chapter 4 scene could not be loaded")
		return

	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await process_frame
	paused = false

	chapter.call("switch_player_to_hanuman")
	await process_frame
	await process_frame
	chapter.call("set_magic_trail_random_seed", 424242)
	var hanuman := chapter.get_node_or_null("YSortRoot/Player")
	var minimap := chapter.get_node_or_null("YSortRoot/Player/HUD/MiniMap")
	var minimap_texture := chapter.get_node_or_null("YSortRoot/Player/HUD/MiniMap/MapClip/MapTexture") as TextureRect
	if hanuman == null or minimap == null or minimap_texture == null:
		_fail("Hanuman HUD minimap nodes are missing after the cutscene switch")
		return
	if not minimap.visible or minimap_texture.texture == null:
		_fail("Hanuman minimap did not initialize after the cutscene switch")
		return

	var trail := chapter.get_node_or_null("YSortRoot/MagicTrail") as Area2D
	var quiz := chapter.get_node_or_null("MagicTrailQuiz")
	var portal := chapter.get_node_or_null("YSortRoot/Chapter5Portal")
	if trail == null or quiz == null or portal == null:
		_fail("Chapter 4 magic trail nodes are missing")
		return

	chapter.call("start_magic_trail_quest")
	await process_frame
	var point_pools: Array = chapter.call("get_magic_trail_point_pools")
	if point_pools.size() != 5:
		_fail("Magic trail did not expose four progress pools and one exit pool")
		return
	for pool_index: int in point_pools.size():
		var pool: Array = point_pools[pool_index]
		if pool.size() < 2:
			_fail("Magic trail pool %d does not contain enough random walkable points" % pool_index)
			return
	if not trail.visible:
		_fail("Magic trail did not appear when the quest started")
		return
	if not portal.locked:
		_fail("Chapter 5 portal was not locked during the trail quest")
		return
	if chapter.call("get_magic_trail_progress") != 0:
		_fail("Magic trail quest did not start at 0/4")
		return

	var first_position := trail.global_position
	if not _pool_contains(point_pools[0], first_position):
		_fail("The first magic trail point was not randomized inside the far walkable pool")
		return
	chapter.call("_on_magic_trail_interaction_requested", trail)
	await process_frame
	if not _quiz_matches(quiz, 0):
		return
	quiz.call("_on_choice_pressed", 0)
	await trail.movement_finished
	if chapter.call("get_magic_trail_progress") != 0:
		_fail("A wrong answer advanced magic trail progress")
		return
	if trail.global_position == first_position:
		_fail("A wrong answer did not move the magic trail to a detour")
		return
	if not _pool_contains(point_pools[0], trail.global_position):
		_fail("A wrong first answer moved the magic trail outside the far walkable pool")
		return

	var portal_position: Vector2 = portal.global_position
	var previous_distance := trail.global_position.distance_to(portal_position)
	for index: int in 4:
		chapter.call("_on_magic_trail_interaction_requested", trail)
		await process_frame
		if not _quiz_matches(quiz, index):
			return
		quiz.call("_on_choice_pressed", CORRECT_INDICES[index])
		await trail.movement_finished
		if chapter.call("get_magic_trail_progress") != index + 1:
			_fail("Correct answer did not advance magic trail progress to %d/4" % (index + 1))
			return
		var expected_pool_index := index + 1
		if not _pool_contains(point_pools[expected_pool_index], trail.global_position):
			_fail("Correct answer %d did not select a walkable point from the expected distance pool" % (index + 1))
			return
		var current_distance := trail.global_position.distance_to(portal_position)
		if current_distance >= previous_distance:
			_fail("Correct answer %d did not move the trail closer to the Chapter 5 portal" % (index + 1))
			return
		previous_distance = current_distance

	if portal.locked:
		_fail("Chapter 5 portal stayed locked after four correct answers")
		return
	await create_timer(0.8).timeout
	if trail.visible:
		_fail("The final magic trail did not fade out after four correct answers")
		return
	if trail.monitoring or trail.call("is_interaction_enabled"):
		_fail("The faded magic trail can still be interacted with")
		return
	var quest := root.get_node("Quest")
	if quest.call("is_completed"):
		_fail("The follow-Thosakan quest was incorrectly marked complete")
		return
	var quest_name := quest.get_node(
		"PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel"
	) as Label
	var quest_detail := quest.get_node(
		"PageDim/Page/PageMargin/Columns/Detail/PageTextLabel"
	) as Label
	if quest_name.text != "ตามรอยทศกัณฐ์":
		_fail("The quest did not change to follow Thosakan")
		return
	if quest_detail.text != "เดินทางออกจากป่าเพื่อตามหานางสีดา":
		_fail("The follow-Thosakan quest showed the wrong detail")
		return
	if quest.call("get_target_count") != 1:
		_fail("The follow-Thosakan quest did not target the Chapter 5 portal")
		return

	print("Chapter 4 magic trail runtime passed")
	quit(0)


func _pool_contains(pool: Array, point: Vector2) -> bool:
	for candidate: Variant in pool:
		if (candidate as Vector2).is_equal_approx(point):
			return true
	return false


func _quiz_matches(quiz: Node, index: int) -> bool:
	var question_label := quiz.get_node("Dim/Page/PageMargin/VBox/QuestionLabel") as Label
	if question_label.text != EXPECTED_QUESTIONS[index]:
		_fail("Trail step %d showed the wrong question" % (index + 1))
		return false
	var choices := quiz.get_node("Dim/Page/PageMargin/VBox/Choices")
	if choices.get_child_count() != 3:
		_fail("Trail step %d did not show exactly three choices" % (index + 1))
		return false
	for choice_index: int in 3:
		var button := choices.get_child(choice_index) as Button
		if button.text != EXPECTED_CHOICES[index][choice_index]:
			_fail("Trail step %d showed the wrong choice text" % (index + 1))
			return false
	return true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
