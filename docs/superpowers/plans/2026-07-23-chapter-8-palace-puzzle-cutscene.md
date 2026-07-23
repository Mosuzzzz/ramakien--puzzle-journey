# Chapter 8 Palace Puzzle Opening Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มคัตซีน “ปริศนาแห่งพระราชวังลงกา” ที่แสดงทันทีเมื่อเข้า Chapter 8 และคืนการควบคุมพระรามในฉากเดิมเมื่อจบหรือกดข้าม

**Architecture:** ใช้ `CanvasLayer` แบบเต็มหน้าจอซ้อนใน `chapter_8.tscn` และสคริปต์ `Control` เฉพาะคัตซีนเป็นผู้หยุดเกม แสดงคำบรรยาย รับปุ่ม `E` และปลดหยุดเกมเมื่อจบ ภาพแนวตั้งใช้ `TextureRect` แบบ cover เพื่อเต็มหน้าจอโดยรักษาจุดสำคัญกลางภาพ

**Tech Stack:** Godot 4.7, GDScript, Godot `.tscn`, POSIX shell contract test

## Global Constraints

- คัตซีนแสดงทันทีทุกครั้งที่ฉาก Chapter 8 ถูกเปิด
- เฟดหน้าจอมืด 1 วินาที และเฟดแสดงคัตซีน 1 วินาที
- กด `E` เพื่อดำเนินเรื่องต่อ และใช้ปุ่มข้ามร่วมกับ `CutsceneSkip`
- เมื่อจบให้ควบคุมพระรามใน Chapter 8 ต่อโดยไม่เปลี่ยนฉาก
- ห้ามแก้ประตู ห้อง ศัตรู ปริศนา จุดเกิดผู้เล่น และเส้นทางเดิม
- ใช้ภาพ `assets/cutscene/chapter_8/ChatGPT Image 23 ก.ค. 2569 11_31_24.png`

---

### Task 1: Define the Chapter 8 opening cutscene contract

**Files:**
- Create: `tests/test_chapter_8_opening_cutscene.sh`

**Interfaces:**
- Consumes: โครงสร้าง `scenes/chapter_8/chapter_8.tscn` และรูปแบบสคริปต์คัตซีน Chapter 6
- Produces: สัญญาทดสอบสำหรับ resource, UI, เนื้อหา, transition, skip และการคงโหนด gameplay

- [ ] **Step 1: Write the failing contract test**

```sh
#!/bin/sh
set -eu

scene="scenes/chapter_8/chapter_8.tscn"
cutscene="scenes/cutscene/chapter_8_cutscene.gd"

test -f "$cutscene"
grep -Fq 'Chapter8CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_8_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 23 ก.ค. 2569 11_31_24.png' "$scene"
grep -Fq 'text = "ปริศนาแห่งพระราชวังลงกา"' "$scene"
grep -Fq 'parent="Chapter8CutsceneLayer/Chapter8Cutscene"' "$scene"
grep -Fq 'stretch_mode = 6' "$scene"

grep -Fq 'คำบรรยาย: หลังจากพระรามฝ่าแนวป้องกันของเหล่าทหารยักษ์' "$cutscene"
grep -Fq 'ประตูทุกบานเชื่อมต่อกันราวกับเขาวงกต' "$cutscene"
grep -Fq 'พระรามต้องไขปริศนาเพื่อเปิดประตูบานสุดท้าย' "$cutscene"
grep -Fq 'การเผชิญหน้าครั้งสุดท้ายก็ใกล้จะเริ่มต้น' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'event.keycode == KEY_E' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'กด E เพื่อเริ่ม Chapter 8 ▼' "$cutscene"
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter9Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter7Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Mob1" parent="YSortRoot"' "$scene"

echo "Chapter 8 opening cutscene contract passed"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/test_chapter_8_opening_cutscene.sh`

Expected: FAIL at `test -f scenes/cutscene/chapter_8_cutscene.gd`.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/test_chapter_8_opening_cutscene.sh
git commit -m "test: define Chapter 8 opening cutscene"
```

### Task 2: Implement the Chapter 8 opening cutscene controller

**Files:**
- Create: `scenes/cutscene/chapter_8_cutscene.gd`

**Interfaces:**
- Consumes: Child nodes `$CutsceneImage`, `$BackgroundDim`, `$TitleBanner`, `$Dialogue`, `$ContinuePrompt`, `$FadeOverlay`
- Produces: `_finish_cutscene() -> void`, callable by `CutsceneSkip.attach`

- [ ] **Step 1: Create the minimal controller**

```gdscript
extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากพระรามฝ่าแนวป้องกันของเหล่าทหารยักษ์ และบุกเข้าสู่พระราชวังลงกาได้สำเร็จ",
	"คำบรรยาย: กลับพบว่าทางเข้าสู่ท้องพระโรงทอดยาวผ่านหลายห้อง ประตูทุกบานเชื่อมต่อกันราวกับเขาวงกต",
	"คำบรรยาย: มีเพียงผู้มีสติปัญญาและความกล้าหาญเท่านั้นจึงจะผ่านไปได้ พระรามต้องไขปริศนาเพื่อเปิดประตูบานสุดท้าย",
	"คำบรรยาย: เบื้องหลังประตูนั้นคือท้องพระโรง ที่ซึ่งทศกัณฐ์กำลังรออยู่ เมื่อประตูเปิด การเผชิญหน้าครั้งสุดท้ายก็ใกล้จะเริ่มต้น",
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
	_prompt_label.text = "กด E เพื่อเริ่ม Chapter 8 ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
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

- [ ] **Step 2: Run the contract test and confirm the expected partial failure**

Run: `sh tests/test_chapter_8_opening_cutscene.sh`

Expected: FAIL when searching for `Chapter8CutsceneLayer` because the scene is not wired yet.

### Task 3: Wire the cutscene UI into Chapter 8

**Files:**
- Modify: `scenes/chapter_8/chapter_8.tscn`

**Interfaces:**
- Consumes: `chapter_8_cutscene.gd`, cutscene image UID `uid://l5hlblynhrek`, Sarabun fonts, title banner
- Produces: `Chapter8CutsceneLayer/Chapter8Cutscene` and its six controller child paths

- [ ] **Step 1: Add the cutscene external resources**

Append these resources after the existing external resources:

```ini
[ext_resource type="Texture2D" uid="uid://l5hlblynhrek" path="res://assets/cutscene/chapter_8/ChatGPT Image 23 ก.ค. 2569 11_31_24.png" id="chapter_8_cutscene_image"]
[ext_resource type="Script" path="res://scenes/cutscene/chapter_8_cutscene.gd" id="chapter_8_cutscene_script"]
[ext_resource type="FontFile" uid="uid://c7je1jbvvhbpy" path="res://assets/fonts/Sarabun-Regular.ttf" id="chapter_8_cutscene_font"]
[ext_resource type="FontFile" uid="uid://qhf8k27eetcl" path="res://assets/fonts/Sarabun-Bold.ttf" id="chapter_8_cutscene_bold"]
[ext_resource type="Texture2D" uid="uid://bobkkl4uwe3n0" path="res://assets/ui/lable/pieces1/title_scroll_banner.png" id="chapter_8_title_banner"]
```

- [ ] **Step 2: Add the full-screen UI without changing gameplay nodes**

Append these nodes after the existing Chapter 8 nodes:

```ini
[node name="Chapter8CutsceneLayer" type="CanvasLayer" parent="."]
layer = 100

[node name="Chapter8Cutscene" type="Control" parent="Chapter8CutsceneLayer"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("chapter_8_cutscene_script")

[node name="CutsceneImage" type="TextureRect" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("chapter_8_cutscene_image")
expand_mode = 1
stretch_mode = 6

[node name="BackgroundDim" type="ColorRect" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0, 0, 0, 0.34)

[node name="TitleBanner" type="NinePatchRect" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.19
anchor_right = 0.81
offset_top = 36.0
offset_bottom = 132.0
grow_horizontal = 2
texture = ExtResource("chapter_8_title_banner")
patch_margin_left = 92
patch_margin_top = 16
patch_margin_right = 92
patch_margin_bottom = 16

[node name="Title" type="Label" parent="Chapter8CutsceneLayer/Chapter8Cutscene/TitleBanner"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 86.0
offset_right = -86.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.2, 0.12, 0.045, 1)
theme_override_fonts/font = ExtResource("chapter_8_cutscene_bold")
theme_override_font_sizes/font_size = 32
text = "ปริศนาแห่งพระราชวังลงกา"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Dialogue" type="Label" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
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
theme_override_fonts/font = ExtResource("chapter_8_cutscene_font")
theme_override_font_sizes/font_size = 30
text = "คำบรรยาย: หลังจากพระรามฝ่าแนวป้องกันของเหล่าทหารยักษ์ และบุกเข้าสู่พระราชวังลงกาได้สำเร็จ"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 2

[node name="ContinuePrompt" type="Label" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
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
theme_override_fonts/font = ExtResource("chapter_8_cutscene_font")
theme_override_font_sizes/font_size = 19
text = "กด E เพื่อดำเนินเรื่องต่อ ▼"
horizontal_alignment = 1

[node name="FadeOverlay" type="ColorRect" parent="Chapter8CutsceneLayer/Chapter8Cutscene"]
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

Run: `sh tests/test_chapter_8_opening_cutscene.sh`

Expected: `Chapter 8 opening cutscene contract passed`.

- [ ] **Step 4: Run related regression tests**

Run:

```bash
sh tests/test_chapter_6_opening_cutscene.sh
sh tests/test_chapter_8_sida_room.sh
```

Expected:

```text
Chapter 6 opening cutscene contract passed
Chapter 8 Sida placement contract passed
```

- [ ] **Step 5: Validate Godot resources headlessly**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit code 0 with no parse error for `chapter_8.tscn` or `chapter_8_cutscene.gd`.

- [ ] **Step 6: Check the final diff and commit**

Run:

```bash
git diff --check
git diff -- scenes/chapter_8/chapter_8.tscn scenes/cutscene/chapter_8_cutscene.gd tests/test_chapter_8_opening_cutscene.sh
git add assets/cutscene/chapter_8 scenes/chapter_8/chapter_8.tscn scenes/cutscene/chapter_8_cutscene.gd tests/test_chapter_8_opening_cutscene.sh docs/superpowers/plans/2026-07-23-chapter-8-palace-puzzle-cutscene.md
git commit -m "feat: add Chapter 8 palace puzzle cutscene"
```
