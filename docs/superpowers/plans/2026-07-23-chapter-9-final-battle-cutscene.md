# Chapter 9 Final Battle Opening Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มคัตซีน “ศึกสุดท้ายกับทศกัณฐ์” ที่แสดงทันทีเมื่อเข้า Chapter 9 และคืนการควบคุมพระรามเพื่อเริ่มการต่อสู้ในฉากเดิม

**Architecture:** ใช้ `CanvasLayer` แบบเต็มหน้าจอซ้อนใน `chapter_9.tscn` และสคริปต์ `Control` เฉพาะคัตซีนเป็นผู้หยุดเกม แสดงคำบรรยาย รับปุ่ม `E` และปลดหยุดเกมเมื่อจบ ภาพใช้ `TextureRect` แบบ cover และ UI ใช้รูปแบบเดียวกับ Chapter 8

**Tech Stack:** Godot 4.7, GDScript, Godot `.tscn`, POSIX shell contract test

## Global Constraints

- คัตซีนแสดงทันทีทุกครั้งที่ฉาก Chapter 9 ถูกเปิด
- เฟดหน้าจอมืด 1 วินาที และเฟดแสดงคัตซีน 1 วินาที
- กด `E` เพื่อดำเนินเรื่องต่อ และใช้ปุ่มข้ามร่วมกับ `CutsceneSkip`
- เมื่อจบให้ควบคุมพระรามและเริ่มต่อสู้กับทศกัณฐ์ใน Chapter 9 โดยไม่เปลี่ยนฉาก
- ห้ามแก้พลังชีวิตบอส ค่าความเสียหาย พอร์ทัล จุดเกิด และระบบต่อสู้เดิม
- ใช้ภาพ `assets/cutscene/chapter_9/ChatGPT Image 23 ก.ค. 2569 13_33_08.png`

---

### Task 1: Define the Chapter 9 opening cutscene contract

**Files:**
- Create: `tests/test_chapter_9_opening_cutscene.sh`

**Interfaces:**
- Consumes: `scenes/chapter_9/chapter_9.tscn`
- Produces: สัญญาทดสอบสำหรับภาพ UI คำบรรยาย transition การข้าม และการคงค่าบอส

- [ ] **Step 1: Write the failing contract test**

```sh
#!/bin/sh
set -eu

scene="scenes/chapter_9/chapter_9.tscn"
cutscene="scenes/cutscene/chapter_9_cutscene.gd"

test -f "$cutscene"
grep -Fq 'Chapter9CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_9_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 23 ก.ค. 2569 13_33_08.png' "$scene"
grep -Fq 'text = "ศึกสุดท้ายกับทศกัณฐ์"' "$scene"
grep -Fq 'parent="Chapter9CutsceneLayer/Chapter9Cutscene"' "$scene"
grep -Fq 'stretch_mode = 6' "$scene"

grep -Fq 'คำบรรยาย: หลังจากพระรามผ่านปริศนาภายในพระราชวังลงกาได้สำเร็จ' "$cutscene"
grep -Fq 'ทศกัณฐ์ประกาศว่าจะไม่มีวันยอมคืนสีดา' "$cutscene"
grep -Fq 'พระรามจึงเข้าประลองกับทศกัณฐ์ในการต่อสู้ครั้งสุดท้าย' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'event.keycode == KEY_E' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'กด E เพื่อเริ่มการต่อสู้ ▼' "$cutscene"
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Thotsakan" parent="YSortRoot"' "$scene"
grep -Fq 'max_health = 180' "$scene"
grep -Fq 'contact_damage = 20' "$scene"
grep -Fq '[node name="EndingPortal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter8Portal" parent="YSortRoot"' "$scene"

echo "Chapter 9 opening cutscene contract passed"
```

- [ ] **Step 2: Run the test and verify RED**

Run: `sh tests/test_chapter_9_opening_cutscene.sh`

Expected: FAIL at `test -f scenes/cutscene/chapter_9_cutscene.gd`.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/test_chapter_9_opening_cutscene.sh
git commit -m "test: define Chapter 9 opening cutscene"
```

### Task 2: Implement the Chapter 9 cutscene controller

**Files:**
- Create: `scenes/cutscene/chapter_9_cutscene.gd`

**Interfaces:**
- Consumes: `$CutsceneImage`, `$BackgroundDim`, `$TitleBanner`, `$Dialogue`, `$ContinuePrompt`, `$FadeOverlay`
- Produces: `_finish_cutscene() -> void` สำหรับ `CutsceneSkip.attach`

- [ ] **Step 1: Create the controller**

```gdscript
extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากพระรามผ่านปริศนาภายในพระราชวังลงกาได้สำเร็จ พระรามก็มาถึงท้องพระโรง ที่ซึ่งทศกัณฐ์กำลังรออยู่",
	"คำบรรยาย: ทศกัณฐ์ประกาศว่าจะไม่มีวันยอมคืนสีดา และเลือกตัดสินทุกอย่างด้วยการต่อสู้",
	"คำบรรยาย: พระรามจึงเข้าประลองกับทศกัณฐ์ในการต่อสู้ครั้งสุดท้าย เพื่อยุติสงครามและช่วยนางสีดากลับคืนมา",
]

var _dialogue_index := 0
var _transitioning := false
var _finished := false

@onready var _cutscene_image: TextureRect = $CutsceneImage
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	get_tree().paused = true
	_show_dialogue(0, false)
	CutsceneSkip.attach(self, _finish_cutscene)
	_play_intro_transition()


func _play_intro_transition() -> void:
	_transitioning = true
	var content: Array[CanvasItem] = [
		_cutscene_image,
		_background_dim,
		_title_banner,
		_dialogue_label,
		_prompt_label,
	]
	for item: CanvasItem in content:
		item.hide()
	_fade_overlay.color.a = 0.0
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	for item: CanvasItem in content:
		item.show()
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	if _transitioning or _finished:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_advance_dialogue()


func _advance_dialogue() -> void:
	if _dialogue_index + 1 >= DIALOGUES.size():
		_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	var is_final_line := _dialogue_index == DIALOGUES.size() - 1
	_prompt_label.text = "กด E เพื่อเริ่มการต่อสู้ ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.text = DIALOGUES[_dialogue_index]
		return
	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.text = DIALOGUES[_dialogue_index]
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	get_tree().paused = false
	var cutscene_layer := get_parent()
	if cutscene_layer is CanvasLayer:
		cutscene_layer.queue_free()
	else:
		queue_free()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
```

- [ ] **Step 2: Run the contract and confirm the expected partial failure**

Run: `sh tests/test_chapter_9_opening_cutscene.sh`

Expected: FAIL when searching for `Chapter9CutsceneLayer`.

### Task 3: Wire the full-screen UI into Chapter 9

**Files:**
- Modify: `scenes/chapter_9/chapter_9.tscn`

**Interfaces:**
- Consumes: Image UID `uid://bnumsic1w3gs2`, `chapter_9_cutscene.gd`, Sarabun fonts, title banner
- Produces: `Chapter9CutsceneLayer/Chapter9Cutscene` and controller child paths

- [ ] **Step 1: Add external resources**

```ini
[ext_resource type="Texture2D" uid="uid://bnumsic1w3gs2" path="res://assets/cutscene/chapter_9/ChatGPT Image 23 ก.ค. 2569 13_33_08.png" id="chapter_9_cutscene_image"]
[ext_resource type="Script" path="res://scenes/cutscene/chapter_9_cutscene.gd" id="chapter_9_cutscene_script"]
[ext_resource type="FontFile" uid="uid://c7je1jbvvhbpy" path="res://assets/fonts/Sarabun-Regular.ttf" id="chapter_9_cutscene_font"]
[ext_resource type="FontFile" uid="uid://qhf8k27eetcl" path="res://assets/fonts/Sarabun-Bold.ttf" id="chapter_9_cutscene_bold"]
[ext_resource type="Texture2D" uid="uid://bobkkl4uwe3n0" path="res://assets/ui/lable/pieces1/title_scroll_banner.png" id="chapter_9_title_banner"]
```

- [ ] **Step 2: Add the full-screen cutscene nodes**

เพิ่ม `Chapter9CutsceneLayer` และโหนดลูกตามรูปแบบ Chapter 8 โดยใช้ค่า:

```ini
[node name="Chapter9CutsceneLayer" type="CanvasLayer" parent="."]
layer = 100

[node name="Chapter9Cutscene" type="Control" parent="Chapter9CutsceneLayer"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("chapter_9_cutscene_script")

[node name="CutsceneImage" type="TextureRect" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("chapter_9_cutscene_image")
expand_mode = 1
stretch_mode = 6
```

เพิ่มโหนดที่เหลือด้วยค่าต่อไปนี้:

```ini
[node name="BackgroundDim" type="ColorRect" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0, 0, 0, 0.34)

[node name="TitleBanner" type="NinePatchRect" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.19
anchor_right = 0.81
offset_top = 36.0
offset_bottom = 132.0
grow_horizontal = 2
texture = ExtResource("chapter_9_title_banner")
patch_margin_left = 92
patch_margin_top = 16
patch_margin_right = 92
patch_margin_bottom = 16

[node name="Title" type="Label" parent="Chapter9CutsceneLayer/Chapter9Cutscene/TitleBanner"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 86.0
offset_right = -86.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.2, 0.12, 0.045, 1)
theme_override_fonts/font = ExtResource("chapter_9_cutscene_bold")
theme_override_font_sizes/font_size = 32
text = "ศึกสุดท้ายกับทศกัณฐ์"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Dialogue" type="Label" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.07
anchor_top = 0.62
anchor_right = 0.93
anchor_bottom = 0.8
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 1)
theme_override_colors/font_outline_color = Color(0, 0, 0, 0.95)
theme_override_constants/line_spacing = 6
theme_override_constants/shadow_offset_x = 3
theme_override_constants/shadow_offset_y = 3
theme_override_constants/outline_size = 4
theme_override_fonts/font = ExtResource("chapter_9_cutscene_font")
theme_override_font_sizes/font_size = 30
text = "คำบรรยาย: หลังจากพระรามผ่านปริศนาภายในพระราชวังลงกาได้สำเร็จ พระรามก็มาถึงท้องพระโรง ที่ซึ่งทศกัณฐ์กำลังรออยู่"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 2

[node name="ContinuePrompt" type="Label" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.3
anchor_top = 1.0
anchor_right = 0.7
anchor_bottom = 1.0
offset_top = -62.0
offset_bottom = -26.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(0.9, 0.87, 0.78, 0.95)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 1)
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
theme_override_constants/shadow_offset_x = 2
theme_override_constants/shadow_offset_y = 2
theme_override_constants/outline_size = 3
theme_override_fonts/font = ExtResource("chapter_9_cutscene_font")
theme_override_font_sizes/font_size = 19
text = "กด E เพื่อดำเนินเรื่องต่อ ▼"
horizontal_alignment = 1

[node name="FadeOverlay" type="ColorRect" parent="Chapter9CutsceneLayer/Chapter9Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0, 0, 0, 0)
```

- [ ] **Step 3: Run the contract test**

Run: `sh tests/test_chapter_9_opening_cutscene.sh`

Expected: `Chapter 9 opening cutscene contract passed`.

- [ ] **Step 4: Run regression tests**

Run:

```bash
sh tests/test_chapter_8_opening_cutscene.sh
sh tests/test_chapter_8_sida_room.sh
```

Expected: Both tests exit 0.

- [ ] **Step 5: Validate the scene with Godot**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene scenes/chapter_9/chapter_9.tscn --quit-after 3
```

Expected: exit code 0 with no parse error for Chapter 9 resources.

- [ ] **Step 6: Check and commit**

```bash
git diff --check
git add assets/cutscene/chapter_9 docs/superpowers/plans/2026-07-23-chapter-9-final-battle-cutscene.md scenes/chapter_9/chapter_9.tscn scenes/cutscene/chapter_9_cutscene.gd scenes/cutscene/chapter_9_cutscene.gd.uid
git commit -m "feat: add Chapter 9 final battle cutscene"
```
