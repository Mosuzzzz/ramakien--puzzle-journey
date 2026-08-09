extends SceneTree

const ROOM_SCENE_PATH := "res://scenes/chapter_6/chapter_6_room_right.tscn"

var _failed := false


func _initialize() -> void:
	var packed := load(ROOM_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "right-room scene must load")
	if packed == null:
		quit(1)
		return
	var room := packed.instantiate()
	_assert_visible(room, "JarInteractions")
	_assert_visible(room, "PedestalInteraction")
	_assert_hidden(room, "RightJarModal")
	_assert_hidden(room, "RightCodeModal")
	_assert_hidden(room, "JarInteractions/JarUpperLeft/Prompt")
	_assert_hidden(room, "PedestalInteraction/Prompt")
	room.free()

	if _failed:
		quit(1)
	else:
		print("PASS: Chapter 6 right-room interaction visibility")
		quit(0)


func _assert_visible(room: Node, node_path: NodePath) -> void:
	var node := room.get_node_or_null(node_path) as CanvasItem
	_assert_true(node != null, "%s must exist" % node_path)
	if node != null:
		_assert_true(node.visible, "%s must remain visible so interaction prompts can be shown" % node_path)


func _assert_hidden(room: Node, node_path: NodePath) -> void:
	var node := room.get_node_or_null(node_path)
	if node == null and not str(node_path).contains("/"):
		node = room.find_child(str(node_path), true, false)
	_assert_true(node != null, "%s must exist" % node_path)
	if node != null:
		_assert_true(not bool(node.get("visible")), "%s must start hidden" % node_path)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FAIL: %s" % message)
