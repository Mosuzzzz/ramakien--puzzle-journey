# Chapter 9 Prop Layering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ทำให้พร็อพทั้ง 4 ชิ้นใน Chapter 9 แสดงเหนือพระรามและทศกัณฐ์เสมอเมื่อภาพซ้อนกัน

**Architecture:** เพิ่มฟังก์ชันกำหนดลำดับ CanvasItem ที่ทดสอบได้ใน `chapter_9.gd` แล้วเรียกเมื่อฉากพร้อม กลุ่ม `Chapter9Props` จะใช้ global z-index ที่สูงกว่า `YSortRoot` โดยไม่แก้โครงสร้างหรือตำแหน่งในไฟล์ฉาก

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree regression tests

## Global Constraints

- พร็อพ `FireTowerA`, `FireTowerB`, `DarkTowerA` และ `DarkTowerB` ต้องอยู่เหนือพระรามและทศกัณฐ์เสมอ
- ไม่แก้ `scenes/chapter_9/chapter_9.tscn` หรือ `scenes/chapter_2/chapter_2.tscn`
- ไม่กระทบ Background, Collision, UI, บอสบาร์, การต่อสู้ หรือระบบกล้อง

---

## File Structure

- Modify `scenes/chapter_9/chapter_9.gd`: กำหนด global z-index ของกลุ่มพร็อพเมื่อฉากพร้อม
- Modify `tests/test_camera_framing_runtime.gd`: ทดสอบพฤติกรรมเลเยอร์จริงและตรวจว่า Chapter 9 เรียกใช้งาน

### Task 1: Keep Chapter 9 Props Above Actors

**Files:**
- Modify: `scenes/chapter_9/chapter_9.gd`
- Test: `tests/test_camera_framing_runtime.gd`

**Interfaces:**
- Consumes: `props: CanvasItem`, `actors: CanvasItem`
- Produces: `configure_props_above_characters(props: CanvasItem, actors: CanvasItem) -> void`

- [ ] **Step 1: Write the failing layering test**

Add a preload and a behavior test to `tests/test_camera_framing_runtime.gd`:

```gdscript
const Chapter9Script := preload("res://scenes/chapter_9/chapter_9.gd")

func _check_chapter_9_prop_layering() -> void:
	var props := Node2D.new()
	var actors := Node2D.new()
	actors.z_index = 3
	Chapter9Script.configure_props_above_characters(props, actors)
	_expect(not props.z_as_relative, "chapter 9 props use a global drawing layer")
	_expect(props.z_index > actors.z_index, "chapter 9 props draw above actors")
	props.free()
	actors.free()
```

Call `_check_chapter_9_prop_layering()` from `_initialize()`. Extend the existing source contract check with:

```gdscript
_expect(
	source.contains("configure_props_above_characters(_chapter_9_props, _y_sort_root)"),
	"chapter 9 configures prop layering when ready"
)
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `sh tests/run_camera_framing_tests.sh`

Expected: FAIL because `configure_props_above_characters` does not exist.

- [ ] **Step 3: Implement the minimal layering behavior**

Add these node references to `scenes/chapter_9/chapter_9.gd`:

```gdscript
@onready var _chapter_9_props: Node2D = $Chapter9Props
@onready var _y_sort_root: Node2D = $YSortRoot
```

Call this at the beginning of `_ready()`:

```gdscript
configure_props_above_characters(_chapter_9_props, _y_sort_root)
```

Add the tested helper:

```gdscript
static func configure_props_above_characters(props: CanvasItem, actors: CanvasItem) -> void:
	if props == null or actors == null:
		return
	props.z_as_relative = false
	props.z_index = actors.z_index + 1
```

- [ ] **Step 4: Run focused Chapter 9 tests**

Run:

```bash
sh tests/run_camera_framing_tests.sh
sh tests/run_chapter_9_props_tests.sh
```

Expected: both commands exit 0 and print their PASS messages.

- [ ] **Step 5: Commit the implementation and test**

```bash
git add scenes/chapter_9/chapter_9.gd tests/test_camera_framing_runtime.gd
git commit -m "fix: draw chapter 9 props above actors"
```

### Task 2: Full Verification

**Files:**
- Verify only; no expected source changes

**Interfaces:**
- Consumes: all runners matching `tests/run_*_tests.sh`
- Produces: regression evidence for the final branch state

- [ ] **Step 1: Run every headless test runner**

Run:

```bash
set -e
for test_runner in tests/run_*_tests.sh; do
  sh "$test_runner"
done
```

Expected: every runner exits 0 and prints its PASS message.

- [ ] **Step 2: Parse the project with Godot**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
```

Expected: exit code 0 with no new parser errors. Existing macOS certificate, resource UID, editor setting, or missing Chapter 3 cutscene asset warnings may remain.

- [ ] **Step 3: Confirm user scene edits remain untouched**

Run: `git status --short`

Expected: only the pre-existing user modifications to `scenes/chapter_2/chapter_2.tscn` and `scenes/chapter_9/chapter_9.tscn` remain unstaged.
