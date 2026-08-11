extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/props/miyarap.tscn") as PackedScene
	_expect(packed != null, "Miyarap scene loads after a clean import")
	if packed == null:
		_finish()
		return
	var boss := packed.instantiate()
	root.add_child(boss)
	await process_frame

	var bar := boss.get_node("BossHUD/BossBar") as TextureProgressBar
	var name_label := boss.find_child("BossName", true, false) as Label
	_expect(name_label != null, "BossName exists")
	if name_label != null:
		_expect(name_label.get_parent() == bar, "BossName follows the BossBar layout")
		_expect(name_label.get_theme_font_size("font_size") >= 24, "BossName is large enough to read")
		_expect(
			name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
			"BossName is horizontally centered"
		)
		_expect(
			name_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER,
			"BossName is vertically centered"
		)
		var bar_rect := bar.get_global_rect()
		var name_rect := name_label.get_global_rect()
		_expect(
			absf(name_rect.get_center().x - bar_rect.get_center().x) <= 1.0,
			"BossName center follows the health bar center"
		)
		var relative_center_y := name_rect.get_center().y - bar_rect.position.y
		_expect(
			relative_center_y >= bar_rect.size.y * 0.4
			and relative_center_y <= bar_rect.size.y * 0.7,
			"BossName sits inside the visual center of the red health tube"
		)

	boss.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: Miyarap boss HUD runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
