extends SceneTree

const WIDE_PATH := "/private/tmp/thosakan_boss_hud_1920x1080.png"
const COMPACT_PATH := "/private/tmp/thosakan_boss_hud_1024x768.png"


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	if not await _capture(Vector2i(1920, 1080), WIDE_PATH):
		quit(1)
		return
	if not await _capture(Vector2i(1024, 768), COMPACT_PATH):
		quit(1)
		return
	print("CAPTURED: %s" % WIDE_PATH)
	print("CAPTURED: %s" % COMPACT_PATH)
	quit(0)


func _capture(viewport_size: Vector2i, path: String) -> bool:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#596169")
	viewport.add_child(background)
	var packed := load("res://scenes/props/thosakan.tscn") as PackedScene
	if packed == null:
		push_error("Thosakan scene failed to load")
		viewport.queue_free()
		return false
	var boss := packed.instantiate()
	(boss.get_node("Sprite") as AnimatedSprite2D).hide()
	viewport.add_child(boss)
	for frame in 8:
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != viewport_size:
		push_error("Invalid capture for %s" % path)
		viewport.queue_free()
		return false
	var error := image.save_png(path)
	viewport.queue_free()
	await process_frame
	if error != OK:
		push_error("Failed to save %s (error %d)" % [path, error])
		return false
	return true
