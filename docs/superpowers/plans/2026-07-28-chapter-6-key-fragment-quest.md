# Chapter 6 Key Fragment Quest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Start a persistent `0/3` Lanka key-fragment quest after the Chapter 6 cutscene and let the Yak Captain drop a floating, E-interactable shaft fragment that enters inventory and advances the quest to `1/3`.

**Architecture:** A Chapter 6 controller owns quest state and translates a generic mob defeat signal into a reusable world pickup. Inventory remains the source of truth for collected pieces, while GameState records the uncollected Yak drop across scene changes and SaveGame records the Yak's defeated state.

**Tech Stack:** Godot 4.7.1, GDScript, Area2D interaction, CanvasLayer autoloads, JSON save slots, POSIX shell and headless Godot runtime tests.

## Global Constraints

- Use three distinct item IDs: `lanka_key_fragment_shaft`, `lanka_key_fragment_bar`, and `lanka_key_fragment_ring`.
- The Yak Captain drops only `lanka_key_fragment_shaft` in this phase.
- Use `res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png` for the Yak shaft fragment.
- Show quest name `ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง`.
- Show detail `รวบรวมชิ้นส่วนกุญแจ %d/3`.
- Killing the Yak Captain must not advance progress; collecting the pickup advances it.
- Do not implement room puzzles, fragment combination, or city-gate unlocking.
- Do not change Chapter 6 wall collisions, tower-room layout, portal positions, or portal destinations.
- Preserve all user-owned uncommitted images and scene edits. Do not create a code commit that would capture unrelated work.

---

### Task 1: Register Fragment Inventory and Persistent State

**Files:**
- Create: `tests/test_chapter_6_key_fragment_state.sh`
- Modify: `tests/test_inventory_save_runtime.gd`
- Modify: `scenes/ui/inventory.gd`
- Modify: `scenes/core/game_state.gd`
- Modify: `scenes/core/save_game.gd`
- Modify: `scenes/homepage/home_page.gd`

**Interfaces:**
- Produces: Inventory IDs consumed by the Chapter 6 controller.
- Produces: `GameState.chapter_6_yak_defeated: bool`.
- Produces: `GameState.chapter_6_yak_fragment_position: Vector2`.
- Produces: Save/load persistence for `chapter_6_intro_played` and `chapter_6_yak_defeated`.

- [ ] **Step 1: Write the failing state contract**

Create `tests/test_chapter_6_key_fragment_state.sh`:

```sh
#!/bin/sh
set -eu

inventory="scenes/ui/inventory.gd"
state="scenes/core/game_state.gd"
save_game="scenes/core/save_game.gd"
home="scenes/homepage/home_page.gd"
icons="assets/ui/icon/split"

test -f "$icons/image-removebg-preview-removebg-preview.png"
test -f "$icons/image-removebg-preview สำเนา.png"
test -f "$icons/image-removebg-preview.png"
grep -Fq '"lanka_key_fragment_shaft"' "$inventory"
grep -Fq '"lanka_key_fragment_bar"' "$inventory"
grep -Fq '"lanka_key_fragment_ring"' "$inventory"
grep -Fq 'static var chapter_6_yak_defeated := false' "$state"
grep -Fq 'static var chapter_6_yak_fragment_position := Vector2.INF' "$state"
grep -Fq '"chapter_6_intro_played"' "$save_game"
grep -Fq '"chapter_6_yak_defeated"' "$save_game"
grep -Fq 'GameState.chapter_6_yak_defeated = false' "$home"
grep -Fq 'GameState.chapter_6_yak_fragment_position = Vector2.INF' "$home"
echo "Chapter 6 key fragment state contract passed"
```

Extend `tests/test_inventory_save_runtime.gd` before saving:

```gdscript
GameState.chapter_6_intro_played = true
GameState.chapter_6_yak_defeated = true
```

Assert both keys are present and true in `slot_info(2)`, then set both false,
load the slot, and assert both return to true. Reset
`GameState.chapter_6_yak_fragment_position` before and after the test.

- [ ] **Step 2: Run state tests to verify RED**

Run:

```bash
bash tests/test_chapter_6_key_fragment_state.sh
bash tests/test_inventory_save_and_ending.sh
```

Expected: the new contract exits 1 at the first missing item/state declaration,
and the save runtime fails because the Chapter 6 fields are not persisted.

- [ ] **Step 3: Add the three inventory catalog entries**

Add to `Inventory.ITEMS`:

```gdscript
"lanka_key_fragment_shaft": {
	"name": "ชิ้นส่วนกุญแจ: แกน",
	"icon": "res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png",
},
"lanka_key_fragment_bar": {
	"name": "ชิ้นส่วนกุญแจ: แท่ง",
	"icon": "res://assets/ui/icon/split/image-removebg-preview สำเนา.png",
},
"lanka_key_fragment_ring": {
	"name": "ชิ้นส่วนกุญแจ: ห่วง",
	"icon": "res://assets/ui/icon/split/image-removebg-preview.png",
},
```

- [ ] **Step 4: Add and reset Chapter 6 state**

Add to `game_state.gd`:

```gdscript
static var chapter_6_yak_defeated := false
static var chapter_6_yak_fragment_position := Vector2.INF
```

Reset both fields in `home_page.gd::_on_start_pressed()`.

- [ ] **Step 5: Persist the boolean Chapter 6 state**

Add `chapter_6_intro_played` and `chapter_6_yak_defeated` to
`SaveGame.STATE_KEYS`. In `load_slot()`, set:

```gdscript
GameState.chapter_6_yak_fragment_position = Vector2.INF
```

before changing scenes, so a loaded uncollected fragment uses the authored Yak
position rather than stale in-memory coordinates.

- [ ] **Step 6: Run state tests to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_key_fragment_state.sh
bash tests/test_inventory_save_and_ending.sh
bash tests/test_inventory_persistence.sh
```

Expected: all three commands exit 0.

- [ ] **Step 7: Review checkpoint**

Run `git diff --check`. Do not commit because the shared working tree contains
user-owned uncommitted Chapter 6 work.

---

### Task 2: Add One-Shot Mob Defeat and Reusable Floating Pickup

**Files:**
- Create: `scenes/props/key_fragment_pickup.gd`
- Create: `scenes/props/key_fragment_pickup.tscn`
- Create: `tests/test_key_fragment_pickup_runtime.gd`
- Create: `tests/test_key_fragment_pickup_runtime.sh`
- Modify: `scenes/props/mob.gd`

**Interfaces:**
- Produces: `Mob.defeated(mob: CharacterBody2D)` emitted exactly once on lethal damage.
- Produces: `KeyFragmentPickup.configure(id: String, texture: Texture2D, prompt: String) -> void`.
- Produces: `KeyFragmentPickup.collection_requested(pickup: Area2D)` emitted once after an in-range E press.
- Produces: readable `item_id: String` for the Chapter 6 controller.

- [ ] **Step 1: Write the failing component runtime test**

Create `tests/test_key_fragment_pickup_runtime.gd` as a `SceneTree` test. It
must:

1. Instantiate `res://scenes/props/mob.tscn` with `max_health = 1`.
2. Connect `defeated`, apply lethal damage twice, wait 0.2 seconds, and require
   exactly one emission.
3. Instantiate `res://scenes/props/key_fragment_pickup.tscn`, call:

```gdscript
pickup.call(
	"configure",
	"lanka_key_fragment_shaft",
	load("res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png"),
	"กด E เพื่อเก็บชิ้นส่วนกุญแจ"
)
```

4. Require the visual Y position to change over several process frames.
5. Add a collision-layer-2 `CharacterBody2D` named `Player`, place it inside
   the pickup, wait for physics, and require `Prompt.visible`.
6. Send a non-echo pressed E event twice and require exactly one
   `collection_requested` emission and `item_id == "lanka_key_fragment_shaft"`.

Create `tests/test_key_fragment_pickup_runtime.sh`:

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-key-fragment-pickup}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_key_fragment_pickup_runtime.gd
```

- [ ] **Step 2: Run the component test to verify RED**

Run:

```bash
bash tests/test_key_fragment_pickup_runtime.sh
```

Expected: exit 1 because the pickup scene and mob defeat signal do not exist.

- [ ] **Step 3: Add a guarded defeat signal to Mob**

In `mob.gd`, add:

```gdscript
signal defeated(mob: CharacterBody2D)
var _defeated := false
```

Return early from damage methods after defeat. In the lethal branch of
`apply_authorized_damage()` set `_defeated = true`, emit `defeated(self)`
before the existing delay, then free the mob. This guard must make repeated
lethal calls harmless.

- [ ] **Step 4: Create the reusable pickup scene**

Create an `Area2D` with:

- `collision_mask = 2`
- one circular `CollisionShape2D` with radius 32
- `Visual` Node2D containing a Sprite2D
- a hidden Label named `Prompt` with Thai text, white font, black outline, and
  centered offsets above the item
- body-entered and body-exited signal connections

The script must keep `_elapsed`, `_player`, and `_collected` state. In
`_process(delta)`, assign:

```gdscript
_visual.position.y = sin(_elapsed * 3.0) * 6.0
```

`configure()` stores the item ID, texture, and prompt. `_ready()` applies the
texture and scales its longest side to 56 pixels. `_input()` accepts only a
pressed, non-echo E key while Player is in range, disables repeat collection,
hides the prompt, and emits `collection_requested(self)`.

- [ ] **Step 5: Run the component test to verify GREEN**

Run:

```bash
bash tests/test_key_fragment_pickup_runtime.sh
```

Expected: exit 0 with one defeat emission, visible bob motion, in-range prompt,
and one collection request.

- [ ] **Step 6: Review checkpoint**

Run `git diff --check`. Do not commit in the shared dirty working tree.

---

### Task 3: Connect Cutscene, Quest, Yak Drop, Inventory, and Restoration

**Files:**
- Create: `scenes/chapter_6/chapter_6.gd`
- Create: `tests/test_chapter_6_key_fragment_quest_runtime.gd`
- Create: `tests/test_chapter_6_key_fragment_quest_runtime.sh`
- Modify: `scenes/chapter_6/chapter_6.tscn`
- Modify: `scenes/cutscene/chapter_6_cutscene.gd`
- Modify: `tests/test_chapter_6_opening_cutscene.sh`

**Interfaces:**
- Consumes: the three inventory IDs and Chapter 6 GameState fields from Task 1.
- Consumes: `Mob.defeated` and `KeyFragmentPickup.collection_requested` from Task 2.
- Produces: `Chapter6.start_key_fragment_quest() -> void`.
- Produces: a runtime child named `YSortRoot/YakKeyFragmentPickup`.
- Produces: quest text derived from the three distinct inventory entries.

- [ ] **Step 1: Write the failing end-to-end runtime test**

Create `tests/test_chapter_6_key_fragment_quest_runtime.gd` as a `SceneTree`
test with helpers for scene changes and failure reporting. Reset inventory,
Quest, and both Yak GameState fields, then verify this sequence:

1. Load Chapter 6 with `chapter_6_intro_played = false`; QuestButton is hidden.
2. Call `Chapter6Cutscene._finish_cutscene()`.
3. Require the quest name and `รวบรวมชิ้นส่วนกุญแจ 0/3`.
4. Damage Yak Captain nonlethally and require no pickup.
5. Record Yak position, deal lethal damage, wait 0.2 seconds, and require one
   `YSortRoot/YakKeyFragmentPickup` at that position while inventory and quest
   remain `0/3`.
6. Change to the left room and back to Chapter 6. Require no Yak Captain and
   one restored pickup at the recorded position.
7. Move Player onto the pickup, require its prompt, send E, and require:

```gdscript
Inv.count("lanka_key_fragment_shaft") == 1
Inv.count("lanka_key_fragment_bar") == 0
Inv.count("lanka_key_fragment_ring") == 0
```

8. Require the pickup is freed and quest detail becomes
   `รวบรวมชิ้นส่วนกุญแจ 1/3`.
9. Re-enter Chapter 6 and require neither Yak Captain nor a pickup.

Create `tests/test_chapter_6_key_fragment_quest_runtime.sh` using a dedicated
`/private/tmp/codex-godot-chapter-6-key-quest` HOME and the same Godot
headless pattern as other runtime tests.

Extend `tests/test_chapter_6_opening_cutscene.sh` to require:

```sh
grep -Fq 'start_key_fragment_quest' "$cutscene"
grep -Fq 'res://scenes/chapter_6/chapter_6.gd' "$scene"
```

- [ ] **Step 2: Run integration tests to verify RED**

Run:

```bash
bash tests/test_chapter_6_key_fragment_quest_runtime.sh
bash tests/test_chapter_6_opening_cutscene.sh
```

Expected: runtime exit 1 because Chapter 6 has no quest controller, and the
opening-cutscene contract exits 1 because the hook/script references are
missing.

- [ ] **Step 3: Implement the Chapter 6 controller**

Create `chapter_6.gd` with:

```gdscript
extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const KeyFragmentPickup := preload("res://scenes/props/key_fragment_pickup.tscn")
const SHAFT_TEXTURE := preload(
	"res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png"
)
const FRAGMENT_IDS := [
	"lanka_key_fragment_shaft",
	"lanka_key_fragment_bar",
	"lanka_key_fragment_ring",
]
const QUEST_NAME := "ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง"
const QUEST_DETAIL := "รวบรวมชิ้นส่วนกุญแจ %d/3"
const YAK_AUTHORED_POSITION := Vector2(724, 445)
```

Resolve inventory and quest through `/root/Inv` and `/root/Quest` to avoid
adding more compile-time autoload coupling. In `_ready()`:

- connect inventory `changed` to quest refresh;
- if the shaft is owned or Yak is defeated, remove Yak;
- otherwise connect the Yak `defeated` signal;
- restore an uncollected pickup when defeated;
- call `start_key_fragment_quest()` immediately only when the intro flag is
  already true.

On defeat, set the flag, store `mob.global_position`, and spawn one configured
pickup. On collection, add the shaft only when its count is zero, clear the
stored position, and free the pickup. Compute progress as one per distinct
fragment ID, call `Quest.set_quest(QUEST_NAME, QUEST_DETAIL % count)`, and set
completion only at 3.

- [ ] **Step 4: Attach the controller and hook cutscene completion**

Add `chapter_6.gd` as an external script resource and assign it to the
Chapter6 root without changing existing node positions or collisions.

In `chapter_6_cutscene.gd::_finish_cutscene()`, after setting the intro flag
and unpausing but before freeing the cutscene layer:

```gdscript
var chapter := get_tree().current_scene
if chapter != null and chapter.has_method("start_key_fragment_quest"):
	chapter.call("start_key_fragment_quest")
```

This same function is used by normal completion and skip, so both paths start
the quest once.

- [ ] **Step 5: Run integration tests to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_key_fragment_quest_runtime.sh
bash tests/test_chapter_6_opening_cutscene.sh
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
```

Expected: all commands exit 0; the quest progresses from 0/3 to 1/3 only on
collection and existing Chapter 6 room flow remains intact.

- [ ] **Step 6: Review checkpoint**

Run `git diff --check`. Confirm no text between the Chapter 6 room `Walls` and
`YSortRoot` nodes changed during this task. Do not commit in the dirty shared
workspace.

---

### Task 4: Full Regression and Visual Asset Verification

**Files:**
- Verify all files from Tasks 1–3.
- Verify user-owned PNG and `.import` files under `assets/ui/icon/split/`.

**Interfaces:**
- Consumes: all prior task outputs.
- Produces: verified Chapter 6 key-fragment phase-one behavior.

- [ ] **Step 1: Run all focused tests with fail-fast behavior**

Run:

```bash
set -eu
bash tests/test_chapter_6_key_fragment_state.sh
bash tests/test_key_fragment_pickup_runtime.sh
bash tests/test_chapter_6_key_fragment_quest_runtime.sh
bash tests/test_chapter_6_opening_cutscene.sh
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_inventory_save_and_ending.sh
```

Expected: every command exits 0.

- [ ] **Step 2: Run every project test**

Run:

```bash
set -eu
passed_count=0
for test_file in tests/*.sh; do
	bash "$test_file"
	passed_count=$((passed_count + 1))
done
echo "VERIFIED_TESTS=$passed_count"
```

Expected: all pre-existing tests plus the three new scripts exit 0.

- [ ] **Step 3: Parse the project in Godot**

Run:

```bash
env HOME=/private/tmp/codex-godot-chapter-6-key-fragment-final \
	/Applications/Godot.app/Contents/MacOS/Godot \
	--headless --path . --editor --quit
```

Expected: exit 0 and editor initialization completes.

- [ ] **Step 4: Verify protected scope**

Run `git diff --check`, inspect `git diff --stat`, and compare the current
SHA-256 text hashes of both tower-room `Walls` sections to the baselines
recorded immediately before implementation. Require exact equality.

- [ ] **Step 5: Manual handoff**

Report the exact quest text, Yak fragment icon, interaction prompt,
persistence rules, test count, known pre-existing `--script` autoload warning
if still present, and the fact that room puzzles/gate unlocking remain
deferred.
