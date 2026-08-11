extends SceneTree

const BOSS_WIDE_PATH := "/private/tmp/miyarap_boss_hud_1920x1080.png"
const BOSS_NARROW_PATH := "/private/tmp/miyarap_boss_hud_1024x768.png"
const QUEST_WIDE_PATH := "/private/tmp/quest_long_title_1920x1080.png"
const QUEST_NARROW_PATH := "/private/tmp/quest_long_title_1024x768.png"
const LONG_QUEST_NAME := "สำรวจพระราชวังเพื่อหานางสีดา"
const LONG_QUEST_DETAIL := "สำรวจห้องต่าง ๆ ภายในพระราชวังและตามหานางสีดา"


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	if not await _capture_boss(Vector2i(1920, 1080), BOSS_WIDE_PATH):
		quit(1)
		return
	if not await _capture_boss(Vector2i(1024, 768), BOSS_NARROW_PATH):
		quit(1)
		return
	if not await _capture_quest(Vector2i(1920, 1080), QUEST_WIDE_PATH):
		quit(1)
		return
	if not await _capture_quest(Vector2i(1024, 768), QUEST_NARROW_PATH):
		quit(1)
		return
	print("CAPTURED: %s" % BOSS_WIDE_PATH)
	print("CAPTURED: %s" % BOSS_NARROW_PATH)
	print("CAPTURED: %s" % QUEST_WIDE_PATH)
	print("CAPTURED: %s" % QUEST_NARROW_PATH)
	quit(0)


func _capture_boss(viewport_size: Vector2i, path: String) -> bool:
	var viewport := _make_viewport(viewport_size)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#596169")
	viewport.add_child(background)
	var boss := (load("res://scenes/props/miyarap.tscn") as PackedScene).instantiate()
	(boss.get_node("Sprite") as AnimatedSprite2D).hide()
	(boss.get_node("Shadow") as Sprite2D).hide()
	viewport.add_child(boss)
	for frame in 8:
		await process_frame
	var saved := _save_viewport(viewport, path, viewport_size)
	viewport.queue_free()
	await process_frame
	return saved


func _capture_quest(viewport_size: Vector2i, path: String) -> bool:
	var viewport := _make_viewport(viewport_size)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://assets/map/chapter_8/main_map.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	viewport.add_child(background)
	var quest := (load("res://scenes/ui/quest_log.tscn") as PackedScene).instantiate()
	viewport.add_child(quest)
	quest.set_quest(LONG_QUEST_NAME, LONG_QUEST_DETAIL)
	quest.call("_on_quest_button_pressed")
	for frame in 8:
		await process_frame
	var saved := _save_viewport(viewport, path, viewport_size)
	viewport.queue_free()
	await process_frame
	return saved


func _make_viewport(viewport_size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport


func _save_viewport(viewport: SubViewport, path: String, expected_size: Vector2i) -> bool:
	var captured_image := viewport.get_texture().get_image()
	if captured_image == null or captured_image.is_empty():
		push_error("Capture is empty: %s" % path)
		return false
	if captured_image.get_size() != expected_size:
		push_error("Capture size mismatch for %s: expected %s, got %s" % [
			path, expected_size, captured_image.get_size()
		])
		return false
	var error := captured_image.save_png(path)
	if error != OK:
		push_error("Failed to save capture %s (error %d)" % [path, error])
		return false
	return true
