extends SceneTree

const EXPECTED_TEXTURES := [
	"res://assets/props/chapter9/image-removebg-preview.png",
	"res://assets/props/chapter9/image-removebg-preview (1).png",
	"res://assets/props/chapter9/image-removebg-preview (2).png",
	"res://assets/props/chapter9/image-removebg-preview (3).png",
]

var _failures := 0


func _initialize() -> void:
	var packed := load("res://scenes/chapter_9/chapter_9.tscn") as PackedScene
	_expect(packed != null, "chapter 9 scene loads")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate()
	var props := scene.get_node_or_null("Chapter9Props")
	_expect(props != null, "chapter 9 exposes an editable props group")
	if props != null:
		_expect(props.get_child_count() == EXPECTED_TEXTURES.size(), "props group contains all four images")
		var actual_paths: Array[String] = []
		for child in props.get_children():
			_expect(child is Sprite2D, "%s is a Sprite2D" % child.name)
			if child is Sprite2D and child.texture != null:
				actual_paths.append(child.texture.resource_path)
		for texture_path: String in EXPECTED_TEXTURES:
			_expect(texture_path in actual_paths, "%s is assigned to a prop" % texture_path)
	scene.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)


func _finish() -> void:
	if _failures == 0:
		print("PASS: chapter 9 props runtime")
	quit(_failures)
