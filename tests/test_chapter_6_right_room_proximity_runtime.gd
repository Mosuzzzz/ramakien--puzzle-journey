extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")
const ROOM_SCENE := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const JAR_PATHS := [
	"JarInteractions/JarUpperLeft",
	"JarInteractions/JarUpperRight",
	"JarInteractions/JarLowerLeft",
	"JarInteractions/JarLowerRight",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	var room := (load(ROOM_SCENE) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	await physics_frame

	var player := room.get_node("YSortRoot/Player") as CharacterBody2D
	player.global_position = Vector2(627, 800)
	await physics_frame
	await physics_frame
	if _visible_jar_prompts(room) != []:
		_fail(room, "Jar prompts appeared while the player was in the middle of the room")
		return
	if room.get_node("PedestalInteraction/Prompt").is_visible_in_tree():
		_fail(room, "Pedestal prompt appeared before the player was close to the pedestal")
		return

	player.global_position = Vector2(245, 450)
	await physics_frame
	await physics_frame
	if _visible_jar_prompts(room) != []:
		_fail(room, "Jar prompt appeared before the player was close to the jar")
		return

	player.global_position = Vector2(245, 425)
	await physics_frame
	await physics_frame
	if _visible_jar_prompts(room) != [0]:
		_fail(room, "Approaching one jar did not show exactly that jar's prompt")
		return

	player.global_position = Vector2(627, 720)
	await physics_frame
	await physics_frame
	if _visible_jar_prompts(room) != []:
		_fail(room, "Jar prompt remained visible after leaving its interaction range")
		return
	if not room.get_node("PedestalInteraction/Prompt").is_visible_in_tree():
		_fail(room, "Pedestal prompt did not appear when the player was close")
		return

	room.queue_free()
	await process_frame
	print("Chapter 6 right-room proximity runtime passed")
	quit(0)


func _visible_jar_prompts(room: Node) -> Array[int]:
	var visible_indices: Array[int] = []
	for index: int in range(JAR_PATHS.size()):
		var prompt := room.get_node("%s/Prompt" % JAR_PATHS[index]) as Label
		if prompt.is_visible_in_tree():
			visible_indices.append(index)
	return visible_indices


func _fail(room: Node, message: String) -> void:
	push_error(message)
	room.queue_free()
	quit(1)
