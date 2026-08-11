# Boss, Quest, and Web Icon UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Center and enlarge Miyarap's boss name, balance all quest-title wrapping within the existing two-column page, and restore the Chapter 4 magic-trail icon in clean Web exports.

**Architecture:** Keep each fix at its owning UI boundary. `miyarap.tscn` owns boss-bar geometry, `quest_log.gd` owns display-only responsive title formatting while preserving canonical quest state, and `magic_trail.tscn` owns a tracked ASCII-named source texture. Add focused runtime tests before each production change, then verify with fixed-size visual captures and a clean Web export.

**Tech Stack:** Godot 4.7.1, GDScript, Godot scene resources (`.tscn`), PNG textures, shell test runners, Godot Web exporter.

## Global Constraints

- Preserve the existing two-column quest page: quest list on the left, selected quest title and detail on the right.
- Do not change canonical quest names, quest progression, save data, combat balance, health values, boss-bar artwork, or magic-trail interaction behavior.
- Use Sarabun Bold at 24 px for the Miyarap name.
- Use 36/64 quest-column stretch ratios with 24 px separation.
- Quest title sizes are 17 px down to 15 px on the left and 24 px down to 20 px on the right.
- A wrapped title must not leave either line shorter than 35 percent of the title's measured width.
- The tracked magic-trail source path is exactly `assets/ui/icon/magic_trail_icon.png`.
- Preserve the user's unrelated unstaged edit in `scenes/chapter_9/chapter_9.tscn` and never include it in these commits.

---

## File Map

- `scenes/props/miyarap.tscn`: boss health-bar hierarchy, name font, and name alignment.
- `scenes/ui/quest_log.gd`: canonical quest-name state and display-only responsive formatting.
- `scenes/ui/quest_log.tscn`: two-column ratios, spacing, and title-label alignment.
- `assets/ui/icon/magic_trail_icon.png`: recovered, tracked source artwork for Web export.
- `assets/ui/icon/magic_trail_icon.png.import`: Godot import metadata generated from the recovered source.
- `scenes/props/magic_trail.tscn`: reference to the Web-safe icon path.
- `tests/test_miyarap_boss_hud_runtime.gd`: boss-name layout regression test.
- `tests/run_miyarap_boss_hud_tests.sh`: focused boss HUD runner.
- `tests/test_quest_title_layout_runtime.gd`: responsive title and canonical-state regression test.
- `tests/run_quest_title_layout_tests.sh`: focused quest-title runner.
- `tests/test_magic_trail_web_asset_runtime.gd`: missing-source and scene-reference regression test.
- `tests/run_magic_trail_web_asset_tests.sh`: focused magic-trail asset runner.
- `tests/capture_boss_quest_ui.gd`: deterministic wide and 1024×768 visual QA captures.

---

### Task 1: Miyarap Boss Name Layout

**Files:**
- Create: `tests/test_miyarap_boss_hud_runtime.gd`
- Create: `tests/run_miyarap_boss_hud_tests.sh`
- Modify: `scenes/props/miyarap.tscn:370-402`

**Interfaces:**
- Consumes: `res://scenes/props/miyarap.tscn`, node paths `BossHUD/BossBar` and `BossHUD/BossBar/BossName`.
- Produces: a `BossName` label parented to `BossBar`, font size 24, centered in a symmetric inner-bar rectangle.

- [ ] **Step 1: Write the failing boss HUD runtime test**

Create a `SceneTree` test that instantiates the real boss scene and asserts the desired hierarchy and geometry:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var boss := (load("res://scenes/props/miyarap.tscn") as PackedScene).instantiate()
	root.add_child(boss)
	await process_frame
	var bar := boss.get_node("BossHUD/BossBar") as TextureProgressBar
	var name_label := boss.get_node_or_null("BossHUD/BossBar/BossName") as Label
	_expect(name_label != null, "BossName is owned by BossBar")
	if name_label != null:
		_expect(name_label.get_theme_font_size("font_size") == 24, "BossName uses 24 px")
		_expect(name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "name is horizontally centered")
		_expect(name_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "name is vertically centered")
		_expect(is_equal_approx(name_label.offset_left, -name_label.offset_right), "inner horizontal offsets are symmetric")
		_expect(name_label.position.y + name_label.size.y * 0.5 > bar.size.y * 0.4, "name center is not above the inner bar")
		_expect(name_label.position.y + name_label.size.y * 0.5 < bar.size.y * 0.7, "name center is not below the inner bar")
	boss.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS: Miyarap boss HUD runtime")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
```

Create the runner using the repository's existing Godot path and log pattern:

```sh
#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
exec "$godot_bin" --headless --log-file /tmp/ramakien-miyarap-boss-hud-test.log \
  --path . --script res://tests/test_miyarap_boss_hud_runtime.gd
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `bash tests/run_miyarap_boss_hud_tests.sh`

Expected: FAIL because `BossName` is currently at `BossHUD/BossName`, not under `BossBar`, and uses 15 px.

- [ ] **Step 3: Implement the boss-name scene layout**

In `miyarap.tscn`, add Sarabun Bold as an external font resource, reparent `BossName` to `BossHUD/BossBar`, and use full-rect anchors with symmetric inner-bar margins:

```ini
[node name="BossName" type="Label" parent="BossHUD/BossBar"]
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
theme_override_fonts/font = ExtResource("boss_name_font")
theme_override_font_sizes/font_size = 24
text = "ไมยราพ"
horizontal_alignment = 1
vertical_alignment = 1
```

Keep the existing foreground color and shadow overrides.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `bash tests/run_miyarap_boss_hud_tests.sh`

Expected: `PASS: Miyarap boss HUD runtime` with no script errors.

- [ ] **Step 5: Commit Task 1**

```bash
git add scenes/props/miyarap.tscn tests/test_miyarap_boss_hud_runtime.gd tests/run_miyarap_boss_hud_tests.sh
git commit -m "fix: center Miyarap boss name"
```

---

### Task 2: Balanced Quest Titles Without Mutating Quest State

**Files:**
- Create: `tests/test_quest_title_layout_runtime.gd`
- Create: `tests/run_quest_title_layout_tests.sh`
- Modify: `scenes/ui/quest_log.gd:1-55,137-150`
- Modify: `scenes/ui/quest_log.tscn:120-178`

**Interfaces:**
- Consumes: `Quest.set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF)` and existing label nodes.
- Produces: `_layout_quest_titles()`, `_fit_title(label: Label, canonical_text: String, normal_size: int, minimum_size: int)`, and `_balanced_title_break(...) -> String`; `snapshot()` continues returning the unmodified canonical name.

- [ ] **Step 1: Write the failing quest layout runtime test**

Instantiate the real quest log, update it with short and long titles used across the game, and inspect both display labels after one process frame:

```gdscript
const TITLES: Array[String] = [
	"ปราบไมยราพ",
	"ตามหาขนนกพญาชฎายุ",
	"เดินทางไปยังกรุงลงกา",
	"ลักลอบเข้าไปในวังทศกัณฐ์",
	"สำรวจพระราชวังเพื่อหานางสีดา",
]

func _check_title(quest: CanvasLayer, title: String) -> void:
	quest.set_quest(title, "รายละเอียด")
	await process_frame
	var snapshot: Dictionary = quest.snapshot()
	_expect(snapshot.get("name") == title, "canonical title is unchanged: %s" % title)
	var left := quest.get_node("PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel") as Label
	var right := quest.get_node("PageDim/Page/PageMargin/Columns/Detail/DetailNameLabel") as Label
	_expect(left.label_settings.font_size >= 15, "left font stays readable")
	_expect(right.label_settings.font_size >= 20, "right font stays readable")
	_expect(_has_no_orphan(left), "left title has balanced lines: %s" % title)
	_expect(_has_no_orphan(right), "right title has balanced lines: %s" % title)
```

The helper splits on `\n`, measures each line with `label.label_settings.font.get_string_size(...)`, and fails when the shorter line is below 35 percent of the combined width. Also assert `Columns` uses separation 24 and stretch ratios 0.36/0.64.

Create `tests/run_quest_title_layout_tests.sh` following the exact shell structure from Task 1 with script path `res://tests/test_quest_title_layout_runtime.gd`.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `bash tests/run_quest_title_layout_tests.sh`

Expected: FAIL because the current ratios are 0.42/0.58, separation is 30, `snapshot()` reads presentation text, and no balancing routine exists.

- [ ] **Step 3: Separate canonical state from presentation text**

Add canonical state and use it for change detection and snapshots:

```gdscript
var _quest_name := ""

func set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void:
	var changed := not _has_quest or _quest_name != quest_name \
		or _detail_text_label.text != detail or _completed
	_quest_name = quest_name
	_name_label.text = quest_name
	_detail_name_label.text = quest_name
	# retain the existing completion, detail, visibility, target, and notification flow
	call_deferred("_layout_quest_titles")

func snapshot() -> Dictionary:
	if not _has_quest:
		return {}
	# retain existing target serialization
	return {"name": _quest_name, "detail": _detail_text_label.text, "target": target}
```

Reset `_quest_name` in `clear()`.

- [ ] **Step 4: Implement responsive fitting and balanced display wrapping**

Duplicate each label's `LabelSettings` once in `_ready()` so font-size changes stay local to this quest-log instance. Implement fitting using actual label width after container layout:

```gdscript
const LEFT_TITLE_SIZE := 17
const LEFT_TITLE_MIN_SIZE := 15
const RIGHT_TITLE_SIZE := 24
const RIGHT_TITLE_MIN_SIZE := 20
const MIN_LINE_WIDTH_RATIO := 0.35
const PREFERRED_BREAK_MARKERS: Array[String] = ["เพื่อ", "ไปยัง", "ใต้", "จาก", "และ", "ช่วย", "ตาม"]

func _layout_quest_titles() -> void:
	_fit_title(_name_label, _quest_name, LEFT_TITLE_SIZE, LEFT_TITLE_MIN_SIZE)
	_fit_title(_detail_name_label, _quest_name, RIGHT_TITLE_SIZE, RIGHT_TITLE_MIN_SIZE)

func _fit_title(label: Label, canonical_text: String, normal_size: int, minimum_size: int) -> void:
	label.text = canonical_text
	var font := label.label_settings.font
	var available_width := maxf(label.size.x, 1.0)
	for font_size in range(normal_size, minimum_size - 1, -1):
		if font.get_string_size(canonical_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available_width:
			label.label_settings.font_size = font_size
			return
	label.label_settings.font_size = minimum_size
	label.text = _balanced_title_break(canonical_text, font, minimum_size, available_width)
```

`_balanced_title_break()` must first collect positions immediately before preferred markers, then add character positions between 35 and 65 percent of the string when no marker fits. Skip positions whose next Unicode code point is a Thai combining mark (`U+0E31`, `U+0E34–U+0E3A`, or `U+0E47–U+0E4E`). Measure both candidate lines, reject candidates with a shorter-line ratio below `MIN_LINE_WIDTH_RATIO`, and return the candidate with the smallest width difference. Return the canonical text unchanged if no valid candidate exists.

- [ ] **Step 5: Apply the approved two-column geometry**

In `quest_log.tscn`:

```ini
[node name="Columns" type="HBoxContainer" parent="PageDim/Page/PageMargin"]
theme_override_constants/separation = 24

[node name="QuestList" type="VBoxContainer" parent="PageDim/Page/PageMargin/Columns"]
size_flags_stretch_ratio = 0.36

[node name="Detail" type="VBoxContainer" parent="PageDim/Page/PageMargin/Columns"]
size_flags_stretch_ratio = 0.64
```

Set both title labels to vertical center alignment and give the left entry a minimum height that cleanly supports two 15 px lines plus its existing content margins.

- [ ] **Step 6: Run focused and existing quest tests**

Run:

```bash
bash tests/run_quest_title_layout_tests.sh
bash tests/run_quest_notification_tests.sh
bash tests/run_chapter_quest_state_tests.sh
bash tests/run_chapter_quest_flow_tests.sh
```

Expected: all four runners pass with no script errors; snapshots contain original titles without inserted newlines.

- [ ] **Step 7: Commit Task 2**

```bash
git add scenes/ui/quest_log.gd scenes/ui/quest_log.tscn tests/test_quest_title_layout_runtime.gd tests/run_quest_title_layout_tests.sh
git commit -m "fix: balance quest title wrapping"
```

---

### Task 3: Restore the Magic-Trail Source Texture for Web Export

**Files:**
- Create: `assets/ui/icon/magic_trail_icon.png`
- Create: `assets/ui/icon/magic_trail_icon.png.import`
- Create: `tests/test_magic_trail_web_asset_runtime.gd`
- Create: `tests/run_magic_trail_web_asset_tests.sh`
- Modify: `scenes/props/magic_trail.tscn:3-17`
- Temporary only, do not commit: `/private/tmp/recover_magic_trail_icon.gd`

**Interfaces:**
- Consumes: the locally cached texture currently resolved by `MagicTrail/Icon`.
- Produces: tracked `res://assets/ui/icon/magic_trail_icon.png` and a scene reference that can be imported from a clean checkout.

- [ ] **Step 1: Write the failing Web-asset runtime test**

```gdscript
extends SceneTree

const ICON_PATH := "res://assets/ui/icon/magic_trail_icon.png"
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists(ICON_PATH), "tracked magic-trail source PNG exists")
	var packed := load("res://scenes/props/magic_trail.tscn") as PackedScene
	var trail := packed.instantiate()
	var icon := trail.get_node("Icon") as Sprite2D
	_expect(icon.texture != null, "magic-trail texture loads")
	if icon.texture != null:
		_expect(icon.texture.resource_path == ICON_PATH, "scene uses the Web-safe ASCII asset path")
	trail.free()
	_finish()
```

Use the same `_expect()`/`_finish()` helpers as Task 1. Create the runner with script path `res://tests/test_magic_trail_web_asset_runtime.gd`.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `bash tests/run_magic_trail_web_asset_tests.sh`

Expected: FAIL because the ASCII-named source PNG does not exist and the scene references the missing Thai-named source.

- [ ] **Step 3: Recover the exact cached artwork**

Create `/private/tmp/recover_magic_trail_icon.gd` with:

```gdscript
extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/props/magic_trail.tscn") as PackedScene
	var trail := packed.instantiate()
	var texture := (trail.get_node("Icon") as Sprite2D).texture
	if texture == null or texture.get_image() == null:
		push_error("The cached magic-trail texture cannot be recovered")
		quit(1)
		return
	var error := texture.get_image().save_png("res://assets/ui/icon/magic_trail_icon.png")
	trail.free()
	quit(0 if error == OK else 1)
```

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script /private/tmp/recover_magic_trail_icon.gd
sips -g pixelWidth -g pixelHeight -g hasAlpha assets/ui/icon/magic_trail_icon.png
```

Visually compare the recovered PNG to the working local icon before changing the scene.

- [ ] **Step 4: Reference and import the recovered source**

Change `magic_trail.tscn` resource `2_texture` to:

```ini
[ext_resource type="Texture2D" path="res://assets/ui/icon/magic_trail_icon.png" id="2_texture"]
```

Run Godot's editor import once:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
```

Confirm `assets/ui/icon/magic_trail_icon.png.import` exists and its `source_file` is the exact ASCII path.

- [ ] **Step 5: Run focused test and a clean Web export smoke test**

Run:

```bash
bash tests/run_magic_trail_web_asset_tests.sh
mkdir -p /private/tmp/ramakien-web-export
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --export-release Web /private/tmp/ramakien-web-export/index.html
test -s /private/tmp/ramakien-web-export/index.html
test -s /private/tmp/ramakien-web-export/index.pck
```

Expected: the focused test passes, export exits 0, both Web files exist, and the export log contains no missing-resource message for `magic_trail_icon.png`.

- [ ] **Step 6: Commit Task 3**

```bash
git add assets/ui/icon/magic_trail_icon.png assets/ui/icon/magic_trail_icon.png.import scenes/props/magic_trail.tscn tests/test_magic_trail_web_asset_runtime.gd tests/run_magic_trail_web_asset_tests.sh
git commit -m "fix: package magic trail icon for web"
```

---

### Task 4: Visual QA and Full Regression

**Files:**
- Create: `tests/capture_boss_quest_ui.gd`
- Test: all `tests/run_*.sh`

**Interfaces:**
- Consumes: the completed boss HUD, quest log, and magic-trail scene.
- Produces: four fixed-size screenshots under `/private/tmp` and final regression evidence.

- [ ] **Step 1: Create a deterministic SubViewport capture harness**

The harness must render through `SubViewport` rather than resizing the root window. Capture:

```text
/private/tmp/miyarap_boss_hud_1920x1080.png
/private/tmp/miyarap_boss_hud_1024x768.png
/private/tmp/quest_long_title_1920x1080.png
/private/tmp/quest_long_title_1024x768.png
```

For boss captures, instantiate `miyarap.tscn` and show its `BossHUD`. For quest captures, instantiate `quest_log.tscn`, call `set_quest("สำรวจพระราชวังเพื่อหานางสีดา", "สำรวจห้องต่าง ๆ ภายในพระราชวังและตามหานางสีดา")`, and invoke `_on_quest_button_pressed()`. Before saving each image, assert `image.get_size()` equals the requested viewport size; return a nonzero exit code on mismatch or save failure.

- [ ] **Step 2: Run and inspect visual captures**

Run with the GUI-compatible renderer:

```bash
HOME=/private/tmp/codex-godot-boss-quest \
  /Applications/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility \
  --path . --script res://tests/capture_boss_quest_ui.gd
```

Inspect all four PNGs. Confirm the boss name is large and centered inside the red bar; the long quest title is one line on the right when readable; any left-side wrap is visually balanced with no orphan fragment; and no control clips at 1024×768.

- [ ] **Step 3: Run every test runner and reject hidden script errors**

```bash
test_log_dir=$(mktemp -d /private/tmp/ramakien-ui-tests.XXXXXX)
for test_script in tests/run_*.sh; do
  test_log="$test_log_dir/$(basename "$test_script").log"
  bash "$test_script" >"$test_log" 2>&1
  ! rg -q "SCRIPT ERROR" "$test_log"
done
```

Expected: every runner exits 0 and no per-run log contains `SCRIPT ERROR`.

- [ ] **Step 4: Run final repository checks**

```bash
git diff --check
git status --short
git diff -- scenes/chapter_9/chapter_9.tscn
```

Expected: no whitespace errors; only the user's pre-existing Chapter 9 edit remains unstaged; task files are committed.

- [ ] **Step 5: Commit the visual harness**

```bash
git add tests/capture_boss_quest_ui.gd
git commit -m "test: add boss and quest visual QA"
```

- [ ] **Step 6: Request final code review**

Review the complete range from `9912553` through `HEAD` for requirement coverage, Web-export safety, UI regressions, and accidental inclusion of the user's Chapter 9 change. Resolve Critical and Important findings, rerun focused/full verification after any change, and only then offer branch integration options.
