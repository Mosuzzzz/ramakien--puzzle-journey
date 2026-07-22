# Chapter 6 Lanka Gate Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-screen opening cutscene to Chapter 6 that introduces the sealed gate of Lanka, locks gameplay during narration, and returns control to the existing Phra Ram player.

**Architecture:** Add a focused `Control` script and a high-layer `CanvasLayer` embedded in `chapter_6.tscn`, following the established Chapter 4 cutscene layout and shared skip helper. A shell contract test checks scene resources, narration, input locking, transition durations, and preservation of the existing player and portals.

**Tech Stack:** Godot 4.7 scene resources (`.tscn`), GDScript, POSIX shell contract test.

## Global Constraints

- Work on the current `CutSceneChapter6` branch without switching branches.
- Use `assets/cutscene/chapter_6/ChatGPT Image 22 ก.ค. 2569 20_29_33.png`.
- Display the title `ประตูกรุงลงกา` and the four approved Thai narration entries exactly.
- Play automatically every time Chapter 6 loads.
- Pause gameplay until the cutscene finishes or is skipped.
- Preserve the existing Phra Ram player, Chapter 5 portal, Chapter 7 portal, enemies, map, and spawn positions.
- Use one-second darken and one-second reveal transitions.

---

### Task 1: Chapter 6 Cutscene Contract Test

**Files:**
- Create: `tests/test_chapter_6_opening_cutscene.sh`
- Test: `tests/test_chapter_6_opening_cutscene.sh`

**Interfaces:**
- Consumes: `scenes/chapter_6/chapter_6.tscn` and `scenes/cutscene/chapter_6_cutscene.gd` as text resources.
- Produces: a repeatable static contract test with exit code `0` on success.

- [ ] **Step 1: Write the failing test**

```sh
#!/bin/sh
set -eu

scene="scenes/chapter_6/chapter_6.tscn"
cutscene="scenes/cutscene/chapter_6_cutscene.gd"

test -f "$cutscene"
grep -Fq 'Chapter6CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_6_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 22 ก.ค. 2569 20_29_33.png' "$scene"
grep -Fq 'text = "ประตูกรุงลงกา"' "$scene"
grep -Fq 'parent="Chapter6CutsceneLayer/Chapter6Cutscene"' "$scene"

grep -Fq 'คำบรรยาย: หลังจากหนุมานช่วยพระรามกลับมาจากไมยราพได้สำเร็จ' "$cutscene"
grep -Fq 'คำบรรยาย: เมื่อเดินทางมาถึง พบว่ากรุงลงกาถูกปกป้องด้วยกำแพงขนาดมหึมา' "$cutscene"
grep -Fq 'ประตูเมืองปิดสนิทด้วยอาคมโบราณ' "$cutscene"
grep -Fq 'พระรามจึงต้องออกค้นหากลไกโบราณ' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'event.keycode == KEY_E' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter7Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter5Portal" parent="YSortRoot"' "$scene"

echo "Chapter 6 opening cutscene contract passed"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/test_chapter_6_opening_cutscene.sh`

Expected: non-zero exit because `scenes/cutscene/chapter_6_cutscene.gd` does not exist.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/test_chapter_6_opening_cutscene.sh
git commit -m "test: define Chapter 6 opening cutscene contract"
```

---

### Task 2: Opening Cutscene Script and Scene Layer

**Files:**
- Create: `scenes/cutscene/chapter_6_cutscene.gd`
- Modify: `scenes/chapter_6/chapter_6.tscn`
- Test: `tests/test_chapter_6_opening_cutscene.sh`

**Interfaces:**
- Consumes: `CutsceneSkip.attach(host: Node, on_skip: Callable) -> Button`, the new Chapter 6 texture, Sarabun fonts, and the shared title banner.
- Produces: an auto-starting `Chapter6Cutscene` control whose `_finish_cutscene() -> void` unpauses gameplay and removes its canvas layer.

- [ ] **Step 1: Create the focused cutscene script**

```gdscript
extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากหนุมานช่วยพระรามกลับมาจากไมยราพได้สำเร็จ พระรามก็เดินทางต่อไปยังกรุงลงกาเพื่อช่วยนางสีดา",
	"คำบรรยาย: เมื่อเดินทางมาถึง พบว่ากรุงลงกาถูกปกป้องด้วยกำแพงขนาดมหึมา",
	"คำบรรยาย: ประตูเมืองปิดสนิทด้วยอาคมโบราณ ไม่มีผู้ใดสามารถทำลายหรือผลักประตูให้เปิดออกได้",
	"คำบรรยาย: พระรามจึงต้องออกค้นหากลไกโบราณ เพื่อปลดผนึกอาคมของประตูเมืองให้ได้",
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
	_prompt_label.text = "กด E เพื่อเริ่ม Chapter 6 ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
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

- [ ] **Step 2: Add scene resources and the full-screen node hierarchy**

Add these resources after the existing Chapter 6 resources:

```ini
[ext_resource type="Texture2D" uid="uid://1sgk7kg45wfd" path="res://assets/cutscene/chapter_6/ChatGPT Image 22 ก.ค. 2569 20_29_33.png" id="chapter_6_cutscene_image"]
[ext_resource type="Script" path="res://scenes/cutscene/chapter_6_cutscene.gd" id="chapter_6_cutscene_script"]
[ext_resource type="FontFile" uid="uid://c7je1jbvvhbpy" path="res://assets/fonts/Sarabun-Regular.ttf" id="chapter_6_cutscene_font"]
[ext_resource type="FontFile" uid="uid://qhf8k27eetcl" path="res://assets/fonts/Sarabun-Bold.ttf" id="chapter_6_cutscene_bold"]
[ext_resource type="Texture2D" uid="uid://bobkkl4uwe3n0" path="res://assets/ui/lable/pieces1/title_scroll_banner.png" id="chapter_6_title_banner"]
```

Append this node hierarchy to `chapter_6.tscn`:

```ini
[node name="Chapter6CutsceneLayer" type="CanvasLayer" parent="."]
layer = 100

[node name="Chapter6Cutscene" type="Control" parent="Chapter6CutsceneLayer"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("chapter_6_cutscene_script")

[node name="CutsceneImage" type="TextureRect" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("chapter_6_cutscene_image")
expand_mode = 1
stretch_mode = 6

[node name="BackgroundDim" type="ColorRect" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0, 0, 0, 0.34)

[node name="TitleBanner" type="NinePatchRect" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.19
anchor_right = 0.81
offset_top = 36.0
offset_bottom = 132.0
grow_horizontal = 2
texture = ExtResource("chapter_6_title_banner")
patch_margin_left = 92
patch_margin_top = 16
patch_margin_right = 92
patch_margin_bottom = 16

[node name="Title" type="Label" parent="Chapter6CutsceneLayer/Chapter6Cutscene/TitleBanner"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 86.0
offset_right = -86.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.2, 0.12, 0.045, 1)
theme_override_fonts/font = ExtResource("chapter_6_cutscene_bold")
theme_override_font_sizes/font_size = 32
text = "ประตูกรุงลงกา"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Dialogue" type="Label" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
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
theme_override_fonts/font = ExtResource("chapter_6_cutscene_font")
theme_override_font_sizes/font_size = 30
text = "คำบรรยาย: หลังจากหนุมานช่วยพระรามกลับมาจากไมยราพได้สำเร็จ พระรามก็เดินทางต่อไปยังกรุงลงกาเพื่อช่วยนางสีดา"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 2

[node name="ContinuePrompt" type="Label" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
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
theme_override_fonts/font = ExtResource("chapter_6_cutscene_font")
theme_override_font_sizes/font_size = 19
text = "กด E เพื่อดำเนินเรื่องต่อ ▼"
horizontal_alignment = 1

[node name="FadeOverlay" type="ColorRect" parent="Chapter6CutsceneLayer/Chapter6Cutscene"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0, 0, 0, 0)
```

- [ ] **Step 3: Run the focused contract test**

Run: `sh tests/test_chapter_6_opening_cutscene.sh`

Expected: `Chapter 6 opening cutscene contract passed`.

- [ ] **Step 4: Run regression and resource checks**

Run:

```bash
sh tests/test_chapter_4_hanuman_after_cutscene.sh
sh tests/test_chapter_5_post_boss_cutscene.sh
git diff --check
```

Expected: both regression tests print `passed`; `git diff --check` prints nothing and exits `0`.

- [ ] **Step 5: Run Godot validation when available**

Run:

```bash
if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --editor --quit
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --editor --quit
else
  echo "Godot CLI not available; static contract tests completed"
fi
```

Expected: Godot exits `0`, or the explicit unavailable message is printed.

- [ ] **Step 6: Commit the implementation**

```bash
git add scenes/cutscene/chapter_6_cutscene.gd scenes/chapter_6/chapter_6.tscn assets/cutscene/chapter_6 tests/test_chapter_6_opening_cutscene.sh
git commit -m "feat: add Chapter 6 Lanka gate cutscene"
```
