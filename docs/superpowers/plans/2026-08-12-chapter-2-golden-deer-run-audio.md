# Chapter 2 Golden Deer Run Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มเสียง `Deer.mp3` แบบวนและติดตามตำแหน่งกวางทอง โดยเล่นเฉพาะตอนแอนิเมชัน `run` ใน Chapter 2 ทั้งสองฉาก

**Architecture:** เก็บ asset เป็น `res://assets/audio/sfx/deer_run.mp3` และเพิ่ม `AudioStreamPlayer2D` ชื่อ `RunAudio` ภายใน packed scene `GoldenDeer` สคริปต์ `golden_deer.gd` sync สถานะเสียงจากชื่อแอนิเมชันใน `_play()` และหยุดเสียงในทุก lifecycle ที่กวางหยุด/ตาย/ออกจาก tree จึงไม่ต้องแก้ logic ซ้ำใน Chapter 2 รายฉาก

**Tech Stack:** Godot 4.7, GDScript, AudioStreamMP3, AudioStreamPlayer2D, headless runtime tests

## Global Constraints

- ใช้ไฟล์ต้นฉบับ `/Users/siwakornbundi/Downloads/Deer.mp3` และปลายทาง `assets/audio/sfx/deer_run.mp3`
- เสียงต้อง loop ตลอดช่วง `run` โดยไม่ restart ทุก physics frame
- เสียงต้องหยุดตอน `idle`, `_die()`, ถูกจับ, หนีสำเร็จ และ `_exit_tree()`
- `RunAudio` ต้องใช้ bus `SFX`, `max_distance = 900` px และเป็นเสียง 2D ที่ติดตามกวาง
- ต้องครอบคลุมทั้ง `chapter_2.tscn` และ `chapter_2_second.tscn` ผ่าน packed scene เดียวกัน
- ห้ามเปลี่ยน AI, ความเร็ว, animation, quiz, quest หรือ Cutscene flow
- รักษา working-tree changes ของงานกรอบบทพูดทั้ง 4 ไฟล์โดยไม่รวมใน commit เสียงกวาง

---

### Task 1: เพิ่ม RED runtime test สำหรับวงจรเสียงกวาง

**Files:**
- Create: `tests/test_golden_deer_run_audio_runtime.gd`
- Create: `tests/run_golden_deer_run_audio_tests.sh`

**Interfaces:**
- Consumes: `res://scenes/props/golden_deer.tscn`
- Verifies: child node `RunAudio`, existing `_play(anim: String)`, `_die()`, and tree-exit cleanup

- [ ] **Step 1: เขียน test ที่ mount GoldenDeer กับ Player จริง**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var player := Node2D.new()
	player.name = "Player"
	stage.add_child(player)
	var deer := (load("res://scenes/props/golden_deer.tscn") as PackedScene).instantiate()
	stage.add_child(deer)
	var run_audio := deer.get_node_or_null("RunAudio") as AudioStreamPlayer2D
	_expect(run_audio != null, "GoldenDeer owns positional run audio")
	if run_audio != null:
		_expect(run_audio.bus == &"SFX", "deer run audio uses SFX bus")
		_expect(is_equal_approx(run_audio.max_distance, 900.0), "deer audio has bounded range")
		_expect(run_audio.stream is AudioStreamMP3, "deer uses imported MP3 stream")
		_expect((run_audio.stream as AudioStreamMP3).loop, "deer run stream loops")
		deer.call("_play", "run")
		_expect(run_audio.playing, "run animation starts deer audio")
		var playback_position := run_audio.get_playback_position()
		deer.call("_play", "run")
		_expect(run_audio.get_playback_position() >= playback_position, "repeated run does not restart audio")
		deer.call("_play", "idle")
		_expect(not run_audio.playing, "idle animation stops deer audio")
	stage.free()
	_finish()
```

- [ ] **Step 2: เพิ่ม runner ตาม pattern ของโปรเจกต์**

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-golden-deer-run-audio-test.log \
  --path . --script res://tests/test_golden_deer_run_audio_runtime.gd
```

- [ ] **Step 3: รันทดสอบและยืนยัน RED**

Run:

```bash
bash tests/run_golden_deer_run_audio_tests.sh
```

Expected: exit code `1` เพราะ `GoldenDeer/RunAudio` ยังไม่มี

- [ ] **Step 4: Commit RED test โดย stage เฉพาะสองไฟล์ใหม่**

```bash
git add tests/test_golden_deer_run_audio_runtime.gd tests/run_golden_deer_run_audio_tests.sh
git commit -m "test: cover golden deer run audio lifecycle"
```

---

### Task 2: เพิ่ม asset และ RunAudio ใน packed scene

**Files:**
- Create: `assets/audio/sfx/deer_run.mp3`
- Modify: `scenes/props/golden_deer.tscn`
- Test: `tests/test_golden_deer_run_audio_runtime.gd`

**Interfaces:**
- Produces: `GoldenDeer/RunAudio: AudioStreamPlayer2D`
- Produces: looping `AudioStreamMP3` resource from `res://assets/audio/sfx/deer_run.mp3`

- [ ] **Step 1: คัดลอก asset เข้าสู่โปรเจกต์**

```bash
cp /Users/siwakornbundi/Downloads/Deer.mp3 assets/audio/sfx/deer_run.mp3
```

ยืนยัน checksum และขนาดไฟล์ต้นทาง/ปลายทางตรงกันด้วย `shasum -a 256`

- [ ] **Step 2: ให้ Godot import asset**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit \
  --log-file /tmp/ramakien-golden-deer-audio-import.log --path .
```

Expected: exit code `0` และ `load("res://assets/audio/sfx/deer_run.mp3")` คืน `AudioStreamMP3`

- [ ] **Step 3: เพิ่ม ext_resource กับ AudioStreamPlayer2D**

ใน `golden_deer.tscn` เพิ่ม resource ของ MP3 และ node:

```text
[node name="RunAudio" type="AudioStreamPlayer2D" parent="."]
stream = ExtResource("4_deer_run")
max_distance = 900.0
bus = &"SFX"
```

ไม่แก้ไฟล์ `.import` ที่ Godot สร้างอัตโนมัติ การเปิด loop จะทำใน `_ready()` ของ `golden_deer.gd` ตาม Task 3 โดย duplicate stream ก่อน เพื่อไม่ mutate imported resource ที่อาจถูกใช้ร่วม

- [ ] **Step 4: รัน test เพื่อยืนยันเหลือ failure เฉพาะ lifecycle**

Run runner เดิม Expected: RunAudio/stream/bus/range ผ่าน แต่ loop และ `_play("run")` ยังไม่ผ่านจนกว่า Task 3 จะกำหนด runtime stream

---

### Task 3: เชื่อมเสียงกับแอนิเมชันและ lifecycle

**Files:**
- Modify: `scenes/props/golden_deer.gd`
- Modify: `tests/test_golden_deer_run_audio_runtime.gd`

**Interfaces:**
- Produces: `_update_run_audio(running: bool) -> void`
- Preserves: `_play(anim: String) -> void`

- [ ] **Step 1: เพิ่ม lifecycle assertions สำหรับตายและออกจาก tree**

สร้างกวางใหม่สำหรับแต่ละ case เพื่อไม่ reuse node ที่ตายแล้ว:

```gdscript
deer.call("_play", "run")
deer.call("_die")
_expect(not run_audio.playing, "death stops deer run audio immediately")

deer.call("_play", "run")
deer.get_parent().remove_child(deer)
_expect(not run_audio.playing, "tree exit stops deer run audio")
```

- [ ] **Step 2: รันและยืนยัน RED จาก lifecycle ที่ยังไม่หยุด**

Run runner เดิม Expected: exit code `1` จาก run/death/tree-exit assertions

- [ ] **Step 3: เพิ่ม implementation ขั้นต่ำ**

```gdscript
@onready var _run_audio: AudioStreamPlayer2D = $RunAudio

func _ready() -> void:
	# existing health/player/idle setup remains unchanged
	var loop_stream := _run_audio.stream.duplicate() as AudioStreamMP3
	loop_stream.loop = true
	_run_audio.stream = loop_stream

func _play(anim: String) -> void:
	# existing animation code remains unchanged
	_update_run_audio(anim == "run")

func _update_run_audio(running: bool) -> void:
	if running:
		if not _run_audio.playing:
			_run_audio.play()
	else:
		_run_audio.stop()

func _exit_tree() -> void:
	if is_instance_valid(_run_audio):
		_run_audio.stop()
```

เรียก `_update_run_audio(false)` ที่ต้น `_die()` ก่อน hide/disable physics

- [ ] **Step 4: รันทดสอบจน GREEN**

```bash
bash tests/run_golden_deer_run_audio_tests.sh
```

Expected: exit code `0` และไม่มีเสียง restart เมื่อ `_play("run")` ถูกเรียกซ้ำ

- [ ] **Step 5: Commit implementation โดยไม่ stage งาน UI ค้าง**

```bash
git add assets/audio/sfx/deer_run.mp3 scenes/props/golden_deer.tscn scenes/props/golden_deer.gd tests/test_golden_deer_run_audio_runtime.gd
git commit -m "feat: add golden deer run audio"
```

---

### Task 4: ตรวจ integration Chapter 2 และ regression

**Files:**
- Modify if needed: `tests/test_golden_deer_run_audio_runtime.gd`
- Test: `scenes/chapter_2/chapter_2.tscn`
- Test: `scenes/chapter_2/chapter_2_second.tscn`

**Interfaces:**
- Verifies: both Chapter 2 scenes inherit the same RunAudio behavior

- [ ] **Step 1: เพิ่ม scene-integration assertions**

โหลดทั้งสอง Chapter 2 scenes แล้วตรวจ `YSortRoot/GoldenDeer/RunAudio`, stream loop, bus `SFX` และเรียก `_play("run")` กับกวางแต่ละ instance เพื่อยืนยันเสียงเริ่ม

- [ ] **Step 2: รัน golden-deer test และ world movement audio regression**

```bash
bash tests/run_golden_deer_run_audio_tests.sh
bash tests/run_world_movement_audio_tests.sh
```

Expected: ทั้งสอง runner exit code `0`; เสียงกวางไม่เปลี่ยน RunLoop/MonsterRunLoop กลาง

- [ ] **Step 3: โหลดโปรเจกต์และ Chapter 2 scenes แบบ headless**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit \
  --log-file /tmp/ramakien-golden-deer-final.log --path .
```

Expected: exit code `0`, ไม่มี missing resource หรือ parse error

- [ ] **Step 4: ตรวจไฟล์และ diff**

```bash
shasum -a 256 /Users/siwakornbundi/Downloads/Deer.mp3 assets/audio/sfx/deer_run.mp3
git diff --check
git status --short
```

Expected: checksums ตรงกัน, ไม่มี whitespace error และไฟล์ UI ค้างจากงานก่อนยังไม่ถูก stage/commit รวมกับงานเสียง

- [ ] **Step 5: Commit integration test หากมีการแก้หลัง Task 3**

```bash
git add tests/test_golden_deer_run_audio_runtime.gd
git commit -m "test: verify deer audio in chapter 2 scenes"
```
