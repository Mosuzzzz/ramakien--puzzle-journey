# Chapter 6 Right-Room Code and Lanka Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the four-jar Thai quiz, the `273` pedestal puzzle, the third key-fragment pickup, and the persistent Chapter 6 city-gate unlock into Chapter 7.

**Architecture:** Two focused paused-mode CanvasLayers own jar-question and code-entry UI state. A right-room controller owns world interactions, persistent jar/pedestal state, room quest text, and the ring pickup; the Chapter 6 controller owns only the shared quest and city-gate transaction. The existing portal gains a post-lock-check activation signal so Chapter 6 can persist and consume the three fragments immediately before its normal scene transition.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scenes, headless SceneTree runtime tests, POSIX shell contract tests.

## Global Constraints

- Preserve the exact right-room `Walls` section hash: `85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e`.
- Do not add, delete, resize, or reposition any existing right-room `Walls` collision node.
- Use the fixed Thai questions, authored first-attempt answer order, jar mapping, and asset paths from the approved design.
- Upper-left jar = `7`; upper-right jar = empty; lower-left jar = `3`; lower-right jar = `2`.
- The solution is exactly `273`; the pedestal remains usable before every jar has been searched.
- The right-room quest name is exactly `ค้นหาโค้ดลับเพื่อปลดล็อกชิ้นส่วนกุญแจ` and has no progress detail.
- Every modal has an upper-left `ยกเลิก (Esc)` button and disables cancellation during one-second red/green feedback.
- Wrong jar answers retry the same fixed question with visibly changed answer positions; wrong codes clear all three slots after feedback.
- Use inventory ID `lanka_key_fragment_ring` and texture `res://assets/ui/icon/split/image-removebg-preview.png`.
- Gate unlock validates all three distinct fragments before removing any one of them.
- Persist the gate-unlocked flag before inventory mutation; an unlocked gate and completed objective must not regress after the fragments are consumed.
- Preserve all unrelated user-owned working-tree changes; stage only files named by the current task.

---

## File Map

### New files

- `scenes/chapter_6/chapter_6_right_jar_modal.gd` — one jar's question/result state machine.
- `scenes/chapter_6/chapter_6_right_jar_modal.tscn` — dim overlay, jar image, question choices, and upper-left cancel button.
- `scenes/chapter_6/chapter_6_right_code_modal.gd` — temporary three-digit input and red/green feedback.
- `scenes/chapter_6/chapter_6_right_code_modal.tscn` — pedestal image, three slots, digit sources, clear, and cancel controls.
- `scenes/chapter_6/chapter_6_room_right.gd` — four world interactions, persistent mask, pedestal, reward, and room quest.
- `tests/test_chapter_6_right_jar_modal_runtime.gd`
- `tests/test_chapter_6_right_jar_modal_runtime.sh`
- `tests/test_chapter_6_right_code_modal_runtime.gd`
- `tests/test_chapter_6_right_code_modal_runtime.sh`
- `tests/test_chapter_6_right_room_flow_runtime.gd`
- `tests/test_chapter_6_right_room_flow_runtime.sh`
- `tests/test_chapter_6_gate_runtime.gd`
- `tests/test_chapter_6_gate_runtime.sh`
- `tests/test_chapter_6_right_room_state.sh`

### Existing files to modify

- `scenes/chapter_6/chapter_6_room_right.tscn` — attach controller and append interaction/UI nodes after the protected `Walls` block.
- `scenes/core/game_state.gd` — add jar mask, pedestal solved, and gate unlocked values.
- `scenes/core/save_game.gd` — save/load the three values.
- `scenes/homepage/home_page.gd` — reset the three values for a new story.
- `scenes/chapter_6/chapter_6_key_quest.gd` — show the green `3/3` gate instruction and preserve resolved state after consumption.
- `scenes/props/portal.gd` — emit a valid-use signal after the lock check.
- `scenes/chapter_6/chapter_6.gd` — configure and transact only `Chapter7Portal`.
- `scenes/chapter_6/chapter_6.tscn` — author the locked/unlocked city-gate prompts.
- `tests/test_chapter_6_key_fragment_quest_runtime.gd` — cover `3/3` and post-consumption resolved state.

### Existing user-provided assets to track with the UI task

- `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_08_34.png`
- `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_09_37.png`
- `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_52_39.png`
- `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png`
- `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_33.png`
- Their matching Godot `.import` files.

---

### Task 1: Persistent Chapter 6 Right-Room State

**Files:**
- Modify: `scenes/core/game_state.gd:22-27`
- Modify: `scenes/core/save_game.gd:25-36`
- Modify: `scenes/homepage/home_page.gd:20-35`
- Create: `tests/test_chapter_6_right_room_state.sh`

**Interfaces:**
- Produces: `GameState.chapter_6_right_jars_mask: int`
- Produces: `GameState.chapter_6_right_pedestal_solved: bool`
- Produces: `GameState.chapter_6_gate_unlocked: bool`
- Consumes: existing dynamic `SaveGame.STATE_KEYS` save/load loop.

- [ ] **Step 1: Write the failing state contract**

```sh
#!/bin/sh
set -eu

state="scenes/core/game_state.gd"
save="scenes/core/save_game.gd"
home="scenes/homepage/home_page.gd"

grep -Fq 'static var chapter_6_right_jars_mask := 0' "$state"
grep -Fq 'static var chapter_6_right_pedestal_solved := false' "$state"
grep -Fq 'static var chapter_6_gate_unlocked := false' "$state"
for key in chapter_6_right_jars_mask chapter_6_right_pedestal_solved chapter_6_gate_unlocked; do
  grep -Fq "\"$key\"" "$save"
  grep -Fq "GameState.$key =" "$home"
done
echo "Chapter 6 right-room state contract passed"
```

- [ ] **Step 2: Run the contract and confirm the missing-state failure**

Run: `sh tests/test_chapter_6_right_room_state.sh`

Expected: FAIL on the first missing `chapter_6_right_jars_mask` assertion.

- [ ] **Step 3: Add exact defaults, save keys, and new-story resets**

```gdscript
# game_state.gd
static var chapter_6_right_jars_mask := 0
static var chapter_6_right_pedestal_solved := false
static var chapter_6_gate_unlocked := false
```

Append all three exact strings to `SaveGame.STATE_KEYS`. In
`HomePage._on_start_pressed()` set the mask to `0` and both booleans to
`false`.

- [ ] **Step 4: Run focused persistence contracts**

Run:

```bash
sh tests/test_chapter_6_right_room_state.sh
sh tests/test_chapter_6_left_chest_state.sh
sh tests/test_inventory_persistence.sh
```

Expected: all three scripts print their `passed` message.

- [ ] **Step 5: Commit only the persistence slice**

```bash
git add scenes/core/game_state.gd scenes/core/save_game.gd scenes/homepage/home_page.gd tests/test_chapter_6_right_room_state.sh
git commit -m "feat: persist chapter 6 right-room progress"
```

---

### Task 2: Jar Question and Result Modal

**Files:**
- Create: `scenes/chapter_6/chapter_6_right_jar_modal.gd`
- Create: `scenes/chapter_6/chapter_6_right_jar_modal.tscn`
- Create: `tests/test_chapter_6_right_jar_modal_runtime.gd`
- Create: `tests/test_chapter_6_right_jar_modal_runtime.sh`
- Track: the four jar result PNGs and their `.import` files.

**Interfaces:**
- Consumes: jar definition dictionary with `index: int`, `question: String`, `choices: Array[String]`, `correct_index: int`, and `result_texture: Texture2D`.
- Produces: `signal searched(jar_index: int)`.
- Produces: `signal closed`.
- Produces: `func open_jar(definition: Dictionary, already_searched: bool) -> void`.
- Produces: `func cancel() -> void`.

- [ ] **Step 1: Write the failing modal runtime test**

The test must instantiate the modal and assert:

```gdscript
const MODAL := "res://scenes/chapter_6/chapter_6_right_jar_modal.tscn"

var definition := {
	"index": 0,
	"question": "ข้อใดเป็นคำพ้องเสียง",
	"choices": ["การ – กาล", "บ้าน – เรือน", "สูง – ต่ำ"],
	"correct_index": 0,
	"result_texture": load("res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png"),
}
modal.open_jar(definition, false)
assert(paused and modal.visible)
assert(modal.get_node("Dim/CancelButton").text == "ยกเลิก (Esc)")
assert(modal.get_node("Dim/QuestionPanel").visible)
```

Press `บ้าน – เรือน`, assert `_feedback_locked`, send Esc and assert the modal
stays open, wait `1.1` paused-time seconds, then assert the same question
remains and the displayed order differs from the authored order. Press
`การ – กาล`, assert one `searched(0)` emission, the question panel hidden, and
the result visible. Close with E, reopen with `already_searched = true`, assert
there is no question, then close with the cancel button. Add a second attempt
that cancels before success and asserts no `searched` emission.

- [ ] **Step 2: Add and run the failing shell wrapper**

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-right-jar}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_right_jar_modal_runtime.gd
```

Run: `sh tests/test_chapter_6_right_jar_modal_runtime.sh`

Expected: FAIL because the modal scene does not exist.

- [ ] **Step 3: Build the focused jar state machine**

Use these exact public signals and entry point:

```gdscript
extends CanvasLayer

signal searched(jar_index: int)
signal closed

const NEUTRAL := Color("#241a14")
const WRONG := Color("#e33a35")

var _definition: Dictionary = {}
var _feedback_locked := false
var _searched_emitted := false
var _current_order: Array[int] = []

func open_jar(definition: Dictionary, already_searched: bool) -> void:
	_definition = definition
	_feedback_locked = false
	_searched_emitted = false
	_current_order = [0, 1, 2]
	$Dim/JarPanel/JarImage.texture = definition.result_texture
	$Dim/QuestionPanel.visible = not already_searched
	_render_authored_choices()
	visible = true
	get_tree().paused = true
```

`_on_choice_pressed(original_index)` compares against
`_definition.correct_index`. On wrong answer, color only the selected button
red, lock all buttons, await `get_tree().create_timer(1.0, true).timeout`, then
generate a shuffled order. If `shuffle()` returns `[0, 1, 2]`, rotate to
`[1, 2, 0]` so the user always sees changed positions. On correct answer, emit
`searched` once and reveal the result without closing it.

`cancel()` must no-op while locked; otherwise hide, unpause, and emit `closed`.
`_input` maps Esc to cancel in both states and E to cancel only after the result
has been revealed.

- [ ] **Step 4: Build the modal scene with exact stable node paths**

```text
RightJarModal (CanvasLayer, process_mode=ALWAYS, visible=false)
└── Dim (ColorRect, full rect, translucent black)
    ├── CancelButton (Button, upper-left 24 px margin)
    ├── JarPanel (Control, centered large)
    │   └── JarImage (TextureRect, keep aspect centered)
    └── QuestionPanel (PanelContainer, centered over jar opening)
        └── Margin/VBox
            ├── QuestionLabel
            └── Choices
                ├── Choice1
                ├── Choice2
                └── Choice3
```

Set Thai-capable Sarabun fonts, mouse filters that stop clicks, a dim color
near `Color(0, 0, 0, 0.72)`, and connect the four buttons to the script.

- [ ] **Step 5: Run modal and parse verification**

Run:

```bash
sh tests/test_chapter_6_right_jar_modal_runtime.sh
HOME=/private/tmp/codex-godot-right-jar-parse /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: runtime prints `Chapter 6 right jar modal runtime passed`; Godot exits
`0` without parse errors.

- [ ] **Step 6: Commit the jar modal slice**

```bash
git add scenes/chapter_6/chapter_6_right_jar_modal.gd scenes/chapter_6/chapter_6_right_jar_modal.gd.uid scenes/chapter_6/chapter_6_right_jar_modal.tscn tests/test_chapter_6_right_jar_modal_runtime.gd tests/test_chapter_6_right_jar_modal_runtime.gd.uid tests/test_chapter_6_right_jar_modal_runtime.sh "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_09_37.png" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_09_37.png.import" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_52_39.png" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_52_39.png.import" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png.import" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_33.png" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_33.png.import"
git commit -m "feat: add chapter 6 jar question modal"
```

---

### Task 3: Central `273` Code Modal

**Files:**
- Create: `scenes/chapter_6/chapter_6_right_code_modal.gd`
- Create: `scenes/chapter_6/chapter_6_right_code_modal.tscn`
- Create: `tests/test_chapter_6_right_code_modal_runtime.gd`
- Create: `tests/test_chapter_6_right_code_modal_runtime.sh`
- Track: `assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_08_34.png` and its `.import`.

**Interfaces:**
- Consumes: `func open(discovered_digits: Array[int]) -> void`.
- Produces: `signal solved`.
- Produces: `signal closed`.
- Produces: `func cancel() -> void`.
- Internal source order is `[2, 7, 3]`; undiscovered source buttons render `?` and are disabled.

- [ ] **Step 1: Write the failing code-modal runtime test**

Instantiate and call `open([2])`. Assert paused/visible, source texts
`["2", "?", "?"]`, only the first source enabled, and an upper-left cancel
button. Close, reopen with `[2, 7, 3]`, and press digit source buttons to build
`272`. Assert all slots red and input/cancel locked, then after `1.1` seconds
assert all slots are blank and neutral. Press `2`, `7`, `3`; assert all slots
green, exactly one `solved` emission, and close/unpause after one second.

Also test:

```gdscript
modal.open([2, 7, 3])
modal.call("_append_digit", 2)
modal.call("_append_digit", 2)
assert(modal.get("_entered_digits") == [2, 2])
modal.call("_clear_code")
assert(modal.get("_entered_digits").is_empty())
```

- [ ] **Step 2: Add the wrapper and confirm the missing-scene failure**

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-right-code}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_right_code_modal_runtime.gd
```

Run: `sh tests/test_chapter_6_right_code_modal_runtime.sh`

Expected: FAIL because the code modal scene does not exist.

- [ ] **Step 3: Implement deterministic entry and feedback**

```gdscript
extends CanvasLayer

signal solved
signal closed

const SOURCE_DIGITS: Array[int] = [2, 7, 3]
const SOLUTION: Array[int] = [2, 7, 3]
const NEUTRAL := Color("#241a14")
const WRONG := Color("#e33a35")
const CORRECT := Color("#36c75b")

var _entered_digits: Array[int] = []
var _feedback_locked := false
var _solved_emitted := false

func open(discovered_digits: Array[int]) -> void:
	_entered_digits.clear()
	_feedback_locked = false
	_solved_emitted = false
	_render_sources(discovered_digits)
	_render_slots(NEUTRAL)
	visible = true
	get_tree().paused = true
```

`_append_digit` ignores input while locked or full, accepts repeated digits,
updates the next slot, and calls `_evaluate()` at length three. Wrong input
locks all controls, colors all slots red for one paused-time second, clears the
array, and restores neutral blank slots. Correct input colors all slots green,
waits one second, emits `solved` once, hides, and unpauses. `cancel()` discards
partial input and emits only `closed`.

- [ ] **Step 4: Build the stable scene hierarchy**

```text
RightCodeModal (CanvasLayer, process_mode=ALWAYS, visible=false)
└── Dim
    ├── CancelButton
    ├── PedestalPanel
    │   ├── PedestalImage
    │   └── Slots
    │       ├── Slot1/Value
    │       ├── Slot2/Value
    │       └── Slot3/Value
    └── EntryPanel/Margin/VBox
        ├── Instruction
        ├── DigitSources
        │   ├── Digit2
        │   ├── Digit7
        │   └── Digit3
        └── ClearButton
```

Set `PedestalImage` to the exact pedestal PNG. Anchor cancel at 24 px from the
upper-left. Connect source buttons, clear, and cancel.

- [ ] **Step 5: Run focused verification**

Run:

```bash
sh tests/test_chapter_6_right_code_modal_runtime.sh
HOME=/private/tmp/codex-godot-right-code-parse /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: test passes and Godot exits `0`.

- [ ] **Step 6: Commit the code modal**

```bash
git add scenes/chapter_6/chapter_6_right_code_modal.gd scenes/chapter_6/chapter_6_right_code_modal.gd.uid scenes/chapter_6/chapter_6_right_code_modal.tscn tests/test_chapter_6_right_code_modal_runtime.gd tests/test_chapter_6_right_code_modal_runtime.gd.uid tests/test_chapter_6_right_code_modal_runtime.sh "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_08_34.png" "assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_08_34.png.import"
git commit -m "feat: add chapter 6 pedestal code modal"
```

---

### Task 4: Four Jar World Interactions

**Files:**
- Create: `scenes/chapter_6/chapter_6_room_right.gd`
- Modify: `scenes/chapter_6/chapter_6_room_right.tscn:1-3, after Walls and after YSortRoot`
- Create: `tests/test_chapter_6_right_room_flow_runtime.gd`
- Create: `tests/test_chapter_6_right_room_flow_runtime.sh`

**Interfaces:**
- Consumes: `RightJarModal.open_jar(definition, already_searched)`.
- Consumes: `RightJarModal.searched(jar_index)` and `RightJarModal.closed`.
- Produces: `func _is_jar_searched(index: int) -> bool`.
- Produces: `func _on_jar_searched(index: int) -> void`.
- Produces: room quest `ค้นหาโค้ดลับเพื่อปลดล็อกชิ้นส่วนกุญแจ` with empty detail.

- [ ] **Step 1: Write the initial right-room integration assertions**

The runtime test resets inventory and all three new state fields, instantiates
`chapter_6_room_right.tscn`, and verifies:

```gdscript
const JAR_PATHS := [
	"JarInteractions/JarUpperLeft",
	"JarInteractions/JarUpperRight",
	"JarInteractions/JarLowerLeft",
	"JarInteractions/JarLowerRight",
]
const EXPECTED_RESULTS := ["7", "", "3", "2"]

for index in range(4):
	var area := room.get_node(JAR_PATHS[index])
	assert(area.position.distance_to(Vector2(627, 627)) > 250.0)
	assert(area.get_node("Prompt").text == "กด E เพื่อค้นหา")
```

Assert the room quest's name is exact and its detail label is empty. Simulate
the player entering upper-left, send E, assert jar definition 0/question 1/result
7 opened. Emit `searched(0)`, assert mask `1`, close, interact again, and assert
the modal opens in result-only mode with prompt `กด E เพื่อดูในโหล`.

Set mask bits for jars 0 and 2, recreate the room, and assert only those two
jars restore as searched. Assert searching jar 1 ORs bit `2` without erasing
bits 0 and 2.

- [ ] **Step 2: Add the shell wrapper and verify failure**

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-right-room}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_right_room_flow_runtime.gd
```

Run: `sh tests/test_chapter_6_right_room_flow_runtime.sh`

Expected: FAIL because the room has no controller or jar nodes.

- [ ] **Step 3: Define the exact fixed jar data**

```gdscript
const JARS := [
	{
		"index": 0,
		"question": "ข้อใดเป็นคำพ้องเสียง",
		"choices": ["การ – กาล", "บ้าน – เรือน", "สูง – ต่ำ"],
		"correct_index": 0,
		"digit": 7,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png",
	},
	{
		"index": 1,
		"question": "คำว่า “เสียสละ” มีความหมายตรงกับข้อใด",
		"choices": ["ยอมสละประโยชน์ของตนเพื่อผู้อื่น", "ทำงานโดยหวังรางวัล", "หลีกเลี่ยงการช่วยเหลือ"],
		"correct_index": 0,
		"digit": -1,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_09_37.png",
	},
	{
		"index": 2,
		"question": "สำนวน “น้ำขึ้นให้รีบตัก” หมายถึงอะไร",
		"choices": ["ให้รีบตักน้ำเก็บไว้", "ให้ใช้โอกาสที่ดีให้เกิดประโยชน์", "ให้ทำงานอย่างช้า ๆ"],
		"correct_index": 1,
		"digit": 3,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_33.png",
	},
	{
		"index": 3,
		"question": "ข้อใดใช้คำเชื่อมได้ถูกต้อง",
		"choices": ["เพราะฝนตก แต่ฉันจึงกางร่ม", "เพราะฝนตก ฉันจึงกางร่ม", "แม้ฝนตก เพราะฉันกางร่ม"],
		"correct_index": 1,
		"digit": 2,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_52_39.png",
	},
]
```

At `_ready`, load each `texture_path` into a duplicate dictionary and connect
each Area2D by its fixed index. `_on_jar_searched` updates:

```gdscript
GameState.chapter_6_right_jars_mask |= 1 << index
```

No array assignment may replace the mask.

- [ ] **Step 4: Append interactions without editing protected walls**

Add the controller ext-resource and these nodes:

```text
JarInteractions (Node2D)
├── JarUpperLeft (Area2D, position Vector2(245, 390), controller index 0)
├── JarUpperRight (Area2D, position Vector2(1005, 390), controller index 1)
├── JarLowerLeft (Area2D, position Vector2(245, 800), controller index 2)
└── JarLowerRight (Area2D, position Vector2(1005, 800), controller index 3)
```

Each jar gets its own duplicated `CircleShape2D` radius `72`, a centered Prompt
label, and body-entered/body-exited connections. Use the four exact authored
positions above; any later visual correction must change only these interaction
nodes, never a `Walls/*` node. Instance `RightJarModal` at the root.

- [ ] **Step 5: Verify runtime and collision preservation**

Run:

```bash
sh tests/test_chapter_6_right_room_flow_runtime.sh
awk '/\\[node name="Walls"/{keep=1} /\\[node name="YSortRoot"/{keep=0} keep' scenes/chapter_6/chapter_6_room_right.tscn | shasum -a 256
```

Expected: runtime passes; hash equals
`85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e`.

- [ ] **Step 6: Commit jar world integration**

```bash
git add scenes/chapter_6/chapter_6_room_right.gd scenes/chapter_6/chapter_6_room_right.gd.uid scenes/chapter_6/chapter_6_room_right.tscn tests/test_chapter_6_right_room_flow_runtime.gd tests/test_chapter_6_right_room_flow_runtime.gd.uid tests/test_chapter_6_right_room_flow_runtime.sh
git commit -m "feat: add searchable jars to chapter 6 right room"
```

---

### Task 5: Pedestal Interaction and Ring Reward

**Files:**
- Modify: `scenes/chapter_6/chapter_6_room_right.gd`
- Modify: `scenes/chapter_6/chapter_6_room_right.tscn`
- Modify: `tests/test_chapter_6_right_room_flow_runtime.gd`

**Interfaces:**
- Consumes: `RightCodeModal.open(discovered_digits: Array[int])`.
- Consumes: `RightCodeModal.solved` and `RightCodeModal.closed`.
- Consumes: `key_fragment_pickup.tscn` and inventory ID `lanka_key_fragment_ring`.
- Produces: `func _discovered_digits() -> Array[int]`.
- Produces: `func _on_code_solved() -> void`.
- Produces: `func _spawn_ring_fragment() -> void`.

- [ ] **Step 1: Extend the failing flow test**

Before any jar is searched, enter `PedestalInteraction`, press E, and assert the
code modal receives an empty discovered array and displays three disabled `?`
sources. Set only the mask bits for the `2`, `7`, and `3` jars (`1 << 3`,
`1 << 0`, `1 << 2`), reopen, and assert the available sources are exactly
`[2, 7, 3]` even while the empty-jar bit remains unset.

Emit `solved`, then assert:

```gdscript
assert(GameState.chapter_6_right_pedestal_solved)
assert(room.get_node_or_null("YSortRoot/RightRoomKeyFragment") != null)
assert(inventory.count("lanka_key_fragment_ring") == 0)
assert(quest_name.text == "เก็บชิ้นส่วนกุญแจ")
```

Recreate the room and assert one pickup is restored. Emit its
`collection_requested`, assert exactly one ring in inventory, no world pickup,
and the shared quest restored. Recreate again and assert no duplicate pickup.

- [ ] **Step 2: Run the focused test to confirm new assertions fail**

Run: `sh tests/test_chapter_6_right_room_flow_runtime.sh`

Expected: FAIL because `PedestalInteraction` and the ring reward do not exist.

- [ ] **Step 3: Add discovery and reward logic**

```gdscript
const RING_ID := "lanka_key_fragment_ring"
const RING_TEXTURE := preload("res://assets/ui/icon/split/image-removebg-preview.png")
const RING_PICKUP_POSITION := Vector2(627, 555)

func _discovered_digits() -> Array[int]:
	var result: Array[int] = []
	for jar: Dictionary in JARS:
		if int(jar.digit) >= 0 and _is_jar_searched(int(jar.index)):
			result.append(int(jar.digit))
	return result
```

`_on_code_solved` must be idempotent, set
`chapter_6_right_pedestal_solved = true`, disable the pedestal interaction,
set quest name `เก็บชิ้นส่วนกุญแจ` with empty detail, and spawn exactly one
pickup. At `_ready`, ring inventory implies solved; solved plus no ring
restores the pickup. Collection adds one ring, removes the pickup, and calls
`Chapter6KeyQuest.refresh(get_tree())`.

- [ ] **Step 4: Append central scene nodes**

Add `PedestalInteraction` at `Vector2(627, 627)` with a `CircleShape2D` radius
`120`, prompt `กด E เพื่อใส่รหัส`, and body signals. Instance
`RightCodeModal` at the root. Add no collision under `Walls`.

- [ ] **Step 5: Run room, modal, inventory, and wall checks**

Run:

```bash
sh tests/test_chapter_6_right_room_flow_runtime.sh
sh tests/test_chapter_6_right_code_modal_runtime.sh
sh tests/test_key_fragment_pickup_runtime.sh
awk '/\\[node name="Walls"/{keep=1} /\\[node name="YSortRoot"/{keep=0} keep' scenes/chapter_6/chapter_6_room_right.tscn | shasum -a 256
```

Expected: all pass and the wall hash remains exact.

- [ ] **Step 6: Commit pedestal and reward**

```bash
git add scenes/chapter_6/chapter_6_room_right.gd scenes/chapter_6/chapter_6_room_right.tscn tests/test_chapter_6_right_room_flow_runtime.gd
git commit -m "feat: award chapter 6 ring fragment from code pedestal"
```

---

### Task 6: Shared `3/3` Quest and Safe Portal Activation Signal

**Files:**
- Modify: `scenes/chapter_6/chapter_6_key_quest.gd:3-27`
- Modify: `scenes/props/portal.gd:1-69`
- Modify: `tests/test_chapter_6_key_fragment_quest_runtime.gd`
- Create: `tests/test_chapter_6_gate_runtime.gd`
- Create: `tests/test_chapter_6_gate_runtime.sh`

**Interfaces:**
- Produces: `Chapter6KeyQuest.has_all_fragments(tree: SceneTree) -> bool`.
- Produces: `Chapter6KeyQuest.consume_fragments(tree: SceneTree) -> bool`.
- Produces: portal `signal activated(portal: Area2D)` emitted only on an unlocked valid use.
- Consumes: `Inventory.remove_item(id: String, n: int = 1) -> bool`.

- [ ] **Step 1: Add failing quest-completion assertions**

Extend the quest runtime test to add one of each distinct fragment and assert:

```gdscript
assert(Chapter6KeyQuest.progress(self) == 3)
Chapter6KeyQuest.refresh(self)
assert(quest_name_label.modulate == Color("#67d56b"))
assert("3/3" in detail_label.text)
assert("ประตูเมือง" in detail_label.text)
```

Then set `GameState.chapter_6_gate_unlocked = true`, remove all fragments,
refresh, and assert the quest remains completed and does not contain `0/3`.

- [ ] **Step 2: Add the failing portal-signal runtime test**

Instantiate `portal.tscn`, set `locked = true`, connect `activated`, call
`_use_portal`, and assert zero emissions. Set unlocked, replace
`target_scene` with the current harmless test scene or intercept before the
deferred frame, call `_use_portal`, and assert one synchronous emission before
the queued transition.

Wrapper:

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-gate}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_gate_runtime.gd
```

- [ ] **Step 3: Run both focused tests and confirm failure**

Run:

```bash
sh tests/test_chapter_6_key_fragment_quest_runtime.sh
sh tests/test_chapter_6_gate_runtime.sh
```

Expected: FAIL on missing completed gate copy and missing portal signal.

- [ ] **Step 4: Implement shared quest and atomic fragment helpers**

```gdscript
const GATE_READY_DETAIL := "รวบรวมชิ้นส่วนกุญแจ 3/3 — ไปปลดล็อกประตูเมือง"
const GATE_OPEN_DETAIL := "ประตูเมืองถูกปลดล็อกแล้ว"

static func has_all_fragments(tree: SceneTree) -> bool:
	return progress(tree) == FRAGMENT_IDS.size()

static func consume_fragments(tree: SceneTree) -> bool:
	if not has_all_fragments(tree):
		return false
	var inventory := tree.root.get_node_or_null("Inv")
	for item_id: String in FRAGMENT_IDS:
		inventory.remove_item(item_id)
	return true
```

`refresh()` first checks `GameState.chapter_6_gate_unlocked`; if true, set the
shared quest to `GATE_OPEN_DETAIL` and completed. Otherwise use normal progress,
substituting `GATE_READY_DETAIL` at three.

- [ ] **Step 5: Add the portal signal after the lock guard**

```gdscript
signal activated(portal: Area2D)

func _use_portal() -> void:
	if locked:
		get_viewport().set_input_as_handled()
		return
	activated.emit(self)
	GameState.next_spawn = target_spawn
	get_tree().change_scene_to_file.call_deferred(target_scene)
	get_viewport().set_input_as_handled()
```

This preserves every existing portal's behavior while giving listeners a
synchronous pre-transition hook.

- [ ] **Step 6: Run shared regression tests**

Run:

```bash
sh tests/test_chapter_6_key_fragment_quest_runtime.sh
sh tests/test_chapter_6_gate_runtime.sh
sh tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected: all pass.

- [ ] **Step 7: Commit quest and portal primitives**

```bash
git add scenes/chapter_6/chapter_6_key_quest.gd scenes/props/portal.gd tests/test_chapter_6_key_fragment_quest_runtime.gd tests/test_chapter_6_gate_runtime.gd tests/test_chapter_6_gate_runtime.gd.uid tests/test_chapter_6_gate_runtime.sh
git commit -m "feat: add chapter 6 gate quest and portal activation hook"
```

---

### Task 7: City Gate Lock, Consumption, and Chapter 7 Transition

**Files:**
- Modify: `scenes/chapter_6/chapter_6.gd:13-93`
- Modify: `scenes/chapter_6/chapter_6.tscn:572-575`
- Extend: `tests/test_chapter_6_gate_runtime.gd`
- Extend: `tests/test_chapter_6_key_fragment_quest_runtime.gd`

**Interfaces:**
- Consumes: `$YSortRoot/Chapter7Portal.activated(portal)`.
- Consumes: `Chapter6KeyQuest.has_all_fragments(tree)`.
- Consumes: `Chapter6KeyQuest.consume_fragments(tree)`.
- Produces: `func _refresh_city_gate() -> void`.
- Produces: `func _on_chapter_7_portal_activated(portal: Area2D) -> void`.

- [ ] **Step 1: Extend the failing gate integration test**

Instantiate Chapter 6 with zero fragments and assert:

```gdscript
var gate := chapter.get_node("YSortRoot/Chapter7Portal")
assert(gate.locked)
assert(gate.locked_prompt_text == "รวบรวมชิ้นส่วนกุญแจให้ครบ 3 ชิ้นก่อน")
```

Add only two distinct fragments and assert the gate remains locked. Add the
third, allow the inventory `changed` signal to process, and assert unlocked
with prompt `กด E เพื่อใช้กุญแจเปิดประตูเมือง`.

Call the chapter handler directly and assert:

```gdscript
assert(GameState.chapter_6_gate_unlocked)
for id in Chapter6KeyQuest.FRAGMENT_IDS:
	assert(inventory.count(id) == 0)
```

Call it a second time and assert no negative/duplicate mutation. Recreate
Chapter 6 with no fragments and `chapter_6_gate_unlocked = true`; assert the
gate stays unlocked and the quest does not regress to `0/3`. Verify its
`target_scene` is exactly Chapter 7.

- [ ] **Step 2: Run the integration test and confirm it fails**

Run: `sh tests/test_chapter_6_gate_runtime.sh`

Expected: FAIL because Chapter 6 does not configure or transact the gate.

- [ ] **Step 3: Configure only the Chapter 7 portal**

```gdscript
@onready var _chapter_7_portal: Area2D = $YSortRoot/Chapter7Portal

func _ready() -> void:
	# Preserve existing Yak setup above/below this addition.
	_chapter_7_portal.activated.connect(_on_chapter_7_portal_activated)
	_refresh_city_gate()
```

Connect inventory `changed` to both `_refresh_quest` and `_refresh_city_gate`
without duplicate connections. `_refresh_city_gate` uses:

```gdscript
var unlocked := (
	GameState.chapter_6_gate_unlocked
	or Chapter6KeyQuest.has_all_fragments(get_tree())
)
_chapter_7_portal.set_locked(not unlocked)
```

It must not affect `LeftTowerRoomPortal`, `RightTowerRoomPortal`, or
`Chapter5Portal`.

- [ ] **Step 4: Implement the one-time gate transaction**

```gdscript
func _on_chapter_7_portal_activated(_portal: Area2D) -> void:
	if GameState.chapter_6_gate_unlocked:
		return
	if not Chapter6KeyQuest.has_all_fragments(get_tree()):
		_chapter_7_portal.set_locked(true)
		return
	GameState.chapter_6_gate_unlocked = true
	if not Chapter6KeyQuest.consume_fragments(get_tree()):
		GameState.chapter_6_gate_unlocked = false
		_chapter_7_portal.set_locked(true)
		return
	Chapter6KeyQuest.refresh(get_tree())
```

The initial validation occurs before removal; the flag is persisted before the
first `remove_item` emits `changed`.

- [ ] **Step 5: Author exact scene prompts**

```ini
[node name="Chapter7Portal" parent="YSortRoot" ...]
target_scene = "res://scenes/chapter_7/chapter_7.tscn"
target_spawn = Vector2(1083, 1462.5)
prompt_text = "กด E เพื่อใช้กุญแจเปิดประตูเมือง"
locked = true
locked_prompt_text = "รวบรวมชิ้นส่วนกุญแจให้ครบ 3 ชิ้นก่อน"
```

- [ ] **Step 6: Run gate and existing Chapter 6 tests**

Run:

```bash
sh tests/test_chapter_6_gate_runtime.sh
sh tests/test_chapter_6_key_fragment_quest_runtime.sh
sh tests/test_chapter_6_tower_rooms.sh
sh tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected: all pass; the two tower portals and Chapter 5 portal retain their
existing targets and interactions.

- [ ] **Step 7: Commit the gate integration**

```bash
git add scenes/chapter_6/chapter_6.gd scenes/chapter_6/chapter_6.tscn tests/test_chapter_6_gate_runtime.gd tests/test_chapter_6_key_fragment_quest_runtime.gd
git commit -m "feat: unlock Lanka gate with three key fragments"
```

---

### Task 8: Save/Load Flow, Full Regression, and Visual Playtest

**Files:**
- Modify: `tests/test_inventory_save_runtime.gd`

**Interfaces:**
- Consumes: all state, modal, room, quest, inventory, portal, and gate interfaces above.
- Produces: verified complete Chapter 6 right-room and gate flow.

- [ ] **Step 1: Add save/load assertions for all three new values**

In the inventory/save runtime fixture, set:

```gdscript
GameState.chapter_6_right_jars_mask = 0b0101
GameState.chapter_6_right_pedestal_solved = true
GameState.chapter_6_gate_unlocked = true
```

Save, overwrite with defaults, load the slot, and assert exact restoration.
Reset the new story and assert `0`, `false`, `false`.

- [ ] **Step 2: Run the focused save test**

Run:

```bash
HOME=/private/tmp/codex-godot-chapter-6-right-save /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_inventory_save_runtime.gd
```

Expected: PASS with the three new values restored.

- [ ] **Step 3: Run every Chapter 6 and inventory regression**

Run:

```bash
for test_script in \
  tests/test_chapter_6_opening_cutscene.sh \
  tests/test_chapter_6_tower_rooms.sh \
  tests/test_chapter_6_tower_rooms_runtime.sh \
  tests/test_chapter_6_tower_rooms_playtest_runtime.sh \
  tests/test_chapter_6_key_fragment_state.sh \
  tests/test_chapter_6_key_fragment_quest_runtime.sh \
  tests/test_chapter_6_left_chest_state.sh \
  tests/test_chapter_6_left_chest_puzzle_runtime.sh \
  tests/test_chapter_6_left_chest_flow_runtime.sh \
  tests/test_chapter_6_right_room_state.sh \
  tests/test_chapter_6_right_jar_modal_runtime.sh \
  tests/test_chapter_6_right_code_modal_runtime.sh \
  tests/test_chapter_6_right_room_flow_runtime.sh \
  tests/test_chapter_6_gate_runtime.sh \
  tests/test_key_fragment_pickup_runtime.sh \
  tests/test_inventory_persistence.sh; do
  sh "$test_script"
done
```

Expected: every script prints a pass message and exits `0`.

- [ ] **Step 4: Parse the complete Godot project**

Run:

```bash
HOME=/private/tmp/codex-godot-chapter-6-right-final /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit `0`, no parser errors, no missing-resource errors.

- [ ] **Step 5: Recheck protected wall hashes**

Run:

```bash
awk '/\\[node name="Walls"/{keep=1} /\\[node name="YSortRoot"/{keep=0} keep' scenes/chapter_6/chapter_6_room_right.tscn | shasum -a 256
```

Expected:

```text
85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e
```

- [ ] **Step 6: Perform the visual playtest**

Run the game and verify this exact route:

1. Enter the right tower and confirm the no-detail room quest.
2. Open an unsearched jar, answer incorrectly, verify red feedback, blocked
   cancel, and shuffled retry of the same question.
3. Cancel before success and confirm it remains unsearched.
4. Correctly search the jars containing `2`, `7`, and `3`; skip the empty jar.
5. Reopen a searched jar and confirm direct result viewing.
6. Open the pedestal early and confirm unknown sources are `?`.
7. Enter a wrong three-digit code and confirm all slots flash red and clear.
8. Enter `273`, confirm one-second green feedback and one ring pickup.
9. Leave and re-enter before collection; confirm exactly one pickup restores.
10. Collect it; confirm inventory has three separate fragment slots and the
    shared quest shows green `3/3` with the gate instruction.
11. Approach the city gate, press E, confirm all three fragments disappear and
    Chapter 7 loads.
12. Return to Chapter 6 and confirm the gate remains open and the completed
    objective does not show `0/3`.

- [ ] **Step 7: Review the scoped diff and commit final test adjustments**

Run:

```bash
git diff --check
git status --short
git diff -- scenes/chapter_6 scenes/core/game_state.gd scenes/core/save_game.gd scenes/homepage/home_page.gd scenes/props/portal.gd tests
```

Confirm no unrelated user file is staged. Then:

```bash
git add tests/test_inventory_save_runtime.gd
git commit -m "test: cover chapter 6 right-room save and gate flow"
```

Skip this commit if the file required no change.
