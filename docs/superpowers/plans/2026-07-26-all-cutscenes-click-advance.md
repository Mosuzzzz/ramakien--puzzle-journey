# All Cutscenes Click Advance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ทำให้คัตซีนที่มีอยู่ใน Chapter 2–9 ใช้คลิกซ้ายเพื่อดำเนินบทพูดได้เหมือน Chapter 1

**Architecture:** เพิ่มตัวช่วยกลางที่จำแนกอินพุต `E`, คลิกซ้าย และคลิกบนปุ่ม UI จากนั้นให้สคริปต์คัตซีนทุกตัวเรียกตัวช่วยเดียวกัน แต่ยังคงเก็บลำดับบทพูด การเฟด และการจบฉากไว้ในสคริปต์เดิม

**Tech Stack:** Godot 4.7.1, GDScript, headless runtime tests

## Global Constraints

- คลิกซ้ายหนึ่งครั้งและปุ่ม `E` ต้องดำเนินบทพูดหนึ่งขั้นเท่ากัน
- คลิกปุ่ม UI เช่น “ข้าม” ต้องไม่ดำเนินบทพูดซ้ำ
- อินพุตระหว่างเฟดหรือหลังจบคัตซีนต้องไม่มีผล
- ไม่เปลี่ยนข้อความ รูปภาพ ลำดับเรื่อง เงื่อนไขเริ่มคัตซีน หรือผลลัพธ์หลังคัตซีน
- ไม่ใช้คำสั่ง Git ไม่ commit และไม่ push

---

### Task 1: ตัวจำแนกอินพุตคัตซีน

**Files:**
- Create: `scenes/ui/cutscene_advance_input.gd`
- Create: `tests/test_cutscene_advance_input_runtime.gd`

**Interfaces:**
- Produces: `CutsceneAdvanceInput.is_advance_event(event: InputEvent, hovered_control: Control) -> bool`

- [ ] **Step 1: เขียนการทดสอบที่ยังไม่ผ่าน**

สร้างเหตุการณ์จริงสี่แบบและตรวจผลแบบ literal:

```gdscript
var left_click := InputEventMouseButton.new()
left_click.button_index = MOUSE_BUTTON_LEFT
left_click.pressed = true
assert(CutsceneAdvanceInput.is_advance_event(left_click, null))

var skip_button := Button.new()
assert(not CutsceneAdvanceInput.is_advance_event(left_click, skip_button))

var e_key := InputEventKey.new()
e_key.keycode = KEY_E
e_key.pressed = true
assert(CutsceneAdvanceInput.is_advance_event(e_key, null))

var motion := InputEventMouseMotion.new()
assert(not CutsceneAdvanceInput.is_advance_event(motion, null))
```

- [ ] **Step 2: รันทดสอบและยืนยันว่า fail เพราะยังไม่มีตัวช่วย**

Run:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_cutscene_advance_input_runtime.gd
```

Expected: exit code `1` เพราะโหลด `res://scenes/ui/cutscene_advance_input.gd` ไม่ได้

- [ ] **Step 3: เพิ่ม implementation ขั้นต่ำ**

```gdscript
extends Object

static func is_advance_event(event: InputEvent, hovered_control: Control) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == KEY_E
	if event is InputEventMouseButton:
		return (
			event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT
			and not hovered_control is Button
		)
	return false
```

- [ ] **Step 4: รันทดสอบและยืนยันว่า pass**

รันคำสั่งเดิมและคาดหวัง exit code `0`

---

### Task 2: เชื่อมตัวช่วยเข้ากับคัตซีนทุกตัว

**Files:**
- Modify: `scenes/cutscene/chapter_2_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_deer_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_abduction_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_post_battle_cutscene.gd`
- Modify: `scenes/cutscene/chapter_4_cutscene.gd`
- Modify: `scenes/cutscene/chapter_5_post_boss_cutscene.gd`
- Modify: `scenes/cutscene/chapter_6_cutscene.gd`
- Modify: `scenes/cutscene/chapter_8_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_ending_cutscene.gd`
- Create: `tests/test_cutscene_click_advance_runtime.gd`

**Interfaces:**
- Consumes: `CutsceneAdvanceInput.is_advance_event(event: InputEvent, hovered_control: Control) -> bool`
- Preserves: `_advance_dialogue()`, `_transitioning`, `_finished` และ `_active` ของแต่ละคัตซีน

- [ ] **Step 1: เขียน integration test ที่ยังไม่ผ่าน**

โหลด Chapter 6 ซึ่งเป็นคัตซีนหลายบรรทัด รอให้ intro transition จบ ส่ง `InputEventMouseButton` คลิกซ้ายเข้า `_input()` และตรวจว่า `_dialogue_index` เปลี่ยนจาก `0` เป็น `1` หลัง animation จบ จากนั้นวาง `Button` ใต้เมาส์ใน viewport และตรวจว่าคลิกปุ่มไม่เปลี่ยน index

- [ ] **Step 2: รันทดสอบและยืนยันว่า fail ตรงการคลิกซ้าย**

Run:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_cutscene_click_advance_runtime.gd
```

Expected: exit code `1` พร้อมข้อความว่าคลิกซ้ายไม่เปลี่ยน `_dialogue_index`

- [ ] **Step 3: แก้ `_input()` ในทุกสคริปต์**

เพิ่ม preload:

```gdscript
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")
```

ใช้รูปแบบเดียวกัน โดยคง guard เฉพาะของแต่ละคัตซีน:

```gdscript
func _input(event: InputEvent) -> void:
	var hovered_control := get_viewport().gui_get_hovered_control()
	if event is InputEventMouse and not CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		return
	get_viewport().set_input_as_handled()
	if _transitioning or _finished:
		return
	if CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		_advance_dialogue()
```

สำหรับ `chapter_9_ending_cutscene.gd` ต้องเก็บ guard `not _active` ไว้ก่อนประมวลผลอินพุต

- [ ] **Step 4: รัน unit และ integration tests**

รัน:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_cutscene_advance_input_runtime.gd
```

และ:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_cutscene_click_advance_runtime.gd
```

Expected: ทั้งสองคำสั่ง exit code `0`

---

### Task 3: ตรวจ regression ของ Chapter เดิม

**Files:**
- Test: `tests/test_chapter_2_post_abduction.sh`
- Test: `tests/test_chapter_3_patrol_flow_runtime.gd`
- Test: `tests/test_chapter_4_hanuman_after_cutscene.sh`
- Test: `tests/test_chapter_5_post_boss_cutscene.sh`
- Test: `tests/test_chapter_6_opening_cutscene.sh`
- Test: `tests/test_chapter_8_opening_cutscene.sh`
- Test: `tests/test_chapter_9_opening_cutscene.sh`
- Test: `tests/test_chapter_9_ending_cutscene.sh`

- [ ] **Step 1: รันชุดทดสอบคัตซีนเดิมทั้งหมด**

รัน shell tests ตามรายชื่อ และรัน Chapter 3 patrol flow แบบ headless

- [ ] **Step 2: ตรวจผล**

ทุกคำสั่งต้อง exit code `0` และ flow การจบคัตซีน การเปลี่ยนตัวละคร เควส และ Ending ต้องไม่เปลี่ยน

- [ ] **Step 3: ตรวจทั้งโปรเจกต์โหลดได้**

Run:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit code `0` โดยไม่มี GDScript parse error
