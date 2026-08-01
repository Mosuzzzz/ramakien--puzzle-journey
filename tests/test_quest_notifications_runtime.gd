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
	_expect(notice != null, "quest notification exists")
	if notice == null:
		_finish()
		return
	_expect(not notice.visible, "notification starts hidden")
	quest.set_quest("เควสแรก", "รายละเอียดแรก")
	_expect(quest.has_unread_notification() and notice.visible, "new quest notifies")
	var start_y := notice.position.y
	await create_timer(0.55).timeout
	_expect(not is_equal_approx(notice.position.y, start_y), "notification bobs")
	button.pressed.emit()
	_expect(not quest.has_unread_notification() and not notice.visible, "press acknowledges")
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
	_expect(not notice.visible and quest.has_unread_notification(), "hidden HUD preserves unread")
	quest.set_hud_visible(true)
	_expect(notice.visible, "restored HUD restores notification")
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
