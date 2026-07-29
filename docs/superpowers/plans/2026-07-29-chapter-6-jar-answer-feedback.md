# Chapter 6 Jar Answer Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ทำให้คำตอบผิดในหน้าค้นหาโหลกระพริบแดง 1 วินาทีก่อนสับคำตอบ และคำตอบถูกแสดงสีเขียว 1 วินาทีก่อนเปิดด้านในโหล

**Architecture:** คง scene และโครง UI เดิมไว้ แล้วรวมการควบคุมช่วง feedback ไว้ใน `chapter_6_right_jar_modal.gd` โดยล็อก input ตลอด 1 วินาที การตอบผิดใช้รอบสีแดง/ขาว 4 ช่วง ช่วงละ 0.25 วินาที ก่อนสับคำตอบ ส่วนการตอบถูกค้างสีเขียว 1 วินาทีแล้วจึงเรียกการเปิดผลลัพธ์เดิม

**Tech Stack:** Godot 4.7.1, GDScript, SceneTree runtime tests

## Global Constraints

- ปรับเฉพาะ feedback ของหน้าค้นหาโหลในห้องขวา Chapter 6
- ห้ามเปลี่ยนคำถาม ตำแหน่งโหล รหัสที่พบ หรือสถานะของโหลที่ค้นแล้ว
- ระหว่าง feedback 1 วินาที ผู้เล่นต้องเลือกคำตอบหรือปิด modal ไม่ได้
- โหลที่ค้นแล้วต้องเปิดดูด้านในทันทีโดยไม่ถามซ้ำ

---

### Task 1: Jar Answer Feedback Timing

**Files:**
- Modify: `tests/test_chapter_6_right_jar_modal_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6_right_jar_modal.gd`

**Interfaces:**
- Consumes: `open_jar(definition: Dictionary, already_searched: bool)`, `_on_choice_pressed(slot_index: int)`, signal `searched(jar_index: int)`
- Produces: `_show_wrong_feedback(slot_index: int)`, `_show_correct_feedback(slot_index: int)`, และค่าคงที่ `CORRECT`

- [ ] **Step 1: Write the failing runtime assertions for wrong-answer blinking**

แก้ช่วงทดสอบคำตอบผิดใน `tests/test_chapter_6_right_jar_modal_runtime.gd` ให้เก็บปุ่มที่มีข้อความ `บ้าน – เรือน` แล้วตรวจลำดับสีจริง:

```gdscript
var wrong_button := _find_choice(modal, "บ้าน – เรือน")
wrong_button.pressed.emit()
if wrong_button.self_modulate != Color("#e33a35"):
	_fail("Wrong jar answer did not begin with red feedback")
	return
for button: Button in _choice_buttons(modal):
	if button != wrong_button and button.self_modulate != Color.WHITE:
		_fail("Wrong jar feedback colored an unselected choice")
		return
await create_timer(0.3, true).timeout
if wrong_button.self_modulate != Color.WHITE:
	_fail("Wrong jar answer did not blink back to neutral")
	return
await create_timer(0.3, true).timeout
if wrong_button.self_modulate != Color("#e33a35"):
	_fail("Wrong jar answer did not blink red a second time")
	return
await create_timer(0.55, true).timeout
if bool(modal.get("_feedback_locked")):
	_fail("Jar feedback stayed locked after one second")
	return
if _choices_equal(modal, AUTHORED_CHOICES):
	_fail("Wrong jar answer did not shuffle choices after blinking")
	return
```

เพิ่ม helper ที่คืนปุ่มจริงจากข้อความ:

```gdscript
func _choice_buttons(modal: Node) -> Array:
	return modal.get_node("Dim/QuestionPanel/Margin/VBox/Choices").get_children()


func _find_choice(modal: Node, text: String) -> Button:
	for button: Button in _choice_buttons(modal):
		if button.text == text:
			return button
	return null
```

- [ ] **Step 2: Write the failing runtime assertions for correct-answer delay**

แทนการกดคำตอบถูกแล้วตรวจทันทีด้วยการตรวจสีเขียวและการหน่วงเปิดโหล:

```gdscript
var correct_button := _find_choice(modal, "การ – กาล")
correct_button.pressed.emit()
if correct_button.self_modulate != Color("#36c75b"):
	_fail("Correct jar answer did not show green feedback")
	return
if not bool(modal.get("_feedback_locked")):
	_fail("Correct jar feedback did not lock input")
	return
if int(state.searched) != 0 or not modal.get_node("Dim/QuestionPanel").visible:
	_fail("Correct jar answer revealed the contents before one second")
	return
await create_timer(0.5, true).timeout
if correct_button.self_modulate != Color("#36c75b"):
	_fail("Correct jar feedback did not stay green for one second")
	return
await create_timer(0.6, true).timeout
if int(state.searched) != 1 or int(state.index) != 0:
	_fail("Correct jar answer did not emit searched(0) after feedback")
	return
if modal.get_node("Dim/QuestionPanel").visible:
	_fail("Correct jar answer did not reveal its contents after feedback")
	return
```

- [ ] **Step 3: Run the focused test and verify RED**

Run:

```bash
sh tests/test_chapter_6_right_jar_modal_runtime.sh
```

Expected: FAIL ที่ข้อความ `Wrong jar answer did not blink back to neutral` เพราะโค้ดเดิมแสดงสีแดงค้างตลอด 1 วินาที

- [ ] **Step 4: Implement blinking wrong feedback**

ใน `scenes/chapter_6/chapter_6_right_jar_modal.gd` เปลี่ยน `_show_wrong_feedback` ให้สลับสี 4 ช่วงก่อนสับคำตอบ:

```gdscript
func _show_wrong_feedback(slot_index: int) -> void:
	_feedback_locked = true
	_set_controls_disabled(true)
	var selected_button := _choice_buttons[slot_index]
	for blink_index: int in range(4):
		selected_button.self_modulate = WRONG if blink_index % 2 == 0 else Color.WHITE
		await get_tree().create_timer(0.25, true).timeout
		if not is_instance_valid(self):
			return
	selected_button.self_modulate = Color.WHITE
	_shuffle_to_changed_order()
	_render_choices()
	_feedback_locked = false
	_set_controls_disabled(false)
```

- [ ] **Step 5: Implement delayed correct feedback**

เพิ่มสีเขียวและส่งคำตอบถูกไปยัง coroutine ใหม่:

```gdscript
const WRONG := Color("#e33a35")
const CORRECT := Color("#36c75b")
```

```gdscript
func _on_choice_pressed(slot_index: int) -> void:
	if _feedback_locked or _result_revealed:
		return
	var original_index := int(_choice_buttons[slot_index].get_meta("original_index", -1))
	if original_index == int(_definition.get("correct_index", -2)):
		_show_correct_feedback(slot_index)
		return
	_show_wrong_feedback(slot_index)
```

```gdscript
func _show_correct_feedback(slot_index: int) -> void:
	_feedback_locked = true
	_set_controls_disabled(true)
	var selected_button := _choice_buttons[slot_index]
	selected_button.self_modulate = CORRECT
	await get_tree().create_timer(1.0, true).timeout
	if not is_instance_valid(self):
		return
	selected_button.self_modulate = Color.WHITE
	_reveal_result()
	_feedback_locked = false
	_set_controls_disabled(false)
```

- [ ] **Step 6: Run the focused runtime tests and verify GREEN**

Run:

```bash
sh tests/test_chapter_6_right_jar_modal_runtime.sh
sh tests/test_chapter_6_right_room_flow_runtime.sh
```

Expected:

```text
Chapter 6 right jar modal runtime passed
Chapter 6 right-room jar flow runtime passed
```

- [ ] **Step 7: Run full regression verification**

Run every shell test:

```bash
passed=0
for test_script in tests/*.sh; do
  sh "$test_script" || exit 1
  passed=$((passed + 1))
done
printf "ALL_TEST_SCRIPTS_PASSED=%s\n" "$passed"
```

Expected: `ALL_TEST_SCRIPTS_PASSED=30`

Run Godot editor parse:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
```

Expected: exit code `0`; macOS sandbox อาจแสดงคำเตือน CA certificate หรือไม่สามารถบันทึก editor settings ซึ่งไม่ใช่ parse failure

Run formatting validation:

```bash
git diff --check
```

Expected: exit code `0` และไม่มี output

- [ ] **Step 8: Commit the implementation**

```bash
git add tests/test_chapter_6_right_jar_modal_runtime.gd scenes/chapter_6/chapter_6_right_jar_modal.gd
git commit -m "feat: animate chapter 6 jar answer feedback"
```
