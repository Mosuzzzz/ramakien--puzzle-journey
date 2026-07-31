extends SceneTree

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	var inventory := root.get_node("Inv")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))
	var before: Dictionary = inventory.get_items_snapshot()
	inventory.add_item("potion")
	_expect(_events == [&"pickup"], "inventory addition plays pickup once")
	_events.clear()
	inventory.restore_items(before)
	_expect(_events.is_empty(), "restoring a save is silent")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: pickup audio hooks")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
