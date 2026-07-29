# Chapter 6 Left-Tower Chest Puzzle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a three-question Thai chest puzzle to the Chapter 6 left tower that unlocks a persistent, collectible bar-shaped key fragment.

**Architecture:** A dedicated paused-mode `CanvasLayer` owns the chest presentation, fixed questions, lock indicators, and feedback animations. The left-room controller owns world interaction, persistent unlock state, pickup restoration, and inventory collection; a small shared helper centralizes Chapter 6 key-fragment quest progress for both the main map and tower rooms.

**Tech Stack:** Godot 4.7.1, GDScript, `.tscn` scenes, shell contract tests, headless Godot runtime tests.

**Revision:** Tasks 5–6 supersede the retry and cancel behavior described in
Task 2. Tasks 7–8 supersede the cancel-button placement and slot bounds from
Task 5. Tasks 9–10 supersede only the slot bounds from Task 7 after calibration
against the captured gameplay image. Tasks 1–8 describe the verified baseline
already present in the working tree.

## Global Constraints

- Use `res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_07_11.png` as the large chest image.
- Use `lanka_key_fragment_bar` and its registered texture `res://assets/ui/icon/split/image-removebg-preview สำเนา.png` as the left-room reward.
- Preserve all existing `Walls` nodes in `chapter_6_room_left.tscn`; the protected section hash is `8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37`.
- Preserve all unrelated dirty-worktree changes and untracked user assets.
- Do not implement the right-room puzzle, fragment combination, or Lanka gate unlock.
- Do not create duplicate fragment inventory entries or world pickups.
- Because target files already contain user-owned uncommitted edits, do not stage or commit implementation files without a fresh explicit user instruction. Use test-green checkpoints in place of automatic implementation commits.

---

## File Structure

### Create

- `scenes/chapter_6/chapter_6_key_quest.gd` — shared IDs, quest text, progress calculation, and Quest refresh.
- `scenes/chapter_6/chapter_6_left_chest_puzzle.gd` — modal puzzle state and animations.
- `scenes/chapter_6/chapter_6_left_chest_puzzle.tscn` — dim overlay, chest image, lock slots, instruction, question, and buttons.
- `scenes/chapter_6/chapter_6_room_left.gd` — locked-chest interaction, state restoration, reward spawning, and collection.
- `tests/test_chapter_6_left_chest_state.sh` — static persistence and scene-contract checks.
- `tests/test_chapter_6_left_chest_puzzle_runtime.gd` — fixed questions and visual feedback runtime test.
- `tests/test_chapter_6_left_chest_puzzle_runtime.sh` — headless runner.
- `tests/test_chapter_6_left_chest_flow_runtime.gd` — room interaction, restoration, collection, and quest integration test.
- `tests/test_chapter_6_left_chest_flow_runtime.sh` — headless runner.

### Modify

- `scenes/chapter_6/chapter_6.gd` — consume the shared quest helper without changing Yak behavior.
- `scenes/chapter_6/chapter_6_room_left.tscn` — attach controller and add only interaction/UI nodes outside `Walls`.
- `scenes/core/game_state.gd` — add `chapter_6_left_chest_unlocked`.
- `scenes/core/save_game.gd` — save/load the chest unlock flag.
- `scenes/homepage/home_page.gd` — reset the flag for a new story.
- `tests/test_inventory_save_runtime.gd` — exercise chest unlock persistence.
- `tests/test_chapter_6_key_fragment_quest_runtime.gd` — verify shared helper preserves Yak quest behavior.

---

### Task 1: Shared Quest Rules and Persistent Chest State

**Files:**

- Create: `scenes/chapter_6/chapter_6_key_quest.gd`
- Create: `tests/test_chapter_6_left_chest_state.sh`
- Modify: `scenes/chapter_6/chapter_6.gd`
- Modify: `scenes/core/game_state.gd`
- Modify: `scenes/core/save_game.gd`
- Modify: `scenes/homepage/home_page.gd`
- Modify: `tests/test_inventory_save_runtime.gd`
- Modify: `tests/test_chapter_6_key_fragment_quest_runtime.gd`

**Interfaces:**

- Produces: `Chapter6KeyQuest.progress(tree: SceneTree) -> int`
- Produces: `Chapter6KeyQuest.refresh(tree: SceneTree) -> int`
- Produces: `GameState.chapter_6_left_chest_unlocked: bool`
- Consumes: `/root/Inv.count(item_id)` and `/root/Quest.set_quest(name, detail)`

- [ ] **Step 1: Write the failing state contract**

Create `tests/test_chapter_6_left_chest_state.sh`:

```sh
#!/bin/sh
set -eu

state="scenes/core/game_state.gd"
save="scenes/core/save_game.gd"
home="scenes/homepage/home_page.gd"
helper="scenes/chapter_6/chapter_6_key_quest.gd"
chapter="scenes/chapter_6/chapter_6.gd"

test -f "$helper"
grep -Fq 'static var chapter_6_left_chest_unlocked := false' "$state"
grep -Fq '"chapter_6_left_chest_unlocked"' "$save"
grep -Fq 'GameState.chapter_6_left_chest_unlocked = false' "$home"
grep -Fq 'const BAR_FRAGMENT_ID := "lanka_key_fragment_bar"' "$helper"
grep -Fq 'const RING_FRAGMENT_ID := "lanka_key_fragment_ring"' "$helper"
grep -Fq 'static func progress(tree: SceneTree) -> int:' "$helper"
grep -Fq 'static func refresh(tree: SceneTree) -> int:' "$helper"
grep -Fq 'Chapter6KeyQuest.refresh(get_tree())' "$chapter"

echo "Chapter 6 left chest state contract passed"
```

- [ ] **Step 2: Extend the save runtime test before implementation**

In `tests/test_inventory_save_runtime.gd`, set the flag before saving, assert
the serialized key is true, reset it before loading, assert load restores it,
and reset it during cleanup:

```gdscript
GameState.chapter_6_left_chest_unlocked = true
SaveGame.save_to_slot(2)
if not bool(saved.get("chapter_6_left_chest_unlocked", false)):
	_cleanup_and_fail("Save data omitted Chapter 6 left chest state")
	return

GameState.chapter_6_left_chest_unlocked = false
SaveGame.load_slot(2)
if not GameState.chapter_6_left_chest_unlocked:
	_cleanup_and_fail("Loading did not restore Chapter 6 left chest state")
	return
```

- [ ] **Step 3: Run the tests to verify RED**

Run:

```bash
bash tests/test_chapter_6_left_chest_state.sh
bash tests/test_inventory_save_and_ending.sh
```

Expected: the state contract fails because the helper and flag do not exist;
the runtime test fails because SaveGame omits the new flag.

- [ ] **Step 4: Implement the shared helper**

Create `scenes/chapter_6/chapter_6_key_quest.gd`:

```gdscript
extends RefCounted

const SHAFT_FRAGMENT_ID := "lanka_key_fragment_shaft"
const BAR_FRAGMENT_ID := "lanka_key_fragment_bar"
const RING_FRAGMENT_ID := "lanka_key_fragment_ring"
const FRAGMENT_IDS := [SHAFT_FRAGMENT_ID, BAR_FRAGMENT_ID, RING_FRAGMENT_ID]
const QUEST_NAME := "ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง"
const QUEST_DETAIL := "รวบรวมชิ้นส่วนกุญแจ %d/3"


static func progress(tree: SceneTree) -> int:
	var inventory := tree.root.get_node_or_null("Inv")
	if inventory == null:
		return 0
	var total := 0
	for item_id: String in FRAGMENT_IDS:
		total += mini(int(inventory.count(item_id)), 1)
	return total


static func refresh(tree: SceneTree) -> int:
	var total := progress(tree)
	var quest := tree.root.get_node_or_null("Quest")
	if quest != null:
		quest.set_quest(QUEST_NAME, QUEST_DETAIL % total)
		quest.set_completed(total >= FRAGMENT_IDS.size())
	return total
```

- [ ] **Step 5: Add the persistent flag and resets**

Add to `scenes/core/game_state.gd`:

```gdscript
static var chapter_6_left_chest_unlocked := false
```

Add `"chapter_6_left_chest_unlocked"` to `SaveGame.STATE_KEYS`. Add to the
new-story reset in `scenes/homepage/home_page.gd`:

```gdscript
GameState.chapter_6_left_chest_unlocked = false
```

- [ ] **Step 6: Refactor only quest calculation in the main controller**

Preload the helper in `scenes/chapter_6/chapter_6.gd`:

```gdscript
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
```

Keep the existing local fragment constants used by Yak spawning, but replace
the body of `_refresh_quest()` with:

```gdscript
func _refresh_quest() -> void:
	if _quest_started:
		Chapter6KeyQuest.refresh(get_tree())
```

- [ ] **Step 7: Run focused tests to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_left_chest_state.sh
bash tests/test_inventory_save_and_ending.sh
bash tests/test_chapter_6_key_fragment_quest_runtime.sh
```

Expected: all three exit 0, Yak drop and `0/3`→`1/3` behavior remains intact.

- [ ] **Step 8: Record the green checkpoint**

Run `git diff --check` and record the passing commands in the implementation
handoff. Do not stage the dirty target files.

---

### Task 2: Dedicated Chest Puzzle Modal

**Files:**

- Create: `scenes/chapter_6/chapter_6_left_chest_puzzle.gd`
- Create: `scenes/chapter_6/chapter_6_left_chest_puzzle.tscn`
- Create: `tests/test_chapter_6_left_chest_puzzle_runtime.gd`
- Create: `tests/test_chapter_6_left_chest_puzzle_runtime.sh`

**Interfaces:**

- Produces: signal `solved`
- Produces: `open() -> void`
- Produces: `begin_questions() -> void`
- Produces: `_on_choice_pressed(index: int) -> void`
- Produces: read-only test state through `_question_index`, `_feedback_locked`,
  and scene nodes `Dim/ChestPanel/Slots`, `Instruction`, `QuestionPanel`

- [ ] **Step 1: Write the runtime test**

The test must:

1. Instantiate the puzzle scene and add it to the root.
2. Call `open()`, await `0.35` seconds, and assert the tree is paused, the dim
   overlay is visible, the chest texture exists, and instruction text matches.
3. Send a pressed E event through `_input()` and verify question 1 and its
   three exact choices. Reopen a fresh instance and verify a left mouse click
   performs the same instruction-to-question transition.
4. Press wrong index `0`, assert `_feedback_locked`, await `1.05` seconds, and
   verify `_question_index == 0`.
5. Press correct index `1`, assert slot 1 is green and question 2 appears.
6. Press correct index `0`, assert slot 2 is green and question 3 appears.
7. Press correct index `1`, await `0.35` seconds, and assert one `solved`
   emission, hidden UI, and an unpaused tree.

Use these constants in `tests/test_chapter_6_left_chest_puzzle_runtime.gd`:

```gdscript
const QUESTIONS := [
	[
		"ใจความสำคัญของข้อความ “ต้นไม้ให้ร่มเงา ช่วยฟอกอากาศ และเป็นที่อยู่อาศัยของสัตว์” คือข้อใด",
		["ต้นไม้มีสีเขียว", "ต้นไม้มีประโยชน์หลายอย่าง", "สัตว์ชอบอาศัยบนต้นไม้"],
		1,
	],
	[
		"ข้อใดเป็นประโยคที่มีความหมายโดยนัย",
		["พ่อเป็นเสาหลักของครอบครัว", "บ้านหลังนี้มีเสาสี่ต้น", "ช่างกำลังซ่อมเสาไม้"],
		0,
	],
	[
		"ข้อใดใช้คำราชาศัพท์ได้ถูกต้อง",
		["พระมหากษัตริย์กินอาหาร", "พระมหากษัตริย์เสวยพระกระยาหาร", "พระมหากษัตริย์ทานข้าว"],
		1,
	],
]
```

- [ ] **Step 2: Write the shell runner and verify RED**

Create `tests/test_chapter_6_left_chest_puzzle_runtime.sh`:

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-left-chest-ui}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_left_chest_puzzle_runtime.gd
```

Run it and expect failure because the puzzle scene does not exist.

- [ ] **Step 3: Create the modal scene**

Create `chapter_6_left_chest_puzzle.tscn` with this hierarchy:

```text
LeftChestPuzzle (CanvasLayer, layer 80, process always)
└── Dim (ColorRect, full rect, #000000B8)
    ├── ChestPanel (Control, centered, 720×720)
    │   ├── ChestImage (TextureRect, keep aspect centered)
    │   └── Slots (Control)
    │       ├── Slot1 (ColorRect)
    │       ├── Slot2 (ColorRect)
    │       └── Slot3 (ColorRect)
    ├── Instruction (PanelContainer)
    │   └── Label
    └── QuestionPanel (PanelContainer)
        └── Margin/VBox
            ├── QuestionLabel
            └── Choices (VBoxContainer)
```

Use the Sarabun fonts already present in `assets/fonts/`. Give each slot a
dark neutral color with a gold border. Inside the 720×720 ChestPanel, use
100×82 slot rectangles with top offset `365`; use left offsets `190`, `310`,
and `430` so they align with the chest windows. Set `Dim.modulate.a = 0.0`
initially and hide the CanvasLayer.

- [ ] **Step 4: Implement fixed-question behavior**

In `chapter_6_left_chest_puzzle.gd`:

```gdscript
extends CanvasLayer

signal solved

const QUESTIONS := [
	{
		"question": "ใจความสำคัญของข้อความ “ต้นไม้ให้ร่มเงา ช่วยฟอกอากาศ และเป็นที่อยู่อาศัยของสัตว์” คือข้อใด",
		"choices": ["ต้นไม้มีสีเขียว", "ต้นไม้มีประโยชน์หลายอย่าง", "สัตว์ชอบอาศัยบนต้นไม้"],
		"correct_index": 1,
	},
	{
		"question": "ข้อใดเป็นประโยคที่มีความหมายโดยนัย",
		"choices": ["พ่อเป็นเสาหลักของครอบครัว", "บ้านหลังนี้มีเสาสี่ต้น", "ช่างกำลังซ่อมเสาไม้"],
		"correct_index": 0,
	},
	{
		"question": "ข้อใดใช้คำราชาศัพท์ได้ถูกต้อง",
		"choices": ["พระมหากษัตริย์กินอาหาร", "พระมหากษัตริย์เสวยพระกระยาหาร", "พระมหากษัตริย์ทานข้าว"],
		"correct_index": 1,
	},
]

const NEUTRAL := Color("#241a14")
const CORRECT := Color("#36c75b")
const WRONG := Color("#e33a35")

var _question_index := 0
var _feedback_locked := false
var _solved_emitted := false
```

`open()` resets all three slots, shows instruction, hides question controls,
pauses the tree, shows the layer, and tweens `Dim.modulate.a` to `1.0` over
`0.25` seconds.

`begin_questions()` ignores calls while feedback is locked, swaps instruction
for the question panel, and calls `_show_question()`.

`_show_question()` rebuilds three buttons using the current fixed data and
connects each button to `_on_choice_pressed(index)`.

While the instruction is visible, `_input(event)` calls `begin_questions()`
for either a pressed, non-echo E key or a pressed left mouse button. It marks
the viewport input handled. All other input is ignored.

- [ ] **Step 5: Implement feedback and completion**

For wrong answers:

```gdscript
_feedback_locked = true
_set_buttons_disabled(true)
var slot := _slot_at(_question_index)
slot.color = WRONG
var tween := create_tween()
for cycle: int in range(4):
	tween.tween_property(slot, "modulate:a", 0.25, 0.1)
	tween.tween_property(slot, "modulate:a", 1.0, 0.1)
await get_tree().create_timer(1.0, true).timeout
slot.color = NEUTRAL
slot.modulate.a = 1.0
_feedback_locked = false
_show_question()
```

For correct answers, set the current slot to `CORRECT`, increment
`_question_index`, then either show the next question or guard and emit one
`solved` signal after a `0.25`-second fade. Unpause the tree immediately before
hiding the completed UI.

- [ ] **Step 6: Run the UI test to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
```

Expected: exit 0 and `Chapter 6 left chest puzzle runtime passed`.

- [ ] **Step 7: Record the green checkpoint**

Run `git diff --check`. Do not stage files.

---

### Task 3: Left-Room Interaction, Reward, and Restoration

**Files:**

- Create: `scenes/chapter_6/chapter_6_room_left.gd`
- Create: `tests/test_chapter_6_left_chest_flow_runtime.gd`
- Create: `tests/test_chapter_6_left_chest_flow_runtime.sh`
- Modify: `scenes/chapter_6/chapter_6_room_left.tscn`

**Interfaces:**

- Consumes: `LeftChestPuzzle.open()`, signal `solved`
- Consumes: `KeyFragmentPickup.configure(item_id, texture, prompt)`
- Consumes: `Chapter6KeyQuest.refresh(tree) -> int`
- Produces: deterministic nodes `ChestInteraction`, `ChestPrompt`,
  `LeftChestPuzzle`, and `YSortRoot/LeftChestKeyFragment`

- [ ] **Step 1: Record the protected wall hash**

Run:

```bash
awk '/^\[node name="Walls"/{capture=1} /^\[node name="YSortRoot"/{capture=0} capture' \
  scenes/chapter_6/chapter_6_room_left.tscn | shasum -a 256
```

Expected:

```text
8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
```

- [ ] **Step 2: Write the room-flow runtime test**

The test must reset inventory and chest state, load the left room, and verify:

1. `ChestInteraction` is active while locked.
2. Calling the body-enter handler with the real Player shows
   `กด E เพื่อปลดล็อกกล่อง`.
3. An E event opens `LeftChestPuzzle`.
4. Calling the three correct choice indices `[1, 0, 1]` unlocks the chest.
5. One pickup named `YSortRoot/LeftChestKeyFragment` exists at
   `Vector2(315, 365)` and the bar inventory count is still zero.
6. Freeing and reloading the room removes locked interaction and restores one
   pickup.
7. Moving Player into the pickup and pressing E adds exactly one bar, removes
   the pickup, and refreshes the quest to the inventory-derived progress.
8. Reloading again creates neither interaction nor pickup.

- [ ] **Step 3: Create the runner and verify RED**

Use test home `/private/tmp/codex-godot-chapter-6-left-chest-flow`, run the
runtime script headlessly, and expect failure because the room has no
controller or chest nodes.

- [ ] **Step 4: Add only non-wall scene nodes**

Attach `chapter_6_room_left.gd` to the root. Add:

```text
ChestInteraction (Area2D, position 315,430, collision mask 2)
├── CollisionShape2D (CircleShape2D radius 105)
└── ChestPrompt (Label, initially hidden)
LeftChestPuzzle (instance of chapter_6_left_chest_puzzle.tscn)
```

Keep these nodes outside the `Walls` section and do not edit any existing
collision resource or collision node.

- [ ] **Step 5: Implement controller restoration**

Use constants:

```gdscript
const GameState := preload("res://scenes/core/game_state.gd")
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
const KEY_FRAGMENT_PICKUP := preload("res://scenes/props/key_fragment_pickup.tscn")
const BAR_TEXTURE := preload("res://assets/ui/icon/split/image-removebg-preview สำเนา.png")
const BAR_ID := "lanka_key_fragment_bar"
const PICKUP_POSITION := Vector2(315, 365)
```

In `_ready()`, connect interaction body signals and `solved`. If inventory
already contains the bar, set the unlocked flag true. Then:

```gdscript
if GameState.chapter_6_left_chest_unlocked:
	_disable_chest_interaction()
	if _bar_count() == 0:
		call_deferred("_spawn_fragment")
else:
	_enable_chest_interaction()
```

Use these exact proximity handlers:

```gdscript
func _on_chest_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not GameState.chapter_6_left_chest_unlocked:
		_player_near = true
		$ChestInteraction/ChestPrompt.show()


func _on_chest_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_near = false
		$ChestInteraction/ChestPrompt.hide()
```

Call `Chapter6KeyQuest.refresh(get_tree())` when
`GameState.chapter_6_intro_played` is true so the quest remains current inside
the room.

- [ ] **Step 6: Implement E interaction and solved flow**

Track `_player_near` and `_opening`. Accept only a pressed, non-echo E event
while locked and near:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or _opening or GameState.chapter_6_left_chest_unlocked:
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_opening = true
		$ChestInteraction/ChestPrompt.hide()
		$LeftChestPuzzle.open()
		get_viewport().set_input_as_handled()
```

On `solved`, set the persistent flag, disable interaction, spawn the reward,
and clear `_opening`.

- [ ] **Step 7: Implement one-shot reward spawn and collection**

Instantiate the existing pickup as `LeftChestKeyFragment`, configure it with
`BAR_ID`, `BAR_TEXTURE`, and the standard Thai prompt, add it to `YSortRoot`,
and set its global position to `PICKUP_POSITION`.

On collection:

```gdscript
if _bar_count() == 0:
	_inventory().add_item(BAR_ID)
	Chapter6KeyQuest.refresh(get_tree())
pickup.queue_free()
```

- [ ] **Step 8: Run focused tests to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_left_chest_flow_runtime.sh
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
bash tests/test_chapter_6_key_fragment_quest_runtime.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected: all exit 0.

- [ ] **Step 9: Prove the wall section is unchanged**

Re-run the hash command from Step 1 and require the exact same hash:

```text
8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
```

- [ ] **Step 10: Record the green checkpoint**

Run `git diff --check`. Do not stage the dirty room scene.

---

### Task 4: Full Regression and Delivery Verification

**Files:**

- Test: all `tests/*.sh`
- Verify: all modified and created files above

**Interfaces:**

- Consumes the completed state, UI, room flow, and shared quest helper.
- Produces fresh verification evidence for delivery.

- [ ] **Step 1: Run every shell test**

```bash
set -eu
for test_file in tests/*.sh
do
  echo "RUN $test_file"
  bash "$test_file"
done
```

Expected: loop exits 0. Note the known macOS certificate warning and the
existing `Inv` warning in the standalone tower playtest separately; require
the Godot editor parse in Step 2 to be clean.

- [ ] **Step 2: Parse the complete project in Godot**

```bash
HOME=/private/tmp/codex-godot-editor-left-chest \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

Expected: exit 0 with no GDScript parse or compile error.

- [ ] **Step 3: Verify formatting and both protected room-wall hashes**

```bash
git diff --check
awk '/^\[node name="Walls"/{capture=1} /^\[node name="YSortRoot"/{capture=0} capture' \
  scenes/chapter_6/chapter_6_room_left.tscn | shasum -a 256
awk '/^\[node name="Walls"/{capture=1} /^\[node name="YSortRoot"/{capture=0} capture' \
  scenes/chapter_6/chapter_6_room_right.tscn | shasum -a 256
```

Expected hashes:

```text
left  8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
right 85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e
```

- [ ] **Step 4: Review scope**

Use `git status --short` and `git diff --stat`. Confirm that:

- all pre-existing dirty files and user assets remain present;
- no right-room puzzle or gate-unlock behavior was added;
- no implementation file was staged or committed automatically; and
- the design-spec commit `0dd3ca1` remains intact.

- [ ] **Step 5: Deliver results**

Report the exact focused/full test commands, parse result, wall hashes, known
non-blocking warnings, changed files, and manual playtest path:

1. Start Chapter 6 and finish/skip the intro.
2. Enter the left tower.
3. Approach the left chest and press E.
4. Intentionally choose one wrong answer and observe the one-second red flash.
5. Answer all three correctly.
6. Collect the floating bar fragment with E.
7. Return to the main map and confirm updated `X/3` quest progress.

---

### Task 5: Revised Retry, Shuffle, Cancel, and Slot Alignment

**Files:**

- Modify: `tests/test_chapter_6_left_chest_puzzle_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.gd`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.tscn`
- Modify: `scenes/chapter_6/chapter_6_room_left.gd`

**Interfaces:**

- Produces: signal `cancelled`
- Produces: `cancel() -> void`
- Produces: `_reset_attempt(shuffle_choices: bool) -> void`
- Produces: per-question `_choice_orders: Array[Array]`
- Consumes: `cancelled` in `chapter_6_room_left.gd::_on_chest_puzzle_cancelled()`

- [ ] **Step 1: Extend the runtime test before production changes**

Update the puzzle runtime test to verify these observable behaviors:

1. `Dim/Instruction/StartHint.text == "กด E เพื่อเริ่ม"`.
2. After answering question 1 correctly, a wrong answer on question 2 flashes
   slot 2, then resets `_question_index` to `0` and all three slots to neutral.
3. Capture all three button texts before the wrong answer. After the flash,
   require at least question 1's display order to differ while still locating
   the correct answer by its text.
4. Answer question 1 using the shuffled button containing
   `ต้นไม้มีประโยชน์หลายอย่าง` and verify it advances.
5. Press Esc on a fresh open attempt and assert one `cancelled` signal,
   hidden UI, neutral progress, and `SceneTree.paused == false`.
6. Reopen and press `Dim/QuestionPanel/Margin/VBox/CancelButton`; assert a
   second cancel with the same cleanup.
7. During `_feedback_locked`, send Esc and assert the modal remains visible
   and paused.
8. For each slot, assert its anchors and offsets keep it within these
   normalized artwork-frame bounds:

```gdscript
const SLOT_BOUNDS := [
	Rect2(0.265, 0.505, 0.155, 0.145),
	Rect2(0.423, 0.505, 0.155, 0.145),
	Rect2(0.608, 0.505, 0.155, 0.145),
]
```

The production mutations caught are: retrying the current question instead of
question 1, retaining green slots, failing to shuffle, checking the shuffled
button index instead of answer identity, leaving the tree paused on cancel,
and returning to fixed pixel slot placement.

- [ ] **Step 2: Run the runtime test to verify RED**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
```

Expected: failure at the missing `StartHint`, `cancelled` signal, or reset/
shuffle assertion.

- [ ] **Step 3: Add the start hint and cancel button**

In `chapter_6_left_chest_puzzle.tscn`:

- change `Instruction` to contain a `VBoxContainer`;
- keep the existing instruction label;
- add `StartHint` with text `กด E เพื่อเริ่ม`, centered, Sarabun Bold 20;
- add `CancelButton` after `Choices`, text `ยกเลิก`, minimum height 42; and
- connect its `pressed` signal to `_on_cancel_pressed`.

Do not change the chest image or modal size.

- [ ] **Step 4: Replace fixed slots with normalized artwork anchors**

For each `ColorRect`, set anchors relative to the 720×720 `Slots` control and
zero offsets:

```text
Slot1: left .265, top .505, right .420, bottom .650
Slot2: left .423, top .505, right .578, bottom .650
Slot3: left .608, top .505, right .763, bottom .650
```

This makes each indicator taller, keeps it inside the gold frame, and scales
with the chest image.

- [ ] **Step 5: Store choice identity independently of display position**

Add:

```gdscript
signal cancelled

var _choice_orders: Array[Array] = []
var _cancel_emitted := false
```

Reset authored order on `open()`:

```gdscript
func _reset_attempt(shuffle_choices: bool) -> void:
	_question_index = 0
	for slot: ColorRect in _slots:
		slot.color = NEUTRAL
		slot.modulate = Color.WHITE
	_choice_orders.clear()
	for data: Dictionary in QUESTIONS:
		var order: Array = range(data["choices"].size())
		if shuffle_choices:
			order.shuffle()
			if order == range(data["choices"].size()):
				var first: Variant = order.pop_front()
				order.push_back(first)
		_choice_orders.append(order)
```

When creating a displayed button, bind its original choice index:

```gdscript
for original_index: int in _choice_orders[_question_index]:
	var button := Button.new()
	button.text = data["choices"][original_index]
	button.pressed.connect(_on_choice_pressed.bind(original_index))
```

`_on_choice_pressed(original_index)` continues comparing against
`data["correct_index"]`, so shuffling does not alter correctness.

- [ ] **Step 6: Reset to question 1 after wrong feedback**

Keep the current one-second red flash. After it finishes:

```gdscript
_reset_attempt(true)
_feedback_locked = false
_show_question()
```

Do not preserve any green slot from the failed attempt.

- [ ] **Step 7: Implement safe button/Esc cancellation**

Add:

```gdscript
func _on_cancel_pressed() -> void:
	cancel()


func cancel() -> void:
	if not visible or _feedback_locked or _cancel_emitted:
		return
	_cancel_emitted = true
	_feedback_locked = true
	var fade := create_tween()
	fade.tween_property(_dim, "modulate:a", 0.0, 0.2)
	await fade.finished
	get_tree().paused = false
	hide()
	_reset_attempt(false)
	cancelled.emit()
```

In `_input(event)`, process Esc before the instruction-only early return:

```gdscript
if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
	cancel()
	get_viewport().set_input_as_handled()
	return
```

Reset `_cancel_emitted = false` in `open()`. Cancel remains ignored during the
wrong-answer flash because `_feedback_locked` is true.

- [ ] **Step 8: Restore room interaction after cancellation**

Connect `_puzzle.cancelled` in `chapter_6_room_left.gd::_ready()`. Implement:

```gdscript
func _on_chest_puzzle_cancelled() -> void:
	_opening = false
	if _player_near and not GameState.chapter_6_left_chest_unlocked:
		_prompt.show()
```

No GameState, inventory, pickup, or quest value changes on cancel.

- [ ] **Step 9: Run focused tests to verify GREEN**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
bash tests/test_chapter_6_left_chest_flow_runtime.sh
```

Expected: both exit 0. The puzzle test proves reset/shuffle/cancel/alignment;
the room test proves the chest reward flow remains intact.

- [ ] **Step 10: Record the green checkpoint**

Run `git diff --check`. Do not stage implementation files.

---

### Task 6: Revised Full Verification

**Files:**

- Test: all `tests/*.sh`
- Verify: puzzle script/scene, left-room controller, and protected rooms

**Interfaces:**

- Consumes the revised modal and existing room flow.
- Produces fresh delivery evidence.

- [ ] **Step 1: Run the full test suite**

```bash
set -eu
for test_file in tests/*.sh
do
  echo "RUN $test_file"
  bash "$test_file"
done
```

Expected: exit 0.

- [ ] **Step 2: Parse the project**

```bash
HOME=/private/tmp/codex-godot-editor-left-chest-revision \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

Expected: exit 0 with no GDScript parse or compile error.

- [ ] **Step 3: Verify diff and protected hashes**

```bash
git diff --check
awk '/^\[node name="Walls"/{capture=1} /^\[node name="YSortRoot"/{capture=0} capture' \
  scenes/chapter_6/chapter_6_room_left.tscn | shasum -a 256
awk '/^\[node name="Walls"/{capture=1} /^\[node name="YSortRoot"/{capture=0} capture' \
  scenes/chapter_6/chapter_6_room_right.tscn | shasum -a 256
```

Require:

```text
left  8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
right 85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e
```

- [ ] **Step 4: Manual playtest checklist**

1. Open the locked chest and verify `กด E เพื่อเริ่ม`.
2. Start, solve question 1, then answer question 2 incorrectly.
3. Verify red flashing, all neutral slots, question 1, and reordered answers.
4. Press Esc and verify immediate return to the same room position.
5. Reopen, use the on-screen cancel button, and verify the same cleanup.
6. Reopen and solve all questions to verify fragment reward behavior is
   unchanged.

---

### Task 7: Upper-Left Cancel Button and Inner Slot Bounds

**Files:**

- Modify: `tests/test_chapter_6_left_chest_puzzle_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.tscn`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.gd`

**Interfaces:**

- Preserves: `cancel() -> void`, `cancelled`, and Esc cancellation behavior.
- Changes: cancel-button node path from
  `Dim/QuestionPanel/Margin/VBox/CancelButton` to `Dim/CancelButton`.
- Produces: three normalized color rectangles fully inside the artwork's gold
  slot frames.

- [ ] **Step 1: Tighten the runtime layout assertions**

Change the test's cancel-button lookup to:

```gdscript
var cancel_button: Button = puzzle.get_node("Dim/CancelButton")
```

Assert that it is a direct child of `Dim`, uses top-left anchors, and has a
24-pixel margin:

```gdscript
if cancel_button.anchor_left != 0.0 or cancel_button.anchor_top != 0.0:
	_fail("Cancel button is not anchored to the upper-left viewport corner")
	return
if cancel_button.offset_left != 24.0 or cancel_button.offset_top != 24.0:
	_fail("Cancel button does not keep the required 24-pixel margin")
	return
```

Replace the slot expectations with the measured inner bounds:

```gdscript
var expected := [
	Vector4(0.274, 0.527, 0.386, 0.616),
	Vector4(0.444, 0.527, 0.556, 0.616),
	Vector4(0.630, 0.527, 0.742, 0.616),
]
```

- [ ] **Step 2: Run the focused test and verify RED**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
```

Expected: FAIL because the button still lives inside the lower question panel
or because the current slot anchors extend beyond the new inner bounds.

- [ ] **Step 3: Move the cancel button to the upper-left**

Remove `CancelButton` from `Dim/QuestionPanel/Margin/VBox` and add it as:

```text
[node name="CancelButton" type="Button" parent="Dim"]
layout_mode = 0
offset_left = 24.0
offset_top = 24.0
offset_right = 224.0
offset_bottom = 74.0
theme_override_fonts/font = ExtResource("3_bold")
theme_override_font_sizes/font_size = 18
text = "ยกเลิก (Esc)"
```

The button remains visible only while the puzzle CanvasLayer is visible. It
must not be placed inside the question panel.

- [ ] **Step 4: Update the script node path**

Change only the on-ready path:

```gdscript
@onready var _cancel_button: Button = $Dim/CancelButton
```

Do not change `cancel()`, Esc handling, feedback locking, room restoration, or
the `cancelled` signal.

- [ ] **Step 5: Put all color rectangles inside the gold frames**

Set the `ColorRect` anchors in the chest scene to these exact bounds, keeping
all offsets at zero:

```text
Slot1: left .274, top .527, right .386, bottom .616
Slot2: left .444, top .527, right .556, bottom .616
Slot3: left .630, top .527, right .742, bottom .616
```

These values are relative to the square chest image and leave the gold border
visible on all four sides.

- [ ] **Step 6: Run focused tests and verify GREEN**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
bash tests/test_chapter_6_left_chest_flow_runtime.sh
```

Expected: both exit 0. The first test proves the node placement and exact inner
bounds; the second proves cancellation and reward flow remain unchanged.

- [ ] **Step 7: Check the focused diff**

```bash
git diff --check -- \
  scenes/chapter_6/chapter_6_left_chest_puzzle.gd \
  scenes/chapter_6/chapter_6_left_chest_puzzle.tscn \
  tests/test_chapter_6_left_chest_puzzle_runtime.gd
```

Do not stage or commit implementation files.

---

### Task 8: Final Layout Verification

**Files:**

- Test: all `tests/*.sh`
- Verify: Chapter 6 left-chest scene and protected room collisions

**Interfaces:**

- Consumes the Task 7 layout.
- Produces fresh verification evidence without altering game state.

- [ ] **Step 1: Run the full test suite**

```bash
set -eu
for test_file in tests/*.sh
do
  bash "$test_file"
done
```

Expected: every test script exits 0.

- [ ] **Step 2: Parse the full project**

```bash
HOME=/private/tmp/codex-godot-editor-left-chest-layout \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

Expected: exit 0 with no GDScript parse or compile error.

- [ ] **Step 3: Recheck protected wall hashes**

Require the unchanged values:

```text
left  8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
right 85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e
```

- [ ] **Step 4: Manual visual check**

1. Open the left-room chest puzzle and press E to begin.
2. Confirm `ยกเลิก (Esc)` appears at the upper-left viewport margin.
3. Confirm each neutral color rectangle is surrounded by visible gold on all
   four sides.
4. Answer correctly and incorrectly once to confirm green/red colors stay
   inside the same inner bounds.

---

### Task 9: Per-Slot Artwork Calibration

**Files:**

- Modify: `tests/test_chapter_6_left_chest_puzzle_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.tscn`

**Interfaces:**

- Preserves: `Dim/CancelButton`, `cancel()`, fixed question flow, and all
  puzzle signals.
- Changes only: normalized anchors for `Slot1`, `Slot2`, and `Slot3`.
- Produces: independently sized indicators that fill each dark center while
  retaining approximately two source pixels of clearance from gold.

- [ ] **Step 1: Replace the runtime test's expected slot bounds**

Use these exact per-slot values:

```gdscript
var expected := [
	Vector4(0.262, 0.515, 0.379, 0.622),
	Vector4(0.439, 0.515, 0.563, 0.622),
	Vector4(0.623, 0.515, 0.739, 0.622),
]
```

Keep the existing `is_equal_approx` comparison and the upper-left cancel
button assertions unchanged.

- [ ] **Step 2: Run the focused test and verify RED**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
```

Expected: FAIL at `Slot 1 is not aligned to the chest frame` because the scene
still contains the Task 7 values.

- [ ] **Step 3: Apply the independently measured scene anchors**

In `chapter_6_left_chest_puzzle.tscn`, change only the four anchors on each
`ColorRect`:

```text
Slot1: left .262, top .515, right .379, bottom .622
Slot2: left .439, top .515, right .563, bottom .622
Slot3: left .623, top .515, right .739, bottom .622
```

Do not add offsets. Do not modify `ChestPanel`, `ChestImage`, `Slots`,
`CancelButton`, or the question panel.

- [ ] **Step 4: Run focused tests and verify GREEN**

```bash
bash tests/test_chapter_6_left_chest_puzzle_runtime.sh
bash tests/test_chapter_6_left_chest_flow_runtime.sh
```

Expected: both exit 0. This proves exact bounds, feedback colors, cancellation,
and chest reward flow.

- [ ] **Step 5: Check the focused diff**

```bash
git diff --check -- \
  scenes/chapter_6/chapter_6_left_chest_puzzle.tscn \
  tests/test_chapter_6_left_chest_puzzle_runtime.gd
```

Do not stage or commit either implementation file.

---

### Task 10: Calibrated Layout Regression Verification

**Files:**

- Test: all `tests/*.sh`
- Verify: protected Chapter 6 room collisions

**Interfaces:**

- Consumes the Task 9 per-slot anchors.
- Produces final verification evidence without changing unrelated scenes.

- [ ] **Step 1: Run the full test suite**

```bash
set -e
for test_file in tests/*.sh
do
  bash "$test_file"
done
```

Expected: every test script exits 0.

- [ ] **Step 2: Parse the project**

```bash
HOME=/private/tmp/codex-godot-editor-left-chest-calibrated \
  /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --editor --quit
```

Expected: exit 0 with no GDScript parse or compile error.

- [ ] **Step 3: Recheck the protected wall hashes**

Require:

```text
left  8acbb3879f96b8f1fea9f5caf56926ad8ab04eda0cc942ac962436cf9f92ef37
right 85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e
```

- [ ] **Step 4: Manual visual check**

1. Open the left chest and answer two questions correctly.
2. Confirm the green rectangles fill the three independently sized dark
   centers without covering gold.
3. Intentionally answer incorrectly and confirm the red flash uses the same
   calibrated bounds.
4. Confirm the cancel button remains at the upper-left.
