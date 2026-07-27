extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var feather_scene := load("res://scenes/props/jatayu_feather.tscn") as PackedScene
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var feather := feather_scene.instantiate() as Area2D
	var player := player_scene.instantiate() as CharacterBody2D
	root.add_child(feather)
	root.add_child(player)
	feather.global_position = Vector2(200, 200)
	player.global_position = Vector2(200, 200)
	await physics_frame
	await physics_frame
	if not (feather.get_node("Prompt") as Label).visible:
		_fail("Player entered the feather range but the E prompt stayed hidden")
		return
	feather.queue_free()
	player.queue_free()
	await process_frame

	var chapter_scene := load("res://scenes/chapter_3/chapter_3.tscn") as PackedScene
	var chapter := chapter_scene.instantiate()
	root.add_child(chapter)
	current_scene = chapter
	await physics_frame
	paused = false
	await physics_frame

	var player_shape := CircleShape2D.new()
	player_shape.radius = 9.0
	for spawn: Marker2D in chapter.get_node("FeatherSpawns").get_children():
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = player_shape
		query.transform = Transform2D(0.0, spawn.global_position)
		query.collision_mask = 1
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hits: Array[Dictionary] = chapter.get_world_2d().direct_space_state.intersect_shape(query)
		for hit: Dictionary in hits:
			var collider := hit.get("collider") as Node
			if collider != null and collider.name == "Walls":
				_fail("%s is inside an impassable wall; nearest clear point: %s" % [
					spawn.name,
					_nearest_clear_point(chapter, spawn.global_position, player_shape),
				])
				return

	print("Chapter 3 feather access runtime passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)


func _nearest_clear_point(chapter: Node, origin: Vector2, shape: Shape2D) -> Vector2:
	for radius in range(20, 241, 20):
		for offset in [
			Vector2(radius, 0),
			Vector2(-radius, 0),
			Vector2(0, radius),
			Vector2(0, -radius),
			Vector2(radius, radius),
			Vector2(radius, -radius),
			Vector2(-radius, radius),
			Vector2(-radius, -radius),
		]:
			var candidate: Vector2 = origin + offset
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = shape
			query.transform = Transform2D(0.0, candidate)
			query.collision_mask = 1
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var hits: Array[Dictionary] = chapter.get_world_2d().direct_space_state.intersect_shape(query)
			var blocked := false
			for hit: Dictionary in hits:
				var collider := hit.get("collider") as Node
				if collider != null and collider.name == "Walls":
					blocked = true
					break
			if not blocked:
				return candidate
	return origin
