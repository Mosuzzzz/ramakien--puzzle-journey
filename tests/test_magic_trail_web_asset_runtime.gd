extends SceneTree

const ICON_PATH := "res://assets/ui/icon/magic_trail_icon.png"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(FileAccess.file_exists(ICON_PATH), "tracked magic-trail source PNG exists")
	var packed := load("res://scenes/props/magic_trail.tscn") as PackedScene
	_expect(packed != null, "magic-trail scene loads")
	if packed != null:
		var trail := packed.instantiate()
		var icon := trail.get_node("Icon") as Sprite2D
		_expect(icon.texture != null, "magic-trail texture loads")
		if icon.texture != null:
			_expect(
				icon.texture.resource_path == ICON_PATH,
				"scene uses the Web-safe ASCII source path"
			)
			var image := icon.texture.get_image()
			_expect(image != null and not image.is_empty(), "magic-trail source decodes to pixels")
		trail.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: magic-trail Web asset runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
