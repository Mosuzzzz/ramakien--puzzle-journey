extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var quest := (load("res://scenes/ui/quest_log.tscn") as PackedScene).instantiate()
	root.add_child(quest)
	await process_frame
	var button := quest.get_node("QuestButton") as TextureButton
	var notice := quest.get_node_or_null("QuestNotification") as TextureRect
	quest.set_quest("เควสแรก", "รายละเอียดแรก")
	_expect(quest.has_unread_notification(), "new quest notifies")
	_expect(notice == null or not notice.visible, "quest arrow stays absent for unread quest")
	await create_timer(0.55).timeout
	_expect(
		button.scale != Vector2.ONE or button.modulate != Color.WHITE,
		"unread quest animates button attention"
	)
	button.pressed.emit()
	_expect(not quest.has_unread_notification(), "press acknowledges")
	_expect(button.scale == Vector2.ONE, "acknowledge restores button scale")
	_expect(button.modulate == Color.WHITE, "acknowledge restores button color")
	quest.set_quest("เควสแรก", "รายละเอียดแรก")
	_expect(not quest.has_unread_notification(), "identical refresh stays read")
	quest.set_quest("เควสแรก", "รายละเอียดใหม่")
	_expect(quest.has_unread_notification(), "detail change notifies")
	button.pressed.emit()
	quest.set_completed(true)
	_expect(quest.has_unread_notification(), "completion change notifies")
	button.pressed.emit()
	quest.set_completed(true)
	_expect(not quest.has_unread_notification(), "same completion stays read")
	quest.set_quest("เควสซ่อน HUD", "ยังไม่ได้อ่าน")
	quest.set_hud_visible(false)
	_expect(quest.has_unread_notification(), "hidden HUD preserves unread")
	quest.set_hud_visible(true)
	_expect(quest.has_unread_notification(), "restored HUD preserves unread")
	quest.clear()
	_expect(not quest.has_unread_notification(), "clear removes unread")
	quest.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("PASS: quest notifications runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
