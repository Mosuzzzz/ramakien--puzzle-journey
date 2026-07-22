# Chapter 5 Lanka March Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a second image and three narration entries after the existing Chapter 5 post-Maiyarap dialogue.

**Architecture:** Extend the existing post-boss Control with a second dialogue phase and TextureRect. The existing boss trigger and idempotent finish path remain unchanged, so normal completion and skipping continue to restore Phra Ram safely.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene resources, shell structural regression test

## Global Constraints

- Use image UID `uid://cm4owh1l85bo4`.
- Fade out and reveal over 1 second each between phases.
- Do not create another boss trigger or another cutscene Control.
- Restore Phra Ram only after phase two finishes, or immediately when skipped.

---

### Task 1: Add the Lanka march phase

**Files:**
- Modify: `tests/test_chapter_5_post_boss_cutscene.sh`
- Modify: `scenes/chapter_5/chapter_5.tscn`
- Modify: `scenes/cutscene/chapter_5_post_boss_cutscene.gd`

**Interfaces:**
- Consumes: existing `show_cutscene()`, `_advance_dialogue()`, `_show_dialogue()`, and `_finish_cutscene()` functions.
- Produces: `FINAL_DIALOGUES`, `_dialogue_phase`, `_current_dialogues()`, and `_transition_to_final_cutscene()`.

- [ ] **Step 1: Extend the failing structural test**

Add assertions for the new image, dialogue phase, transition, and narration:

```sh
grep -Fq 'ChatGPT Image 21 ก.ค. 2569 21_01_37.png' "$scene"
grep -Fq 'FINAL_DIALOGUES' "$cutscene"
grep -Fq '_transition_to_final_cutscene()' "$cutscene"
grep -Fq 'ทุกคนมองไปยังกำแพงกรุงลงกา' "$cutscene"
grep -Fq 'พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา' "$cutscene"
```

- [ ] **Step 2: Run the focused test and confirm it fails**

Run: `sh tests/test_chapter_5_post_boss_cutscene.sh`

Expected: exit code `1` because the new image resource and final phase do not exist.

- [ ] **Step 3: Add the image resource and second TextureRect**

Add to `chapter_5.tscn`:

```tscn
[ext_resource type="Texture2D" uid="uid://cm4owh1l85bo4" path="res://assets/cutscene/chapter_5/ChatGPT Image 21 ก.ค. 2569 21_01_37.png" id="lanka_march_image"]

[node name="LankaMarchImage" type="TextureRect" parent="Chapter5CutsceneLayer/Chapter5PostBossCutscene"]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("lanka_march_image")
expand_mode = 1
stretch_mode = 6
```

- [ ] **Step 4: Add the second phase and transition**

Add the final dialogue array and phase state:

```gdscript
const FINAL_DIALOGUES: Array[String] = [
	"คำบรรยาย: ทุกคนมองไปยังกำแพงกรุงลงกา ที่ตั้งตระหง่านอยู่เบื้องหน้า",
	"คำบรรยาย: เสียงกลองศึกของฝ่ายยักษ์ดังขึ้นจากภายในเมือง",
	"คำบรรยาย: พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา เพื่อเผชิญหน้ากับทศกัณฐ์และชิงนางสีดากลับคืนมา",
]

var _dialogue_phase := 0
@onready var _final_image: TextureRect = $LankaMarchImage
```

Make `_advance_dialogue()` transition after phase one and finish after phase two. Make `_show_dialogue()` read `_current_dialogues()` and show the return prompt only on the final line of phase two.

Implement the transition:

```gdscript
func _transition_to_final_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	_dialogue_phase = 1
	_dialogue_index = 0
	_image.hide()
	_final_image.show()
	$TitleBanner/Title.text = "มุ่งหน้าสู่กรุงลงกา"
	_show_dialogue(0, false)
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false
```

- [ ] **Step 5: Run verification**

Run: `sh tests/test_chapter_5_post_boss_cutscene.sh`

Expected: `Chapter 5 post-boss cutscene contract passed`.

Run: `sh tests/test_chapter_4_hanuman_after_cutscene.sh`

Expected: `Chapter 4 Hanuman switch contract passed`.

Run: `git diff --check`

Expected: exit code `0` with no output.
