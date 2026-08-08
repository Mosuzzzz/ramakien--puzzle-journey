extends SceneTree

const CameraFraming := preload("res://scenes/core/camera_framing.gd")

var _failures := 0


func _initialize() -> void:
	_check_cover(Vector2(1920, 1080), Vector2(1448, 1086), 1.3)
	_check_cover(Vector2(2048, 1280), Vector2(1448, 1086), 1.3)
	_check_cover(Vector2(2560, 1080), Vector2(1448, 1086), 1.3)
	_expect(
		CameraFraming.cover_zoom(Vector2.ZERO, Vector2(1448, 1086), 1.3) == 1.3,
		"zero viewport keeps base zoom"
	)
	_expect(
		CameraFraming.cover_zoom(Vector2(1920, 1080), Vector2.ZERO, 1.3) == 1.3,
		"zero map keeps base zoom"
	)
	_check_chapter_9_lifecycle()
	_finish()


func _check_cover(viewport_size: Vector2, map_size: Vector2, base_zoom: float) -> void:
	var zoom := CameraFraming.cover_zoom(viewport_size, map_size, base_zoom)
	var visible_world_size := viewport_size / zoom
	_expect(visible_world_size.x <= map_size.x, "camera width stays inside map")
	_expect(visible_world_size.y <= map_size.y, "camera height stays inside map")
	_expect(zoom >= base_zoom, "camera does not zoom farther out than normal chapters")


func _check_chapter_9_lifecycle() -> void:
	var source := FileAccess.get_file_as_string("res://scenes/chapter_9/chapter_9.gd")
	_expect(source.contains("CameraFraming.cover_zoom"), "chapter 9 uses cover zoom")
	_expect(source.contains("size_changed.connect"), "chapter 9 reacts to viewport resize")
	_expect(
		source.contains("call_deferred(\"_configure_chapter_9_camera\")"),
		"chapter 9 waits until the scene is ready"
	)
	_expect(source.contains("camera.limit_bottom"), "chapter 9 applies map bounds")
	_expect(
		source.contains("configure_props_above_characters(_chapter_9_props, _y_sort_root)"),
		"chapter 9 configures prop layering when ready"
	)
	_expect(
		source.contains("props.z_as_relative = false"),
		"chapter 9 props use a global drawing layer"
	)
	_expect(
		source.contains("props.z_index = actors.z_index + 1"),
		"chapter 9 props draw above actors"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _finish() -> void:
	if _failures == 0:
		print("PASS: camera framing runtime")
	quit(_failures)
