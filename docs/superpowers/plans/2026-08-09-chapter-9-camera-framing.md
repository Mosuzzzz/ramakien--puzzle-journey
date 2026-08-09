# Chapter 9 Camera Framing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ทำให้กล้อง Chapter 9 เต็มพื้นที่เกม ไม่มีแถบสีเทา และยังติดตามผู้เล่นเหมือน Chapter อื่นในทุกอัตราส่วนหน้าจอ

**Architecture:** แยกสูตรคำนวณ cover zoom เป็น utility แบบ pure เพื่อทดสอบได้ แล้วให้ `chapter_9.gd` เรียกตั้งค่ากล้องหลังฉากพร้อมและทุกครั้งที่ viewport เปลี่ยนขนาด การแก้ไขจำกัดเฉพาะสคริปต์และไฟล์ทดสอบ จึงไม่เขียนทับตำแหน่งพร็อพหรือ Collision ในไฟล์ฉากที่ผู้ใช้แก้ไว้

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree regression tests

## Global Constraints

- Chapter 9 ต้องเต็มพื้นที่เกมโดยไม่มีขอบสีเทา
- กล้องยังติดตามผู้เล่นตามปกติและยอมให้ภาพแผนที่ถูกครอปเล็กน้อยตามอัตราส่วนหน้าจอ
- ไม่แก้ `scenes/chapter_9/chapter_9.tscn` หรือ `scenes/chapter_2/chapter_2.tscn`
- ไม่เปลี่ยนพฤติกรรมกล้องของ Chapter อื่น
- การคำนวณต้องทำซ้ำเมื่อ viewport เปลี่ยนขนาด

---

## File Structure

- Create `scenes/core/camera_framing.gd`: utility คำนวณ zoom แบบ cover และตรวจ input ที่มีขนาดศูนย์
- Create `tests/test_camera_framing_runtime.gd`: regression tests ของสูตรที่อัตราส่วน 16:9, 16:10, ultrawide และ input ไม่ถูกต้อง พร้อมตรวจ wiring ของ Chapter 9
- Create `tests/run_camera_framing_tests.sh`: runner สำหรับ Godot headless test
- Modify `scenes/chapter_9/chapter_9.gd`: ตั้ง limits/zoom หลัง scene ready และเมื่อ viewport เปลี่ยนขนาด

### Task 1: Cover Zoom Utility

**Files:**
- Create: `scenes/core/camera_framing.gd`
- Create: `tests/test_camera_framing_runtime.gd`
- Create: `tests/run_camera_framing_tests.sh`

**Interfaces:**
- Consumes: `viewport_size: Vector2`, `map_size: Vector2`, `base_zoom: float`, `margin: float`
- Produces: `CameraFraming.cover_zoom(viewport_size: Vector2, map_size: Vector2, base_zoom: float = 1.0, margin: float = 1.01) -> float`

- [ ] **Step 1: Write the failing utility tests**

Create `tests/test_camera_framing_runtime.gd` with assertions equivalent to:

```gdscript
extends SceneTree

const CameraFraming := preload("res://scenes/core/camera_framing.gd")

var _failures := 0

func _initialize() -> void:
	_check_cover(Vector2(1920, 1080), Vector2(1448, 1086), 1.3)
	_check_cover(Vector2(2048, 1280), Vector2(1448, 1086), 1.3)
	_check_cover(Vector2(2560, 1080), Vector2(1448, 1086), 1.3)
	_expect(CameraFraming.cover_zoom(Vector2.ZERO, Vector2(1448, 1086), 1.3) == 1.3, "zero viewport keeps base zoom")
	_expect(CameraFraming.cover_zoom(Vector2(1920, 1080), Vector2.ZERO, 1.3) == 1.3, "zero map keeps base zoom")
	_finish()

func _check_cover(viewport_size: Vector2, map_size: Vector2, base_zoom: float) -> void:
	var zoom := CameraFraming.cover_zoom(viewport_size, map_size, base_zoom)
	var visible_world_size := viewport_size / zoom
	_expect(visible_world_size.x <= map_size.x, "camera width stays inside map")
	_expect(visible_world_size.y <= map_size.y, "camera height stays inside map")
	_expect(zoom >= base_zoom, "camera does not zoom farther out than normal chapters")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _finish() -> void:
	if _failures == 0:
		print("PASS: camera framing runtime")
	quit(_failures)
```

Create `tests/run_camera_framing_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-camera-framing-test.log \
  --path . --script res://tests/test_camera_framing_runtime.gd
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `sh tests/run_camera_framing_tests.sh`

Expected: FAIL because `res://scenes/core/camera_framing.gd` does not exist.

- [ ] **Step 3: Implement the minimal utility**

Create `scenes/core/camera_framing.gd`:

```gdscript
class_name CameraFraming
extends RefCounted

static func cover_zoom(
	viewport_size: Vector2,
	map_size: Vector2,
	base_zoom: float = 1.0,
	margin: float = 1.01
) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return base_zoom
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return base_zoom
	var required_zoom := maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y)
	return maxf(base_zoom, required_zoom * maxf(margin, 1.0))
```

- [ ] **Step 4: Run the utility tests**

Run: `sh tests/run_camera_framing_tests.sh`

Expected: PASS with `PASS: camera framing runtime`.

- [ ] **Step 5: Commit the utility and tests**

```bash
git add scenes/core/camera_framing.gd tests/test_camera_framing_runtime.gd tests/run_camera_framing_tests.sh
git commit -m "test: define chapter 9 camera cover framing"
```

### Task 2: Chapter 9 Camera Lifecycle

**Files:**
- Modify: `scenes/chapter_9/chapter_9.gd`
- Modify: `tests/test_camera_framing_runtime.gd`

**Interfaces:**
- Consumes: `CameraFraming.cover_zoom(...)`, `Background: Sprite2D`, `YSortRoot/Player/Camera2D: Camera2D`, `Viewport.size_changed`
- Produces: `_configure_chapter_9_camera() -> void`, `_background_global_rect(background: Sprite2D) -> Rect2`

- [ ] **Step 1: Add failing lifecycle contract checks**

Extend `tests/test_camera_framing_runtime.gd` to load `res://scenes/chapter_9/chapter_9.gd` as text and assert that it contains all of these contracts:

```gdscript
_expect(source.contains("CameraFraming.cover_zoom"), "chapter 9 uses cover zoom")
_expect(source.contains("size_changed.connect"), "chapter 9 reacts to viewport resize")
_expect(source.contains("call_deferred(\"_configure_chapter_9_camera\")"), "chapter 9 waits until the scene is ready")
_expect(source.contains("camera.limit_bottom"), "chapter 9 applies map bounds")
```

- [ ] **Step 2: Run the test to verify lifecycle checks fail**

Run: `sh tests/run_camera_framing_tests.sh`

Expected: FAIL because Chapter 9 does not yet contain the camera lifecycle code.

- [ ] **Step 3: Wire Chapter 9 to the utility**

Modify `scenes/chapter_9/chapter_9.gd` by adding:

```gdscript
const CAMERA_BASE_ZOOM := 1.3
const CAMERA_COVER_MARGIN := 1.01

@onready var _background: Sprite2D = $Background
@onready var _player: CharacterBody2D = $YSortRoot/Player

func _ready() -> void:
	# Existing quest and boss setup remains unchanged.
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_configure_chapter_9_camera")

func _on_viewport_size_changed() -> void:
	call_deferred("_configure_chapter_9_camera")

func _configure_chapter_9_camera() -> void:
	if not is_instance_valid(_background) or _background.texture == null:
		return
	if not is_instance_valid(_player):
		return
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var map_rect := _background_global_rect(_background)
	if map_rect.size.x <= 0.0 or map_rect.size.y <= 0.0:
		return
	camera.limit_left = floori(map_rect.position.x)
	camera.limit_top = floori(map_rect.position.y)
	camera.limit_right = ceili(map_rect.end.x)
	camera.limit_bottom = ceili(map_rect.end.y)
	var zoom_value := CameraFraming.cover_zoom(
		get_viewport_rect().size,
		map_rect.size,
		CAMERA_BASE_ZOOM,
		CAMERA_COVER_MARGIN
	)
	camera.zoom = Vector2(zoom_value, zoom_value)
	camera.reset_smoothing()

func _background_global_rect(background: Sprite2D) -> Rect2:
	var rect := background.get_rect()
	var corners: Array[Vector2] = [
		background.to_global(rect.position),
		background.to_global(rect.position + Vector2(rect.size.x, 0.0)),
		background.to_global(rect.position + Vector2(0.0, rect.size.y)),
		background.to_global(rect.end),
	]
	var min_pos := corners[0]
	var max_pos := corners[0]
	for corner in corners:
		min_pos.x = minf(min_pos.x, corner.x)
		min_pos.y = minf(min_pos.y, corner.y)
		max_pos.x = maxf(max_pos.x, corner.x)
		max_pos.y = maxf(max_pos.y, corner.y)
	return Rect2(min_pos, max_pos - min_pos)
```

The actual edit must preserve all existing quest, boss music, Thotsakan, Sida, and ending cutscene behavior in `_ready()`.

- [ ] **Step 4: Run the focused camera test**

Run: `sh tests/run_camera_framing_tests.sh`

Expected: PASS with `PASS: camera framing runtime`.

- [ ] **Step 5: Run Chapter 9 regression tests**

Run: `sh tests/run_chapter_9_props_tests.sh`

Expected: PASS with `PASS: chapter 9 props runtime`.

- [ ] **Step 6: Commit the Chapter 9 lifecycle change**

```bash
git add scenes/chapter_9/chapter_9.gd tests/test_camera_framing_runtime.gd
git commit -m "fix: keep chapter 9 camera inside map"
```

### Task 3: Full Verification

**Files:**
- Verify only; no expected source changes

**Interfaces:**
- Consumes: all test runners under `tests/run_*_tests.sh`
- Produces: evidence that the new camera behavior does not regress existing chapters

- [ ] **Step 1: Run all existing headless test runners**

Run:

```bash
for test_runner in tests/run_*_tests.sh; do
  sh "$test_runner"
done
```

Expected: every runner exits 0 and prints its PASS message.

- [ ] **Step 2: Check GDScript parsing through Godot**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
```

Expected: exit code 0 with no new parser errors. Existing asset import or macOS certificate warnings may remain if they were already present before this change.

- [ ] **Step 3: Confirm user scene edits remain untouched**

Run: `git status --short`

Expected: the pre-existing user modifications to `scenes/chapter_2/chapter_2.tscn` and `scenes/chapter_9/chapter_9.tscn` remain unstaged and unchanged; no unexpected files are modified.
