extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await physics_frame
	paused = false
	await physics_frame

	var player := chapter.get_node("YSortRoot/Player") as CharacterBody2D
	var story_end_spawn := chapter.get_node_or_null("StoryEndSpawn") as Marker2D
	if story_end_spawn == null:
		_fail("Chapter 3 is missing the StoryEndSpawn marker")
		return

	player.global_position = Vector2(250, 850)
	player.velocity = Vector2(160, -80)
	chapter.call("finish_chapter_3_story")

	if not player.global_position.is_equal_approx(story_end_spawn.global_position):
		_fail("Final cutscene did not move the player to StoryEndSpawn")
		return
	if player.velocity != Vector2.ZERO:
		_fail("Final cutscene did not stop the player after teleporting")
		return

	var player_shape := CircleShape2D.new()
	player_shape.radius = 9.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player_shape
	query.transform = Transform2D(0.0, story_end_spawn.global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits: Array[Dictionary] = chapter.get_world_2d().direct_space_state.intersect_shape(query)
	for hit: Dictionary in hits:
		var collider := hit.get("collider") as Node
		if collider != null and collider.name == "Walls":
			_fail("StoryEndSpawn is inside an impassable wall")
			return

	print("Chapter 3 story end spawn runtime passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
