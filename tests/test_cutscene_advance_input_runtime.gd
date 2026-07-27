extends SceneTree

const HELPER_PATH := "res://scenes/ui/cutscene_advance_input.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var helper_script := load(HELPER_PATH) as GDScript
	if helper_script == null:
		_fail("ไม่สามารถโหลดตัวช่วยอินพุตคัตซีนได้")
		return

	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.pressed = true
	if not helper_script.call("is_advance_event", left_click, null):
		_fail("คลิกซ้ายต้องดำเนินบทพูด")
		return

	var skip_button := Button.new()
	if helper_script.call("is_advance_event", left_click, skip_button):
		skip_button.free()
		_fail("คลิกบนปุ่ม UI ต้องไม่ดำเนินบทพูดซ้ำ")
		return
	skip_button.free()

	var e_key := InputEventKey.new()
	e_key.keycode = KEY_E
	e_key.pressed = true
	if not helper_script.call("is_advance_event", e_key, null):
		_fail("ปุ่ม E ต้องดำเนินบทพูด")
		return

	var key_echo := InputEventKey.new()
	key_echo.keycode = KEY_E
	key_echo.pressed = true
	key_echo.echo = true
	if helper_script.call("is_advance_event", key_echo, null):
		_fail("ปุ่ม E ที่เป็น echo ต้องไม่ดำเนินบทพูด")
		return

	var motion := InputEventMouseMotion.new()
	if helper_script.call("is_advance_event", motion, null):
		_fail("การขยับเมาส์ต้องไม่ดำเนินบทพูด")
		return

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	if helper_script.call("is_advance_event", right_click, null):
		_fail("คลิกขวาต้องไม่ดำเนินบทพูด")
		return

	var released_click := InputEventMouseButton.new()
	released_click.button_index = MOUSE_BUTTON_LEFT
	released_click.pressed = false
	if helper_script.call("is_advance_event", released_click, null):
		_fail("การปล่อยคลิกซ้ายต้องไม่ดำเนินบทพูด")
		return

	print("PASS: ตัวช่วยอินพุตคัตซีนจำแนก E คลิกซ้าย และปุ่ม UI ได้ถูกต้อง")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
