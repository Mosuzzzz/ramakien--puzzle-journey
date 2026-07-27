# Chapter 3 Patrol Quest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มเควสกำจัดยักษ์ลาดตระเวน 2 ตัวหลังคัตซีนเปิด Chapter 3 พร้อมเครื่องหมายสองจุด ความคืบหน้า สีสำเร็จ คัตซีนต่อเนื่อง และเควสชี้ทางออก Chapter 4

**Architecture:** ขยาย Quest autoload ให้รองรับรายการ Node2D เป้าหมายและสร้าง marker จาก template เดิมแบบ runtime โดยรักษา API เป้าหมายเดี่ยวไว้ จากนั้นให้ `chapter_3.gd` เป็น state controller เชื่อม callback จากคัตซีนเปิด การตายของมอนสเตอร์ และคัตซีนสุดท้าย

**Tech Stack:** Godot 4.7, GDScript, Godot scene resources, POSIX shell contract tests

## Global Constraints

- แก้เฉพาะระบบเควสและลำดับเหตุการณ์ของ Chapter 3
- เครื่องหมายต้องแสดงเหนือ `Mob1` และ `Mob2` พร้อมกัน และติดตามตำแหน่งปัจจุบัน
- Quest Log แบบเป้าหมายเดียวของ Chapter อื่นต้องทำงานเหมือนเดิม
- ไม่ล็อกทางออก Chapter 4
- ไม่ทำคำสั่ง Git

---

### Task 1: Quest Log หลายเป้าหมายและสถานะสำเร็จ

**Files:**
- Create: `tests/test_chapter_3_patrol_quest.sh`
- Modify: `scenes/ui/quest_log.gd:3-65`

**Interfaces:**
- Consumes: `$QuestMarker` เป็น `Control` template, label ทั้งสามตัวใน Quest Log
- Produces: `set_targets(nodes: Array[Node2D]) -> void`, `clear_targets() -> void`, `set_completed(completed: bool) -> void`, `get_target_count() -> int`

- [ ] **Step 1: เขียน contract test ที่ล้มเหลว**

```sh
#!/bin/sh
set -eu

quest="scenes/ui/quest_log.gd"
chapter="scenes/chapter_3/chapter_3.gd"
opening="scenes/cutscene/chapter_3_cutscene.gd"
post_battle="scenes/cutscene/chapter_3_post_battle_cutscene.gd"

grep -Fq 'func set_targets(nodes: Array[Node2D]) -> void:' "$quest"
grep -Fq 'func clear_targets() -> void:' "$quest"
grep -Fq 'func set_completed(completed: bool) -> void:' "$quest"
grep -Fq 'func get_target_count() -> int:' "$quest"
grep -Fq '_marker.duplicate()' "$quest"
grep -Fq 'is_instance_valid(target)' "$quest"
grep -Fq 'Color("#67d56b")' "$quest"

grep -Fq 'func start_patrol_quest() -> void:' "$chapter"
grep -Fq 'Quest.set_targets(alive)' "$chapter"
grep -Fq 'กำจัดยักษ์ลาดตระเวนในป่าทั้งหมด %d/2' "$chapter"
grep -Fq 'Quest.set_completed(defeated_count == PATROL_TOTAL)' "$chapter"
grep -Fq 'Quest.set_quest(EXIT_QUEST_NAME, EXIT_QUEST_DETAIL, _chapter4_portal.global_position)' "$chapter"

grep -Fq 'chapter.has_method("start_patrol_quest")' "$opening"
grep -Fq 'chapter.call("start_patrol_quest")' "$opening"
grep -Fq 'chapter.has_method("finish_chapter_3_story")' "$post_battle"
grep -Fq 'chapter.call("finish_chapter_3_story")' "$post_battle"

echo "Chapter 3 patrol quest contract passed"
```

- [ ] **Step 2: รันทดสอบเพื่อยืนยันว่าเป็นสีแดง**

Run: `sh tests/test_chapter_3_patrol_quest.sh`

Expected: FAIL ที่ `func set_targets(nodes: Array[Node2D]) -> void:` เพราะ API ยังไม่มี

- [ ] **Step 3: เพิ่ม state และ API หลายเป้าหมายใน Quest Log**

เพิ่มตัวแปร:

```gdscript
const DEFAULT_TEXT_COLOR := Color.WHITE
const COMPLETED_TEXT_COLOR := Color("#67d56b")

var _target_nodes: Array[Node2D] = []
var _target_markers: Array[Control] = []
```

เพิ่มเมธอด:

```gdscript
func set_targets(nodes: Array[Node2D]) -> void:
	target_position = Vector2.INF
	clear_targets()
	for target: Node2D in nodes:
		if not is_instance_valid(target) or not target.is_inside_tree():
			continue
		var marker := _marker.duplicate() as Control
		add_child(marker)
		marker.show()
		_target_nodes.append(target)
		_target_markers.append(marker)


func clear_targets() -> void:
	for marker: Control in _target_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_target_nodes.clear()
	_target_markers.clear()


func set_completed(completed: bool) -> void:
	var color := COMPLETED_TEXT_COLOR if completed else DEFAULT_TEXT_COLOR
	_name_label.modulate = color
	_detail_name_label.modulate = color
	_detail_text_label.modulate = color


func get_target_count() -> int:
	return _target_nodes.size()
```

ปรับ `set_quest()` ให้เรียก `clear_targets()` และ `set_completed(false)` ก่อนตั้งเป้าหมายเดี่ยว ปรับ `clear()` ให้ล้าง target และคืนสีปกติ

- [ ] **Step 4: อัปเดต marker ทุกตัวและคัดเป้าหมายที่หมดอายุ**

แยก helper:

```gdscript
func _position_marker(marker: Control, world_position: Vector2) -> void:
	var vp := get_viewport()
	if vp.get_camera_2d() == null:
		marker.hide()
		return
	var screen_pos: Vector2 = vp.canvas_transform * world_position
	var screen_size := vp.get_visible_rect().size
	var margin := 40.0
	screen_pos.x = clampf(screen_pos.x, margin, screen_size.x - margin)
	screen_pos.y = clampf(screen_pos.y, margin, screen_size.y - margin)
	marker.position = screen_pos - marker.size * 0.5
	marker.show()
```

ให้ `_update_marker()` อัปเดต marker เดี่ยวแบบเดิม แล้ววน `_target_nodes` ย้อนหลัง หาก `not is_instance_valid(target)` หรือ `not target.is_inside_tree()` ให้ลบ marker/target index นั้น มิฉะนั้นเรียก `_position_marker(marker, target.global_position)`

- [ ] **Step 5: รัน contract test**

Run: `sh tests/test_chapter_3_patrol_quest.sh`

Expected: ยัง FAIL ที่ contract ของ Chapter 3 controller ซึ่ง Task 2 จะเติม

---

### Task 2: เชื่อมเควสกับ Chapter 3 และคัตซีน

**Files:**
- Modify: `scenes/chapter_3/chapter_3.gd:3-40`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd:102-107`
- Modify: `scenes/cutscene/chapter_3_post_battle_cutscene.gd:150-156`
- Test: `tests/test_chapter_3_patrol_quest.sh`

**Interfaces:**
- Consumes: `Quest.set_targets(Array[Node2D])`, `Quest.set_completed(bool)`, `Quest.set_quest(String, String, Vector2)`
- Produces: `start_patrol_quest() -> void`, `finish_chapter_3_story() -> void`

- [ ] **Step 1: เพิ่มค่าคงที่และ references ใน controller**

```gdscript
const PATROL_TOTAL := 2
const PATROL_QUEST_NAME := "กวาดล้างยักษ์ลาดตระเวน"
const EXIT_QUEST_NAME := "ตามรอยทศกัณฐ์"
const EXIT_QUEST_DETAIL := "เดินทางออกจากป่าเพื่อตามหานางสีดา"

var _patrol_quest_started := false

@onready var _chapter4_portal: Area2D = $YSortRoot/Chapter4Portal
```

- [ ] **Step 2: เพิ่ม helper สำหรับมอนสเตอร์ที่ยังอยู่และอัปเดตเควส**

```gdscript
func _alive_patrol_mobs() -> Array[Node2D]:
	var alive: Array[Node2D] = []
	for mob_name: String in ["Mob1", "Mob2"]:
		var mob := get_node_or_null("YSortRoot/%s" % mob_name) as Node2D
		if mob != null:
			alive.append(mob)
	return alive


func _update_patrol_quest() -> void:
	if not _patrol_quest_started:
		return
	var alive := _alive_patrol_mobs()
	var defeated_count := PATROL_TOTAL - alive.size()
	Quest.set_quest(
		PATROL_QUEST_NAME,
		"กำจัดยักษ์ลาดตระเวนในป่าทั้งหมด %d/2" % defeated_count
	)
	Quest.set_targets(alive)
	Quest.set_completed(defeated_count == PATROL_TOTAL)
```

- [ ] **Step 3: เริ่มเควสหลังคัตซีนแรกและอัปเดตเมื่อมอนถูกลบ**

```gdscript
func start_patrol_quest() -> void:
	if _patrol_quest_started:
		return
	_patrol_quest_started = true
	_update_patrol_quest()


func _on_mob_removed() -> void:
	call_deferred("_refresh_after_mob_removed")


func _refresh_after_mob_removed() -> void:
	_update_patrol_quest()
	_check_all_mobs_defeated()
```

คง guard `_post_battle_cutscene_started` เดิมเพื่อให้คัตซีนเล่นครั้งเดียว และตรวจว่ามอนทั้งสองหายแล้วก่อน `show_cutscene()`

- [ ] **Step 4: เพิ่มเควสทางออกหลังคัตซีนสุดท้าย**

```gdscript
func finish_chapter_3_story() -> void:
	reveal_hanuman_after_all_cutscenes()
	Quest.set_quest(EXIT_QUEST_NAME, EXIT_QUEST_DETAIL, _chapter4_portal.global_position)
```

เพิ่ม `_exit_tree()` ใน controller ให้เรียก `Quest.clear_targets()` เฉพาะเมื่อ Quest autoload ยังใช้งานได้

- [ ] **Step 5: เชื่อม callback จากคัตซีนเปิด**

ก่อน `queue_free()` ใน `chapter_3_cutscene.gd`:

```gdscript
var chapter := get_tree().current_scene
if chapter != null and chapter.has_method("start_patrol_quest"):
	chapter.call("start_patrol_quest")
```

- [ ] **Step 6: เชื่อม callback จากคัตซีนสุดท้าย**

แทน callback reveal เดิมใน `chapter_3_post_battle_cutscene.gd`:

```gdscript
var chapter := get_tree().current_scene
if chapter != null and chapter.has_method("finish_chapter_3_story"):
	chapter.call("finish_chapter_3_story")
```

- [ ] **Step 7: รัน contract test เพื่อยืนยันว่าเป็นสีเขียว**

Run: `sh tests/test_chapter_3_patrol_quest.sh`

Expected: PASS และแสดง `Chapter 3 patrol quest contract passed`

---

### Task 3: ตรวจ parser และ regression

**Files:**
- Verify: `scenes/ui/quest_log.gd`
- Verify: `scenes/chapter_3/chapter_3.gd`
- Verify: `scenes/cutscene/chapter_3_cutscene.gd`
- Verify: `scenes/cutscene/chapter_3_post_battle_cutscene.gd`
- Test: `tests/test_chapter_3_patrol_quest.sh`

**Interfaces:**
- Consumes: implementation จาก Task 1 และ Task 2
- Produces: หลักฐานว่าไฟล์ parse ได้และ contract เดิมไม่เสีย

- [ ] **Step 1: รัน Godot headless เพื่อตรวจ project และ GDScript**

Run: `godot --headless --path . --editor --quit`

Expected: exit code 0 และไม่มี `SCRIPT ERROR` หรือ `Parse Error`

- [ ] **Step 2: รันชุด contract tests ทั้งหมด**

Run:

```sh
for test_file in tests/test_*.sh; do
	sh "$test_file"
done
```

Expected: ทุกไฟล์ exit code 0

- [ ] **Step 3: ตรวจ whitespace**

Run:

```sh
rg -n '[[:blank:]]+$' \
	scenes/ui/quest_log.gd \
	scenes/chapter_3/chapter_3.gd \
	scenes/cutscene/chapter_3_cutscene.gd \
	scenes/cutscene/chapter_3_post_battle_cutscene.gd \
	tests/test_chapter_3_patrol_quest.sh
```

Expected: ไม่มี output

- [ ] **Step 4: ตรวจรายการไฟล์ที่แก้ตามขอบเขตงาน**

ตรวจว่าไฟล์ implementation มีเฉพาะ:

```text
scenes/ui/quest_log.gd
scenes/chapter_3/chapter_3.gd
scenes/cutscene/chapter_3_cutscene.gd
scenes/cutscene/chapter_3_post_battle_cutscene.gd
tests/test_chapter_3_patrol_quest.sh
```

Expected: เนื้อหาใหม่มีเฉพาะระบบหลาย marker, progress Chapter 3 และ callback คัตซีนตามสเปก
