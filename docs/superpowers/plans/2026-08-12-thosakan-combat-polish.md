# Thosakan Combat Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Center and enlarge Thosakan's boss name, make his chase slightly faster, and restore reliable normal attacks without adding `Stunned` or `dead` behavior.

**Architecture:** Keep all tuning and presentation changes local to `thosakan.tscn`; the shared `mob.gd` controller and every other enemy remain unchanged. A focused runtime test loads the real scene, verifies the HUD and exported tuning values, and proves the existing normal-attack path starts at a distance that previously could not trigger.

**Tech Stack:** Godot 4.7.1, GDScript, Godot headless runtime tests, Godot Web exporter

## Global Constraints

- Do not add stun counters, stun states, death animations, or delayed disappearance.
- Preserve Thosakan's existing special attacks, healing phase, damage values, defeat signal, and disappearance behavior.
- Do not modify `scenes/props/mob.gd` or change behavior for other enemies.
- Do not delete or stage the user's untracked Thosakan source images.
- Do not include unrelated edits in `scenes/chapter_2/chapter_2_second.tscn` or `scenes/chapter_9/chapter_9.tscn`.

---

### Task 1: Add a failing Thosakan combat-polish runtime test

**Files:**
- Create: `tests/test_thosakan_combat_polish_runtime.gd`
- Create: `tests/run_thosakan_combat_polish_tests.sh`
- Create after Godot import: `tests/test_thosakan_combat_polish_runtime.gd.uid`

**Interfaces:**
- Consumes: `res://scenes/props/thosakan.tscn`, inherited properties `speed` and `attack_range`, the real `BossHUD/BossBar` tree, and `_physics_process(delta: float)`.
- Produces: one executable regression runner that exits nonzero when presentation, tuning, animation scope, or attack activation regresses.

- [ ] **Step 1: Write the failing runtime test**

Create `tests/test_thosakan_combat_polish_runtime.gd` with a real scene instance and a minimal damage-receiving player:

```gdscript
extends SceneTree

var _failures: Array[String] = []


class DamageReceiver:
	extends Node2D
	var current_health := 100
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount
		current_health -= amount


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/props/thosakan.tscn") as PackedScene
	_expect(packed != null, "Thosakan scene loads")
	if packed == null:
		_finish()
		return

	var stage := Node2D.new()
	root.add_child(stage)
	var player := DamageReceiver.new()
	player.name = "Player"
	player.position = Vector2(100.0, 0.0)
	stage.add_child(player)
	var boss := packed.instantiate()
	stage.add_child(boss)
	boss.set_physics_process(false)
	await process_frame

	_expect(is_equal_approx(boss.speed, 75.0), "Thosakan walks at 75 px/s")
	_expect(is_equal_approx(boss.attack_range, 130.0), "Thosakan attack range matches his collision geometry")

	var bar := boss.get_node("BossHUD/BossBar") as TextureProgressBar
	var name_label := boss.get_node_or_null("BossHUD/BossBar/BossName") as Label
	_expect(name_label != null, "BossName follows BossBar layout")
	if name_label != null:
		_expect(name_label.get_theme_font_size("font_size") >= 24, "BossName is at least 24 px")
		_expect(name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "BossName is horizontally centered")
		_expect(name_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "BossName is vertically centered")
		var bar_center := bar.get_global_rect().get_center()
		var label_center := name_label.get_global_rect().get_center()
		_expect(absf(label_center.x - bar_center.x) <= 1.0, "BossName follows the bar center")

	var sprite := boss.get_node("Sprite") as AnimatedSprite2D
	_expect(not sprite.sprite_frames.has_animation(&"Stunned"), "Stunned animation is excluded")
	_expect(not sprite.sprite_frames.has_animation(&"dead"), "dead animation is excluded")
	boss._physics_process(0.016)
	_expect(boss._attacking, "Thosakan starts a normal attack from 100 px")
	_expect(sprite.animation == &"Attack", "Thosakan plays the existing Attack animation")

	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: Thosakan combat polish runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

- [ ] **Step 2: Add the focused runner**

Create `tests/run_thosakan_combat_polish_tests.sh`:

```sh
#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
"$godot_bin" \
  --headless --editor --quit \
  --log-file /tmp/ramakien-thosakan-combat-import.log --path .
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-thosakan-combat-test.log \
  --path . --script res://tests/test_thosakan_combat_polish_runtime.gd
```

- [ ] **Step 3: Run the test and verify RED**

Run: `bash tests/run_thosakan_combat_polish_tests.sh`

Expected: FAIL because speed is 60, attack range is 55, `BossName` is not under `BossBar` and is only 15 px, and the uncommitted scene still contains `Stunned` and `dead`.

### Task 2: Apply the targeted scene fix and verify GREEN

**Files:**
- Modify: `scenes/props/thosakan.tscn`
- Test: `tests/test_thosakan_combat_polish_runtime.gd`
- Test: `tests/run_thosakan_combat_polish_tests.sh`
- Test metadata: `tests/test_thosakan_combat_polish_runtime.gd.uid`

**Interfaces:**
- Consumes: the existing inherited mob controller, existing `Attack` animation, existing boss health textures, and `res://assets/fonts/Sarabun-Bold.ttf`.
- Produces: a Thosakan scene with `speed = 75.0`, `attack_range = 130.0`, and `BossHUD/BossBar/BossName` matching Miyarap's centered 24 px treatment.

- [ ] **Step 1: Remove only the rejected animation additions**

Use a narrow patch in `scenes/props/thosakan.tscn` to remove:

- ExtResources `8_xpv38`, `9_kk6sy`, `10_u1mas`, and `11_d5u43`.
- AtlasTexture subresources `AtlasTexture_vcy7g`, `AtlasTexture_ddx0c`, `AtlasTexture_bpn4s`, `AtlasTexture_7mpqk`, `AtlasTexture_g562r`, `AtlasTexture_6tk3f`, `AtlasTexture_oosng`, `AtlasTexture_awmuq`, `AtlasTexture_joaxu`, and `AtlasTexture_dibr2`.
- The `Stunned` and `dead` entries from `thosakan_frames`.

Set the editor preview animation back to the existing idle animation:

```ini
[node name="Sprite" type="AnimatedSprite2D" parent="." unique_id=1368735828]
sprite_frames = SubResource("thosakan_frames")
animation = &"idle"
autoplay = "idle"
```

Do not delete or stage any PNG or `.import` file that those rejected animations used.

- [ ] **Step 2: Add Thosakan-specific combat tuning**

Update the root node without touching `mob.gd`:

```ini
[node name="ThoSaKan" type="CharacterBody2D" unique_id=1596516181]
script = ExtResource("1_script")
speed = 75.0
attack_range = 130.0
```

- [ ] **Step 3: Match Miyarap's boss-name layout**

Add the font resource:

```ini
[ext_resource type="FontFile" path="res://assets/fonts/Sarabun-Bold.ttf" id="92_boss_font"]
```

Replace the existing sibling label with a child of `BossBar`:

```ini
[node name="BossName" type="Label" parent="BossHUD/BossBar" unique_id=618234907]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 105.0
offset_top = 26.0
offset_right = -105.0
offset_bottom = -15.0
grow_horizontal = 2
grow_vertical = 2
theme_override_fonts/font = ExtResource("92_boss_font")
theme_override_font_sizes/font_size = 24
theme_override_colors/font_color = Color(1, 0.95, 0.8, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.8)
theme_override_constants/shadow_offset_x = 1
theme_override_constants/shadow_offset_y = 1
text = "ทศกัณฐ์"
horizontal_alignment = 1
vertical_alignment = 1
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `bash tests/run_thosakan_combat_polish_tests.sh`

Expected: `PASS: Thosakan combat polish runtime`, exit code 0, and no `SCRIPT ERROR` in `/tmp/ramakien-thosakan-combat-test.log`.

- [ ] **Step 5: Commit the focused implementation**

```bash
git add scenes/props/thosakan.tscn tests/test_thosakan_combat_polish_runtime.gd tests/test_thosakan_combat_polish_runtime.gd.uid tests/run_thosakan_combat_polish_tests.sh
git commit -m "fix: polish Thosakan boss combat"
```

Before committing, confirm `git diff --cached --name-only` lists only those four paths.

### Task 3: Visual QA, regression suite, and Web export

**Files:**
- Create: `tests/capture_thosakan_boss_hud.gd`
- Create after Godot import: `tests/capture_thosakan_boss_hud.gd.uid`

**Interfaces:**
- Consumes: the corrected `thosakan.tscn`, all existing `tests/run_*_tests.sh` runners, and the `Web` export preset.
- Produces: exact-size HUD screenshots plus final evidence that all runtime tests and the Web export pass.

- [ ] **Step 1: Add a deterministic HUD capture script**

Create `tests/capture_thosakan_boss_hud.gd` that captures the real scene at 1920×1080 and 1024×768, hides only the character sprite, validates the captured dimensions, and writes:

```gdscript
extends SceneTree

const WIDE_PATH := "/private/tmp/thosakan_boss_hud_1920x1080.png"
const COMPACT_PATH := "/private/tmp/thosakan_boss_hud_1024x768.png"


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	if not await _capture(Vector2i(1920, 1080), WIDE_PATH):
		quit(1)
		return
	if not await _capture(Vector2i(1024, 768), COMPACT_PATH):
		quit(1)
		return
	print("CAPTURED: %s" % WIDE_PATH)
	print("CAPTURED: %s" % COMPACT_PATH)
	quit(0)


func _capture(viewport_size: Vector2i, path: String) -> bool:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#596169")
	viewport.add_child(background)
	var packed := load("res://scenes/props/thosakan.tscn") as PackedScene
	if packed == null:
		push_error("Thosakan scene failed to load")
		viewport.queue_free()
		return false
	var boss := packed.instantiate()
	(boss.get_node("Sprite") as AnimatedSprite2D).hide()
	viewport.add_child(boss)
	for frame in 8:
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != viewport_size:
		push_error("Invalid capture for %s" % path)
		viewport.queue_free()
		return false
	var error := image.save_png(path)
	viewport.queue_free()
	await process_frame
	if error != OK:
		push_error("Failed to save %s (error %d)" % [path, error])
		return false
	return true
```

- [ ] **Step 2: Generate and inspect both HUD captures**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/capture_thosakan_boss_hud.gd
sips -g pixelWidth -g pixelHeight /private/tmp/thosakan_boss_hud_1920x1080.png /private/tmp/thosakan_boss_hud_1024x768.png
```

Expected: both dimensions match their filenames; visual inspection shows `ทศกัณฐ์` centered inside the red tube with no clipping.

- [ ] **Step 3: Run focused neighboring regressions**

Run:

```bash
bash tests/run_thosakan_combat_polish_tests.sh
bash tests/run_enemy_audio_tests.sh
bash tests/run_world_movement_audio_tests.sh
bash tests/run_boss_music_hook_tests.sh
```

Expected: all four runners exit 0 with no `SCRIPT ERROR`.

- [ ] **Step 4: Run the complete test suite**

Run every `tests/run_*_tests.sh` script, storing each log under a new `/private/tmp/ramakien-thosakan-suite.XXXXXX` directory. Stop on a nonzero exit or `SCRIPT ERROR` and report the exact runner; otherwise report the final runner count.

- [ ] **Step 5: Produce a fresh Web export**

Run:

```bash
mkdir -p /private/tmp/ramakien-thosakan-web
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release Web /private/tmp/ramakien-thosakan-web/index.html
```

Expected: exit code 0; `index.html` and `index.pck` exist; the export log contains no `SCRIPT ERROR`, missing-resource error, or failed Thosakan texture dependency.

- [ ] **Step 6: Check scope and commit the QA harness**

Run:

```bash
git diff --check
git status --short
git diff -- scenes/props/thosakan.tscn
```

Confirm the user's Chapter 2, Chapter 9, PNG, and `.import` changes remain unstaged and untouched. Then commit only the capture harness:

```bash
git add tests/capture_thosakan_boss_hud.gd tests/capture_thosakan_boss_hud.gd.uid
git commit -m "test: add Thosakan boss HUD visual QA"
```
