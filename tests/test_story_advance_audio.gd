extends SceneTree

const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	_expect(
		CutsceneAdvanceInput.consume_advance_event(key_event, null),
		"accepted E is consumed"
	)
	_expect(_events == [&"button_click"], "accepted E sounds once")

	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	_events.clear()
	_expect(
		CutsceneAdvanceInput.consume_advance_event(click_event, null),
		"accepted click is consumed"
	)
	_expect(_events == [&"button_click"], "accepted click sounds once")

	_events.clear()
	var button := Button.new()
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(click_event, button),
		"button-hover click belongs to the button"
	)
	_expect(_events.is_empty(), "button-hover click does not add story sound")
	button.free()

	_events.clear()
	var dialogue := root.get_node("Dialogue")
	var lines: Array[String] = ["บรรทัดสุดท้าย"]
	dialogue.start("", lines)
	dialogue._input(key_event)
	_expect(_events == [&"button_click"], "final dialogue close sounds once")
	_expect(not dialogue.is_active, "final dialogue input closes dialogue")

	_events.clear()
	key_event.echo = true
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(key_event, null),
		"repeated E is rejected"
	)
	_expect(_events.is_empty(), "repeated E stays silent")
	key_event.echo = false

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(right_click, null),
		"right click is rejected"
	)
	_expect(_events.is_empty(), "right click stays silent")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: story advance audio")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
