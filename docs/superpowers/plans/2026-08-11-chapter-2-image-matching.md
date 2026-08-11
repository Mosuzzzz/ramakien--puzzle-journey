# Chapter 2 Image Matching Puzzle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Chapter 2 matching puzzle's left-side words with the four supplied illustrations and communicate correct and incorrect matches through persistent pair-colored and flashing red borders.

**Architecture:** Keep `matching_puzzle.gd` as the reusable controller and extend its input normalization to accept image-backed dictionaries alongside legacy two-item text arrays. Chapter 2 owns the semantic image-to-description data, while focused helpers in the shared component create cards and apply border states consistently.

**Tech Stack:** Godot 4.7, GDScript, Godot `Button`/`StyleBoxFlat` theme overrides, headless SceneTree integration tests.

## Global Constraints

- The four left cards display only the supplied illustrations and never display item-name captions.
- Correct matches use orange, yellow, blue, and green borders, assigned by stable source-pair index; both cards in a pair use the same color.
- Incorrect matches flash red three times, ignore overlapping input during feedback, and become selectable again.
- Existing answer audio, `solved` signaling, pause behavior, quest flow, shuffled right column, and legacy text-pair support remain intact.
- Do not modify or include the user's unrelated change in `scenes/chapter_9/chapter_9.tscn` in any commit.

---

## File Map

- Create `assets/puzzles/chapter_2/firewood.png`: supplied firewood illustration.
- Create `assets/puzzles/chapter_2/stream_water.png`: supplied stream-water illustration.
- Create `assets/puzzles/chapter_2/herbs.png`: supplied herb illustration.
- Create `assets/puzzles/chapter_2/dry_leaves.png`: supplied dry-leaf illustration.
- Modify `scenes/chapter_2/chapter_2.gd`: define four image-backed matching pairs.
- Modify `scenes/ui/matching_puzzle.gd`: normalize pair data, construct image-only buttons, render border states, and lock input during wrong feedback.
- Modify `scenes/ui/matching_puzzle.tscn`: enlarge the modal and card area for legible illustrations while preserving the current parchment layout.
- Create `tests/test_chapter_2_image_matching_runtime.gd`: focused runtime assertions for data, rendering, matching, feedback, audio, and completion.
- Create `tests/run_chapter_2_image_matching_tests.sh`: headless runner for the focused test suite.

---

### Task 1: Chapter 2 Image Pair Data and Assets

**Files:**
- Create: `assets/puzzles/chapter_2/firewood.png`
- Create: `assets/puzzles/chapter_2/stream_water.png`
- Create: `assets/puzzles/chapter_2/herbs.png`
- Create: `assets/puzzles/chapter_2/dry_leaves.png`
- Modify: `scenes/chapter_2/chapter_2.gd:5-10`
- Create: `tests/test_chapter_2_image_matching_runtime.gd`
- Create: `tests/run_chapter_2_image_matching_tests.sh`

**Interfaces:**
- Consumes: The four supplied files in `/Users/siwakornbundi/Downloads/ChatGPT Image 11 ส.ค. 2569 23_15_53.png` through `23_16_10.png`.
- Produces: `SUPPLY_PAIRS`, an array of dictionaries shaped as `{ "left_image": String, "right_text": String }`.

- [ ] **Step 1: Write the failing data test and runner**

Create the runner:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-2-image-matching-test.log \
  --path . --script res://tests/test_chapter_2_image_matching_runtime.gd
```

Start the test file with the data assertion and shared harness:

```gdscript
extends SceneTree

const Chapter2 := preload("res://scenes/chapter_2/chapter_2.gd")

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _test_chapter_2_image_pair_data()
    _finish()


func _test_chapter_2_image_pair_data() -> void:
    var expected_paths := [
        "res://assets/puzzles/chapter_2/firewood.png",
        "res://assets/puzzles/chapter_2/stream_water.png",
        "res://assets/puzzles/chapter_2/herbs.png",
        "res://assets/puzzles/chapter_2/dry_leaves.png",
    ]
    var expected_right := [
        "สำหรับก่อไฟหุงหาอาหาร",
        "สำหรับดื่มและประกอบอาหาร",
        "สำหรับรักษาบาดแผล",
        "สำหรับปูที่นอน",
    ]
    _expect(Chapter2.SUPPLY_PAIRS.size() == 4, "Chapter 2 defines four supply pairs")
    for i in expected_paths.size():
        var pair: Variant = Chapter2.SUPPLY_PAIRS[i]
        _expect(pair is Dictionary, "supply pair %d uses structured image data" % i)
        if pair is Dictionary:
            _expect(pair.get("left_image", "") == expected_paths[i], "supply pair %d image path" % i)
            _expect(pair.get("right_text", "") == expected_right[i], "supply pair %d description" % i)
        _expect(ResourceLoader.exists(expected_paths[i]), "supply image %d exists" % i)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    if _failures.is_empty():
        print("PASS: Chapter 2 image matching")
        quit(0)
        return
    for failure in _failures:
        push_error(failure)
    quit(1)
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `chmod +x tests/run_chapter_2_image_matching_tests.sh && tests/run_chapter_2_image_matching_tests.sh`

Expected: FAIL because the existing `SUPPLY_PAIRS` entries are arrays and the four project asset paths do not exist.

- [ ] **Step 3: Copy the supplied assets and replace the pair definitions**

Copy the source images without altering them:

```bash
mkdir -p assets/puzzles/chapter_2
cp '/Users/siwakornbundi/Downloads/ChatGPT Image 11 ส.ค. 2569 23_15_53.png' assets/puzzles/chapter_2/firewood.png
cp '/Users/siwakornbundi/Downloads/ChatGPT Image 11 ส.ค. 2569 23_16_00.png' assets/puzzles/chapter_2/stream_water.png
cp '/Users/siwakornbundi/Downloads/ChatGPT Image 11 ส.ค. 2569 23_16_05.png' assets/puzzles/chapter_2/herbs.png
cp '/Users/siwakornbundi/Downloads/ChatGPT Image 11 ส.ค. 2569 23_16_10.png' assets/puzzles/chapter_2/dry_leaves.png
```

Replace `SUPPLY_PAIRS` with:

```gdscript
const SUPPLY_PAIRS := [
    {
        "left_image": "res://assets/puzzles/chapter_2/firewood.png",
        "right_text": "สำหรับก่อไฟหุงหาอาหาร",
    },
    {
        "left_image": "res://assets/puzzles/chapter_2/stream_water.png",
        "right_text": "สำหรับดื่มและประกอบอาหาร",
    },
    {
        "left_image": "res://assets/puzzles/chapter_2/herbs.png",
        "right_text": "สำหรับรักษาบาดแผล",
    },
    {
        "left_image": "res://assets/puzzles/chapter_2/dry_leaves.png",
        "right_text": "สำหรับปูที่นอน",
    },
]
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `tests/run_chapter_2_image_matching_tests.sh`

Expected: PASS with `PASS: Chapter 2 image matching`.

- [ ] **Step 5: Commit Task 1**

```bash
git add assets/puzzles/chapter_2 scenes/chapter_2/chapter_2.gd tests/test_chapter_2_image_matching_runtime.gd tests/run_chapter_2_image_matching_tests.sh
git commit -m "feat: add chapter 2 matching illustrations"
```

---

### Task 2: Image-Only Left Cards with Legacy Compatibility

**Files:**
- Modify: `tests/test_chapter_2_image_matching_runtime.gd`
- Modify: `scenes/ui/matching_puzzle.gd:14-55`
- Modify: `scenes/ui/matching_puzzle.tscn:26-80`

**Interfaces:**
- Consumes: Image-backed dictionaries from Task 1 and legacy `[left_text, right_text]` arrays.
- Produces: `_make_left_button(pair: Variant) -> Button`, `_pair_right_text(pair: Variant) -> String`, and unchanged `open(title: String, pairs: Array) -> void` behavior.

- [ ] **Step 1: Add failing rendering and compatibility tests**

Add these calls to `_run()` before `_finish()`:

```gdscript
_test_image_only_left_cards()
_test_legacy_text_pairs()
```

Add the tests and spawn helper:

```gdscript
func _test_image_only_left_cards() -> void:
    var puzzle := _spawn_puzzle()
    puzzle.open("Match", [Chapter2.SUPPLY_PAIRS[0]])
    var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
    _expect(left.text.is_empty(), "image card has no caption")
    _expect(left.icon != null, "image card loads its illustration")
    _expect(left.expand_icon, "image card scales its illustration")
    puzzle.free()


func _test_legacy_text_pairs() -> void:
    var puzzle := _spawn_puzzle()
    puzzle.open("Match", [["L1", "R1"]])
    var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
    var right := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn").get_child(0) as Button
    _expect(left.text == "L1", "legacy left text remains supported")
    _expect(left.icon == null, "legacy left card has no image")
    _expect(right.text == "R1", "legacy right text remains supported")
    puzzle.free()


func _spawn_puzzle() -> CanvasLayer:
    var puzzle := (load("res://scenes/ui/matching_puzzle.tscn") as PackedScene).instantiate()
    root.add_child(puzzle)
    return puzzle
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `tests/run_chapter_2_image_matching_tests.sh`

Expected: FAIL when the existing `open()` passes a dictionary into `_make_button(label: String)` and no image card is created.

- [ ] **Step 3: Implement pair normalization and image card construction**

Change the left loop to call `_make_left_button(pairs[i])`, and change the right loop to call `_make_text_button(_pair_right_text(pairs[idx]))`. Replace `_make_button` with:

```gdscript
func _make_left_button(pair: Variant) -> Button:
    if pair is Dictionary:
        var btn := _make_base_button()
        var image_path := str(pair.get("left_image", ""))
        if ResourceLoader.exists(image_path):
            btn.icon = load(image_path) as Texture2D
            btn.expand_icon = true
            btn.icon_max_width = 220
        return btn
    return _make_text_button(str(pair[0]))


func _pair_right_text(pair: Variant) -> String:
    if pair is Dictionary:
        return str(pair.get("right_text", ""))
    return str(pair[1])


func _make_text_button(label: String) -> Button:
    var btn := _make_base_button()
    btn.text = label
    return btn


func _make_base_button() -> Button:
    var btn := Button.new()
    btn.custom_minimum_size = Vector2(240, 92)
    btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    btn.add_theme_font_override("font", BUTTON_FONT)
    btn.add_theme_font_size_override("font_size", 16)
    return btn
```

Increase the parchment panel vertical half-size from `260` to `300`, its horizontal half-size from `320` to `380`, and retain two equal-width columns. This makes four 92-pixel cards plus gaps fit without compressing the title and hint.

- [ ] **Step 4: Run focused and existing audio tests**

Run: `tests/run_chapter_2_image_matching_tests.sh && tests/run_puzzle_audio_tests.sh`

Expected: Both suites PASS. The legacy audio test proves array-based pair compatibility.

- [ ] **Step 5: Commit Task 2**

```bash
git add scenes/ui/matching_puzzle.gd scenes/ui/matching_puzzle.tscn tests/test_chapter_2_image_matching_runtime.gd
git commit -m "feat: render image cards in matching puzzle"
```

---

### Task 3: Selected and Correct Pair Border States

**Files:**
- Modify: `tests/test_chapter_2_image_matching_runtime.gd`
- Modify: `scenes/ui/matching_puzzle.gd:1-95`

**Interfaces:**
- Consumes: Buttons created by `_make_base_button()` and source-pair indices from `open()`.
- Produces: `PAIR_BORDER_COLORS: Array[Color]`, `_set_border(button: Button, color: Color, width: int) -> void`, persistent correct borders, and gold selection borders.

- [ ] **Step 1: Add failing selection and correct-color tests**

Add these calls to `_run()`:

```gdscript
_test_selected_border()
_test_correct_pairs_share_distinct_borders()
```

Add:

```gdscript
func _test_selected_border() -> void:
    var puzzle := _spawn_puzzle()
    puzzle.open("Match", [["L1", "R1"]])
    var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
    puzzle._on_left_pressed(left, 0)
    _expect(_border_color(left).is_equal_approx(puzzle.SELECTED_BORDER_COLOR), "selected card uses gold border")
    puzzle.free()


func _test_correct_pairs_share_distinct_borders() -> void:
    var puzzle := _spawn_puzzle()
    puzzle.open("Match", [["L1", "R1"], ["L2", "R2"]])
    var left_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn")
    var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
    var observed: Array[Color] = []
    for i in 2:
        var left := left_column.get_child(i) as Button
        var right := _find_button_with_text(right_column, "R%d" % (i + 1))
        puzzle._on_left_pressed(left, i)
        puzzle._on_right_pressed(right, i)
        _expect(_border_color(left).is_equal_approx(_border_color(right)), "correct pair %d shares one border color" % i)
        observed.append(_border_color(left))
    _expect(not observed[0].is_equal_approx(observed[1]), "different correct pairs use distinct colors")
    puzzle.free()


func _border_color(button: Button) -> Color:
    return (button.get_theme_stylebox("normal") as StyleBoxFlat).border_color


func _find_button_with_text(parent: Node, text: String) -> Button:
    for child: Button in parent.get_children():
        if child.text == text:
            return child
    return null
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `tests/run_chapter_2_image_matching_tests.sh`

Expected: FAIL because selection and correct feedback currently use `modulate`, and no `StyleBoxFlat` border state or color constants exist.

- [ ] **Step 3: Implement reusable border styles**

Add constants:

```gdscript
const NEUTRAL_BORDER_COLOR := Color("705b43")
const SELECTED_BORDER_COLOR := Color("e9b949")
const WRONG_BORDER_COLOR := Color("ef3340")
const PAIR_BORDER_COLORS: Array[Color] = [
    Color("f28c28"),
    Color("f2c94c"),
    Color("2f80ed"),
    Color("27ae60"),
]
```

Add a single style helper that applies the same border to every button state:

```gdscript
func _set_border(button: Button, color: Color, width: int = 4) -> void:
    for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("6f6557")
        style.border_color = color
        style.set_border_width_all(width)
        style.set_corner_radius_all(8)
        style.content_margin_left = 12.0
        style.content_margin_right = 12.0
        style.content_margin_top = 8.0
        style.content_margin_bottom = 8.0
        button.add_theme_stylebox_override(state, style)
```

Call `_set_border(btn, NEUTRAL_BORDER_COLOR, 2)` in `_make_base_button()`. Replace selection `modulate` changes with neutral/selected `_set_border` calls. On a correct match, use:

```gdscript
var pair_color := PAIR_BORDER_COLORS[index % PAIR_BORDER_COLORS.size()]
_set_border(_selected_left, pair_color)
_set_border(btn, pair_color)
```

Keep both correct buttons disabled. Remove the green `modulate` success feedback entirely.

- [ ] **Step 4: Run focused and audio suites and verify GREEN**

Run: `tests/run_chapter_2_image_matching_tests.sh && tests/run_puzzle_audio_tests.sh`

Expected: Both suites PASS; correct-answer audio remains `answer_correct`.

- [ ] **Step 5: Commit Task 3**

```bash
git add scenes/ui/matching_puzzle.gd tests/test_chapter_2_image_matching_runtime.gd
git commit -m "feat: add pair-colored matching borders"
```

---

### Task 4: Flashing Wrong Borders and Retry Lock

**Files:**
- Modify: `tests/test_chapter_2_image_matching_runtime.gd`
- Modify: `scenes/ui/matching_puzzle.gd:10-125`

**Interfaces:**
- Consumes: `_set_border`, `WRONG_BORDER_COLOR`, and `NEUTRAL_BORDER_COLOR` from Task 3.
- Produces: `_feedback_active: bool`, `WRONG_FLASH_COUNT := 3`, `WRONG_FLASH_INTERVAL := 0.10`, and `_flash_wrong_pair(left: Button, right: Button) -> void`.

- [ ] **Step 1: Add failing wrong-feedback and retry tests**

Make `_run()` await the asynchronous test before `_finish()`:

```gdscript
await _test_wrong_pair_flashes_and_retries()
```

Add:

```gdscript
func _test_wrong_pair_flashes_and_retries() -> void:
    var puzzle := _spawn_puzzle()
    puzzle.open("Match", [["L1", "R1"], ["L2", "R2"]])
    var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
    var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
    var wrong := _find_button_with_text(right_column, "R2")
    puzzle._on_left_pressed(left, 0)
    puzzle._on_right_pressed(wrong, 1)
    await process_frame
    _expect(left.disabled and wrong.disabled, "wrong pair locks both involved cards during feedback")
    _expect(puzzle._feedback_active, "wrong feedback blocks overlapping attempts")
    _expect(puzzle.WRONG_FLASH_COUNT == 3, "wrong feedback is configured for three flashes")
    _expect(_border_color(left).is_equal_approx(puzzle.WRONG_BORDER_COLOR), "wrong feedback begins with a red border")
    await create_timer(0.65).timeout
    _expect(not left.disabled and not wrong.disabled, "wrong pair is selectable after feedback")
    _expect(not puzzle._feedback_active, "wrong feedback releases the input lock")
    _expect(_border_color(left).is_equal_approx(puzzle.NEUTRAL_BORDER_COLOR), "wrong left border returns to neutral")
    _expect(_border_color(wrong).is_equal_approx(puzzle.NEUTRAL_BORDER_COLOR), "wrong right border returns to neutral")
    puzzle._on_left_pressed(left, 0)
    var correct := _find_button_with_text(right_column, "R1")
    puzzle._on_right_pressed(correct, 0)
    _expect(left.disabled and correct.disabled, "retry can complete the correct pair")
    puzzle.free()
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `tests/run_chapter_2_image_matching_tests.sh`

Expected: FAIL because wrong cards are not disabled during feedback, `_feedback_active` does not exist, and the old implementation uses a single red tint rather than three border flashes.

- [ ] **Step 3: Implement the feedback lock and three flashes**

Add:

```gdscript
const WRONG_FLASH_COUNT := 3
const WRONG_FLASH_INTERVAL := 0.10

var _feedback_active := false
```

Reset `_feedback_active = false` in `open()`. Guard both press handlers with `_feedback_active`. In the wrong branch, clear the selected references, then await:

```gdscript
await _flash_wrong_pair(wrong_left, btn)
```

Implement:

```gdscript
func _flash_wrong_pair(left: Button, right: Button) -> void:
    _feedback_active = true
    left.disabled = true
    right.disabled = true
    for flash_index in WRONG_FLASH_COUNT:
        _set_border(left, WRONG_BORDER_COLOR)
        _set_border(right, WRONG_BORDER_COLOR)
        await get_tree().create_timer(WRONG_FLASH_INTERVAL).timeout
        _set_border(left, NEUTRAL_BORDER_COLOR, 2)
        _set_border(right, NEUTRAL_BORDER_COLOR, 2)
        if flash_index < WRONG_FLASH_COUNT - 1:
            await get_tree().create_timer(WRONG_FLASH_INTERVAL).timeout
    if is_instance_valid(left):
        left.disabled = false
    if is_instance_valid(right):
        right.disabled = false
    _feedback_active = false
```

Retain `AudioManager.ANSWER_WRONG` at the start of the wrong branch and remove the old `modulate` feedback.

- [ ] **Step 4: Run focused and audio suites and verify GREEN**

Run: `tests/run_chapter_2_image_matching_tests.sh && tests/run_puzzle_audio_tests.sh`

Expected: Both suites PASS; wrong-answer audio remains `answer_wrong`, and the focused suite confirms cards can be retried.

- [ ] **Step 5: Commit Task 4**

```bash
git add scenes/ui/matching_puzzle.gd tests/test_chapter_2_image_matching_runtime.gd
git commit -m "feat: flash wrong matching borders"
```

---

### Task 5: Completion Regression and Visual Verification

**Files:**
- Modify: `tests/test_chapter_2_image_matching_runtime.gd`
- Verify: `scenes/ui/matching_puzzle.gd`
- Verify: `scenes/ui/matching_puzzle.tscn`
- Verify: `scenes/chapter_2/chapter_2.gd`

**Interfaces:**
- Consumes: Final puzzle implementation from Tasks 1-4.
- Produces: Regression coverage for `solved`, audio events, pause restoration, and a visually verified Chapter 2 modal.

- [ ] **Step 1: Add a failing completion regression test**

Add audio capture near the top of the test file:

```gdscript
var _events: Array[StringName] = []
```

At the start of `_run()`, connect the existing test hook, then call the test:

```gdscript
root.get_node("AudioManager").sfx_played.connect(func(key: StringName): _events.append(key))
await _test_completion_preserves_signal_audio_and_pause()
```

Add:

```gdscript
func _test_completion_preserves_signal_audio_and_pause() -> void:
    var puzzle := _spawn_puzzle()
    var solved_state := {"count": 0}
    puzzle.solved.connect(func(): solved_state.count += 1)
    puzzle.open("Match", [["L1", "R1"]])
    var left := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
    var right := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn").get_child(0) as Button
    _events.clear()
    puzzle._on_left_pressed(left, 0)
    await puzzle._on_right_pressed(right, 0)
    _expect(_events == [&"answer_correct"], "completion keeps correct-answer audio")
    _expect(solved_state.count == 1, "completion emits solved once")
    _expect(not paused, "completion unpauses the scene tree")
    _expect(not puzzle.visible, "completion hides the puzzle")
    puzzle.free()
```

- [ ] **Step 2: Temporarily break one completion assertion and verify the test detects it**

Change the expected solved count to `2`, run `tests/run_chapter_2_image_matching_tests.sh`, and confirm it FAILS with `completion emits solved once`. Restore the assertion to `solved_state.count == 1` before continuing. This mutation proves the regression assertion is live even if the implementation already satisfies the behavior.

- [ ] **Step 3: Run all relevant automated verification**

Run:

```bash
tests/run_chapter_2_image_matching_tests.sh
tests/run_puzzle_audio_tests.sh
tests/run_chapter_quest_flow_tests.sh
git diff --check
```

Expected: All three suites PASS, `git diff --check` emits no output, and no test log contains `SCRIPT ERROR` or `ERROR:`.

- [ ] **Step 4: Visually inspect the puzzle at the supported viewport**

Run the Chapter 2 scene in Godot, trigger the ashram puzzle, and verify all of the following at the project viewport:

- Four images are fully recognizable and contain no captions.
- Right-side Thai descriptions do not clip or overflow.
- Gold selection and orange/yellow/blue/green correct borders are visible against the brown cards.
- A wrong pair visibly flashes a red border three times and then accepts another answer.
- The modal remains inside the screen at the project's full-screen stretch settings.

If visual sizing fails, adjust only `custom_minimum_size`, `icon_max_width`, panel offsets, or container spacing; rerun all Task 5 commands afterward.

- [ ] **Step 5: Commit the final test and any verified layout adjustment**

```bash
git add tests/test_chapter_2_image_matching_runtime.gd scenes/ui/matching_puzzle.gd scenes/ui/matching_puzzle.tscn
git commit -m "test: cover chapter 2 image matching flow"
```

Do not create an empty commit if no files changed in this task.

---

## Final Verification

- [ ] Run `git status --short` and confirm the only remaining unrelated change is the user's pre-existing `scenes/chapter_9/chapter_9.tscn` modification.
- [ ] Run `git log -6 --oneline` and confirm each implementation task has an auditable commit.
- [ ] Review the final diff from the design-spec commit through `HEAD` for accidental captions, green text success styling, asset/path mistakes, or unrelated Chapter 9 changes.
- [ ] Invoke `superpowers:verification-before-completion` before reporting success.
- [ ] Invoke `superpowers:requesting-code-review` for a final requirements and quality review before handoff.
