# Chapter 6 Code Digit Shuffle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** สุ่มตำแหน่งปุ่ม `2`, `7`, `3` เมื่อเปิดหน้าป้อนรหัส โดยไม่แสดงลำดับเฉลยและยังรับค่าตามตัวเลขที่ผู้เล่นกด

**Architecture:** เพิ่ม `_source_order` เป็นลำดับข้อมูลของปุ่มใน modal และสุ่มเพียงครั้งเดียวใน `open()` การ render จะผูกทั้งข้อความ สถานะค้นพบ และ metadata ของตัวเลขเข้ากับปุ่มแต่ละตำแหน่ง จากนั้น callback อ่านค่าจากปุ่มตำแหน่งนั้นแทนการ bind ตัวเลขตายตัวใน `_ready()`

**Tech Stack:** Godot 4.7.1, GDScript, SceneTree runtime tests

## Global Constraints

- ลำดับปุ่มเมื่อค้นพบครบต้องไม่เป็น `2, 7, 3`
- ลำดับปุ่มคงเดิมหลังล้างรหัสและหลังใส่รหัสผิดภายใน modal รอบเดียวกัน
- ตัวเลขที่ยังไม่ค้นพบแสดง `?` และกดไม่ได้
- เฉลยที่ถูกต้องยังเป็น `273`
- ห้ามเปลี่ยนคำถาม ตำแหน่งโหล รหัสที่พบ หรือ flow ชิ้นส่วนกุญแจ

---

### Task 1: Shuffle Digit Sources and Preserve Value Mapping

**Files:**
- Modify: `tests/test_chapter_6_right_code_modal_runtime.gd`
- Modify: `tests/test_chapter_6_right_room_flow_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6_right_code_modal.gd`

**Interfaces:**
- Consumes: `open(discovered_digits: Array[int])`, `_append_digit(digit: int)`, `SOURCE_DIGITS`, `SOLUTION`
- Produces: `_source_order: Array[int]`, `_shuffle_source_order()`, `_append_source_at(slot_index: int)`

- [ ] **Step 1: Write failing assertions for partially discovered shuffled sources**

แทน assertion ที่บังคับลำดับ `["2", "?", "?"]` ด้วยการตรวจค่าจากปุ่มจริง:

```gdscript
var source_texts := _button_texts(sources)
source_texts.sort()
if source_texts != ["2", "?", "?"]:
	_fail("Partially discovered sources lost a digit while shuffling")
	return
for button: Button in sources:
	var should_enable := button.text == "2"
	if button.disabled == should_enable:
		_fail("Shuffled source enabled state did not follow its displayed digit")
		return
```

- [ ] **Step 2: Write failing assertions for the full shuffled order**

หลัง `modal.open(all_digits)` ให้ตรวจว่าตัวเลขครบแต่ไม่เรียงเป็นเฉลย:

```gdscript
sources = _source_buttons(modal)
var shuffled_order := _button_texts(sources)
if shuffled_order == ["2", "7", "3"]:
	_fail("Code source buttons displayed the solution order")
	return
var sorted_digits := shuffled_order.duplicate()
sorted_digits.sort()
if sorted_digits != ["2", "3", "7"]:
	_fail("Shuffled code sources lost or duplicated a digit")
	return
```

เพิ่ม helper สำหรับกดปุ่มตามค่าที่แสดง:

```gdscript
func _press_digit(modal: Node, digit: int) -> void:
	for button: Button in _source_buttons(modal):
		if button.text == str(digit):
			button.pressed.emit()
			return
	_fail("Could not find code source digit: %d" % digit)
```

เปลี่ยนทุกจุดที่ใช้ `sources[index].pressed.emit()` ให้เรียก `_press_digit(modal, digit)` ตามรหัสที่ต้องการ และเพิ่ม assertion หลังตอบผิดกับหลังล้างรหัส:

```gdscript
if _button_texts(_source_buttons(modal)) != shuffled_order:
	_fail("Wrong code changed the shuffled source order")
	return
```

```gdscript
if _button_texts(_source_buttons(modal)) != shuffled_order:
	_fail("Clearing code changed the shuffled source order")
	return
```

- [ ] **Step 3: Run the focused test and verify RED**

Run:

```bash
sh tests/test_chapter_6_right_code_modal_runtime.sh
```

Expected: FAIL with `Code source buttons displayed the solution order` because the current modal always renders `2`, `7`, `3`.

- [ ] **Step 4: Add shuffled source state and slot-based callbacks**

ใน `scenes/chapter_6/chapter_6_right_code_modal.gd` เพิ่ม state:

```gdscript
var _source_order: Array[int] = SOURCE_DIGITS.duplicate()
```

เปลี่ยนการเชื่อมปุ่มใน `_ready()`:

```gdscript
for index: int in range(_source_buttons.size()):
	_source_buttons[index].pressed.connect(_append_source_at.bind(index))
```

เพิ่ม callback ที่อ่านค่าจาก metadata ของปุ่ม:

```gdscript
func _append_source_at(slot_index: int) -> void:
	var button := _source_buttons[slot_index]
	if _feedback_locked or not bool(button.get_meta("discovered", false)):
		return
	_append_digit(int(button.get_meta("digit", -1)))
```

- [ ] **Step 5: Shuffle once per modal opening**

ใน `open()` เรียก `_shuffle_source_order()` ก่อน `_render_sources()`:

```gdscript
_shuffle_source_order()
_render_sources(discovered_digits)
```

เพิ่มฟังก์ชันสุ่มที่รับประกันว่าไม่เรียงเหมือนเฉลย:

```gdscript
func _shuffle_source_order() -> void:
	_source_order = SOURCE_DIGITS.duplicate()
	_source_order.shuffle()
	if _source_order == SOLUTION:
		_source_order = [7, 3, 2]
```

เปลี่ยน `_render_sources()` ให้ใช้ลำดับที่สุ่มและบันทึกค่าบนปุ่ม:

```gdscript
func _render_sources(discovered_digits: Array[int]) -> void:
	for index: int in range(_source_buttons.size()):
		var digit := _source_order[index]
		var discovered := discovered_digits.has(digit)
		_source_buttons[index].text = str(digit) if discovered else "?"
		_source_buttons[index].disabled = not discovered
		_source_buttons[index].set_meta("digit", digit)
		_source_buttons[index].set_meta("discovered", discovered)
```

- [ ] **Step 6: Run focused runtime tests and verify GREEN**

ก่อนรันทดสอบ ให้เปลี่ยน `tests/test_chapter_6_right_room_flow_runtime.gd` ไม่ให้
คาดหวังลำดับหรือชื่อ node ตายตัว:

```gdscript
var exposed_digits := _button_texts(code_modal)
if exposed_digits == ["2", "7", "3"]:
	_cleanup_fail(room, "Pedestal exposed digits in solution order")
	return
var sorted_exposed_digits := exposed_digits.duplicate()
sorted_exposed_digits.sort()
if sorted_exposed_digits != ["2", "3", "7"]:
	_cleanup_fail(room, "Pedestal did not expose the three numbered jars")
	return
for digit: int in [2, 7, 3]:
	if not _press_code_digit(code_modal, digit):
		_cleanup_fail(room, "Could not find pedestal digit: %d" % digit)
		return
```

เพิ่ม helper ที่กดตามข้อความบนปุ่ม:

```gdscript
func _press_code_digit(code_modal: Node, digit: int) -> bool:
	for button: Button in code_modal.get_node(
		"Dim/EntryPanel/Margin/VBox/DigitSources"
	).get_children():
		if button.text == str(digit):
			button.pressed.emit()
			return true
	return false
```

Run:

```bash
sh tests/test_chapter_6_right_code_modal_runtime.sh
sh tests/test_chapter_6_right_room_flow_runtime.sh
```

Expected:

```text
Chapter 6 right code modal runtime passed
Chapter 6 right-room jar flow runtime passed
```

- [ ] **Step 7: Run full regression verification**

Run:

```bash
passed=0
for test_script in tests/*.sh; do
  sh "$test_script" || exit 1
  passed=$((passed + 1))
done
printf "ALL_TEST_SCRIPTS_PASSED=%s\n" "$passed"
```

Expected: `ALL_TEST_SCRIPTS_PASSED=30`

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
git diff --check
```

Expected: Godot exit code `0` and `git diff --check` produces no output. macOS sandbox may print non-fatal CA certificate or editor-settings warnings.

- [ ] **Step 8: Commit the implementation**

```bash
git add tests/test_chapter_6_right_code_modal_runtime.gd scenes/chapter_6/chapter_6_right_code_modal.gd
git commit -m "feat: shuffle chapter 6 code digit buttons"
```
