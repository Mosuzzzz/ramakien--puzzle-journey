# Chapter 3 Jatayu Feather Quest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Chapter 3's monster quiz quest with three interactive Jatayu feathers that award permanent inventory items, persist through save/load, and reset at the Ending with the default three healing potions.

**Architecture:** A reusable `Area2D` feather scene owns proximity, prompt, bobbing, and fade presentation while `chapter_3.gd` owns quest state, random spawn assignment, quiz coordination, inventory rewards, and cutscene transition. The inventory autoload gains explicit snapshot/restore/reset APIs, and `SaveGame` serializes that snapshot so Chapter transitions and saved sessions share one source of truth.

**Tech Stack:** Godot 4.7, GDScript, Godot scene resources (`.tscn`), headless SceneTree runtime tests, POSIX shell contract tests.

## Global Constraints

- Do not run Git commands, create commits, switch branches, push, or merge.
- Use `res://assets/ui/icon/split/icon_wing.png` for both the world feather and inventory item.
- Keep shared `scenes/props/mob.gd`, `scenes/ui/question_quiz.gd`, and `scenes/ui/quest_log.gd` behavior unchanged unless verification proves a compatibility fix is necessary.
- Monsters in Chapter 3 take normal damage and never open the quiz.
- Three feathers are active at once, each with a quest marker, and a wrong answer relocates only that feather to an unoccupied spawn point.
- Completing 3/3 immediately starts the existing Chapter 3 follow-up cutscene exactly once.
- Inventory survives Chapter changes and save/load; leaving the Ending for a new story clears every item and restores healing potions to exactly 3.

---

### Task 1: Persistent inventory API and Jatayu feather catalog

**Files:**
- Modify: `scenes/ui/inventory.gd`
- Create: `tests/test_inventory_persistence_runtime.gd`
- Create: `tests/test_inventory_persistence.sh`

**Interfaces:**
- Consumes: existing `Inv.add_item(id: String, n: int = 1)`, `Inv.count(id: String)`.
- Produces: `get_items_snapshot() -> Dictionary`, `restore_items(snapshot: Dictionary) -> void`, and `reset_for_new_story() -> void`.

- [ ] **Step 1: Write a failing inventory runtime test**

Create a `SceneTree` test that resolves the `Inv` autoload and verifies the new API:

```gdscript
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var inv := root.get_node("Inv")
	inv.call("restore_items", {"potion": 2, "jatayu_feather": 3, "key": 1})
	var snapshot: Dictionary = inv.call("get_items_snapshot")
	snapshot["jatayu_feather"] = 99
	if int(inv.call("count", "jatayu_feather")) != 3:
		return _fail("Inventory snapshot leaked a shared dictionary reference")
	inv.call("reset_for_new_story")
	if int(inv.call("count", "potion")) != 3:
		return _fail("Ending reset did not restore three healing potions")
	if int(inv.call("count", "jatayu_feather")) != 0 or int(inv.call("count", "key")) != 0:
		return _fail("Ending reset kept a non-potion item")
	print("Inventory persistence runtime passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_inventory_persistence_runtime.gd
```

Expected: FAIL because `restore_items`, `get_items_snapshot`, and `reset_for_new_story` do not exist.

- [ ] **Step 3: Add the feather item and inventory state APIs**

Add the catalog entry and methods to `inventory.gd`:

```gdscript
"jatayu_feather": {
	"name": "ขนนกพญาชฎายุ",
	"icon": "res://assets/ui/icon/split/icon_wing.png",
},

func get_items_snapshot() -> Dictionary:
	return items.duplicate(true)

func restore_items(snapshot: Dictionary) -> void:
	items = snapshot.duplicate(true)
	changed.emit()
	if _page.visible:
		_refresh()

func reset_for_new_story() -> void:
	items = {"potion": 3}
	changed.emit()
	if _page.visible:
		_refresh()
```

Keep `add_item` as the only reward mutation used by Chapter 3.

- [ ] **Step 4: Add and run the static inventory contract**

Create `tests/test_inventory_persistence.sh` with exact checks for the item id, Thai label, wing asset, and three method signatures. Run:

```bash
sh tests/test_inventory_persistence.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_inventory_persistence_runtime.gd
```

Expected: both PASS.

---

### Task 2: Save/load inventory and reset it at the Ending

**Files:**
- Modify: `scenes/core/save_game.gd`
- Modify: `scenes/ending/ending.gd`
- Create: `tests/test_save_inventory_runtime.gd`
- Create: `tests/test_ending_inventory_reset.sh`

**Interfaces:**
- Consumes: Task 1's `Inv.get_items_snapshot()`, `Inv.restore_items(snapshot)`, and `Inv.reset_for_new_story()`.
- Produces: save JSON key `inventory`; old save data without that key remains loadable.

- [ ] **Step 1: Write failing save compatibility tests**

In `test_save_inventory_runtime.gd`, save known items, alter the live inventory, load the slot, wait one process frame, then assert the original item counts returned. Also write a legacy slot dictionary without `inventory`, load it, and assert no inventory replacement or error occurs.

Core assertions:

```gdscript
inv.call("restore_items", {"potion": 4, "jatayu_feather": 2})
SaveGame.save_to_slot(2)
inv.call("restore_items", {"potion": 1})
SaveGame.load_slot(2)
await process_frame
assert(int(inv.call("count", "potion")) == 4)
assert(int(inv.call("count", "jatayu_feather")) == 2)
```

The test must clean up slot 2 using `SaveGame.delete_slot(2)` on success and failure.

- [ ] **Step 2: Run the save test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_save_inventory_runtime.gd
```

Expected: FAIL because save data does not contain inventory.

- [ ] **Step 3: Serialize and restore inventory**

Extend `save_to_slot()`:

```gdscript
var inventory := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Inv")
if inventory != null and inventory.has_method("get_items_snapshot"):
	data["inventory"] = inventory.call("get_items_snapshot")
```

Extend `load_slot()` before the deferred scene change:

```gdscript
var inventory := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Inv")
if data.has("inventory") and inventory != null and inventory.has_method("restore_items"):
	inventory.call("restore_items", data["inventory"])
```

Do not replace inventory for legacy saves lacking the key.

- [ ] **Step 4: Connect Ending confirmation to the reset API**

Before `change_scene_to_file()` in `ending.gd`, call:

```gdscript
if is_instance_valid(Inv):
	Inv.reset_for_new_story()
```

Do not reset in `_ready()`; opening the Ending screen alone must preserve the current inventory.

- [ ] **Step 5: Verify persistence, legacy compatibility, and Ending wiring**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_save_inventory_runtime.gd
sh tests/test_ending_inventory_reset.sh
```

Expected: both PASS; slot 2 is removed after the runtime test.

---

### Task 3: Reusable interactive feather scene

**Files:**
- Create: `scenes/chapter_3/jatayu_feather.gd`
- Create: `scenes/chapter_3/jatayu_feather.tscn`
- Create: `tests/test_jatayu_feather_runtime.gd`
- Create: `tests/test_jatayu_feather_scene.sh`

**Interfaces:**
- Produces signal `collection_requested(feather: Area2D)`.
- Produces methods `set_interaction_enabled(enabled: bool)`, `fade_out() -> void`, `restore_at(world_position: Vector2) -> void`, and `mark_collected() -> void`.
- Chapter controller connects to `collection_requested` and owns all quiz and reward state.

- [ ] **Step 1: Write the failing feather behavior test**

Instantiate the scene, assert its texture path and prompt, call its interaction method, and verify it emits exactly once while enabled and not at all while disabled. Start the bob tween and verify its sprite Y position changes without changing the root spawn position.

Use:

```gdscript
var feather := (load("res://scenes/chapter_3/jatayu_feather.tscn") as PackedScene).instantiate()
root.add_child(feather)
var requested := 0
feather.collection_requested.connect(func(_node): requested += 1)
feather.call("_request_collection")
feather.call("_request_collection")
assert(requested == 1)
```

- [ ] **Step 2: Run the test and verify the scene is missing**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_jatayu_feather_runtime.gd
```

Expected: FAIL loading `jatayu_feather.tscn`.

- [ ] **Step 3: Build the scene**

Create an `Area2D` root with:

- `Sprite2D` using `icon_wing.png`
- `CollisionShape2D` using a `CircleShape2D` interaction radius
- centered `Label` with `กด E เพื่อเก็บขนนก`, hidden by default

Set `process_mode = PROCESS_MODE_ALWAYS` so visual cleanup remains deterministic around paused quiz state, but reject interaction while the quiz lock is active.

- [ ] **Step 4: Implement proximity, bobbing, fade, and restore**

The script must:

```gdscript
signal collection_requested(feather: Area2D)

var _player_nearby := false
var _interaction_enabled := true
var _request_pending := false

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and _interaction_enabled and event.is_action_pressed("interact"):
		_request_collection()

func _request_collection() -> void:
	if not _interaction_enabled or _request_pending:
		return
	_request_pending = true
	_prompt.hide()
	collection_requested.emit(self)
```

Use a looping tween on the child sprite's local Y, not on the root position. `fade_out()` awaits a modulate alpha tween; `restore_at()` changes `global_position`, restores alpha, clears pending state, and restarts bobbing. `mark_collected()` leaves the node hidden and disabled.

- [ ] **Step 5: Run scene contract and runtime tests**

Run:

```bash
sh tests/test_jatayu_feather_scene.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_jatayu_feather_runtime.gd
```

Expected: both PASS.

---

### Task 4: Replace Chapter 3 monster quest with feather quest

**Files:**
- Modify: `scenes/chapter_3/chapter_3.gd`
- Modify: `scenes/chapter_3/chapter_3.tscn`
- Modify: `tests/test_chapter_3_monster_quiz.sh`
- Replace: `tests/test_chapter_3_monster_quiz_runtime.gd`
- Modify: `tests/test_chapter_3_patrol_quest.sh`
- Replace: `tests/test_chapter_3_patrol_flow_runtime.gd`

**Interfaces:**
- Consumes: Task 3's feather signal/methods, existing `QuestionQuiz.answered(correct)`, `Quest.set_targets(nodes)`, and Task 1's `Inv.add_item()`.
- Produces: `start_feather_quest()`, `_on_feather_collection_requested(feather)`, `_on_quiz_answered(correct)`, and completion transition to the existing post-battle cutscene.

- [ ] **Step 1: Rewrite the Chapter 3 runtime test for normal monsters**

Verify `Mob1` and `Mob2` have no `damage_gate`, take immediate damage on both hits, die normally, never make `QuestionQuiz` visible, and never set `_post_battle_cutscene_started`.

Key assertions:

```gdscript
assert(mob1.get("damage_gate") == null)
mob1.call("take_damage", 15)
mob1.call("take_damage", 15)
assert(not quiz.visible)
assert(not bool(chapter.get("_post_battle_cutscene_started")))
```

- [ ] **Step 2: Rewrite the quest flow runtime test for three feathers**

Call `start_feather_quest()`, assert 3 active targets and `0/3`, request a feather, verify one of the two exact questions appears, submit a correct answer, and assert inventory/progress become x1 and 1/3. Submit a wrong answer to a different feather, await its fade/restore, and assert progress stays 1/3 and its spawn index changed. Finish all three correctly and assert:

- Quest detail is `3/3`
- text is `Color("#67d56b")`
- inventory contains three feathers
- no active quest targets remain
- `_post_battle_cutscene_started` is true exactly once

- [ ] **Step 3: Run the rewritten tests and verify they fail**

Run:

```bash
sh tests/test_chapter_3_monster_quiz.sh
sh tests/test_chapter_3_patrol_quest.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_chapter_3_monster_quiz_runtime.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_chapter_3_patrol_flow_runtime.gd
```

Expected: FAIL because the current controller still gates monster damage and has no feathers.

- [ ] **Step 4: Replace monster quiz state with feather quest state**

In `chapter_3.gd`:

- replace `PATROL_TOTAL`, `PATROL_QUEST_NAME`, and `MONSTER_QUESTIONS` with `FEATHER_TOTAL := 3`, quest strings, and a two-entry `FEATHER_QUESTIONS` array
- remove `_pending_quiz_mob`, `_pending_quiz_damage`, `request_mob_damage`, patrol mob tracking, and all `damage_gate` assignments
- add six walkable `Vector2` spawn positions
- add active feather, occupied index, collected count, pending feather, quiz lock, and RNG state
- keep the existing Hanuman, portal, and cutscene callbacks

The correct answer branch must call:

```gdscript
await pending_feather.fade_out()
pending_feather.mark_collected()
Inv.add_item("jatayu_feather", 1)
_feathers_collected += 1
_update_feather_quest()
```

The wrong branch must choose an unoccupied index different from the current one, await fade, update occupancy, call `restore_at()`, and refresh quest targets.

- [ ] **Step 5: Add three feather instances to the Chapter 3 scene**

Add the feather scene as an external resource and create `Feather1`, `Feather2`, and `Feather3` under `YSortRoot`. Connect them at runtime in `_ready()` to avoid brittle signal declarations. Define six spawn points in the controller and assign three unique positions when the opening cutscene invokes the quest.

- [ ] **Step 6: Keep the opening cutscene callback compatible**

Either rename the opening callback call from `start_patrol_quest` to `start_feather_quest`, or keep a short compatibility wrapper:

```gdscript
func start_patrol_quest() -> void:
	start_feather_quest()
```

Prefer updating `scenes/cutscene/chapter_3_cutscene.gd` to the new semantic name if its test contract is updated in the same step.

- [ ] **Step 7: Run all Chapter 3 tests**

Run:

```bash
sh tests/test_chapter_3_monster_quiz.sh
sh tests/test_chapter_3_patrol_quest.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_chapter_3_monster_quiz_runtime.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_chapter_3_patrol_flow_runtime.gd
```

Expected: all PASS.

---

### Task 5: Full regression and visual verification

**Files:**
- Modify only files proven necessary by a failing regression.

**Interfaces:**
- Consumes all previous tasks.
- Produces a verified Chapter 3 flow with persistence and Ending reset.

- [ ] **Step 1: Run every shell contract test**

Run:

```bash
for test_file in tests/*.sh; do sh "$test_file"; done
```

Expected: all scripts print their pass messages and exit 0.

- [ ] **Step 2: Run every relevant headless runtime test**

Run:

```bash
for test_file in \
  tests/test_inventory_persistence_runtime.gd \
  tests/test_save_inventory_runtime.gd \
  tests/test_jatayu_feather_runtime.gd \
  tests/test_chapter_3_monster_quiz_runtime.gd \
  tests/test_chapter_3_patrol_flow_runtime.gd; do
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "$test_file"
done
```

Expected: every process exits 0 without parser, resource, or orphan-node errors.

- [ ] **Step 3: Open Chapter 3 in the editor and perform manual flow QA**

Verify:

1. Opening cutscene finishes and three bobbing wing icons appear at separate walkable positions.
2. All three have round quest markers; monsters do not.
3. Monsters die through normal combat without questions or cutscene transition.
4. E near a feather opens one of the two Thai questions.
5. Wrong answer fades and moves that feather elsewhere.
6. Correct answer hides it, updates 1/3–3/3, and increments the inventory item.
7. At 3/3 the text is green and the existing follow-up cutscene begins once.
8. After all Chapter 3 cutscenes, the exit quest points to Chapter 4.

- [ ] **Step 4: Perform manual save and Ending QA**

Verify:

1. Save with at least one feather, return to menu, and load; item counts are unchanged.
2. Change Chapter; feather count remains unchanged.
3. Reach the Ending; inventory is still unchanged while the Ending is visible.
4. Press the Ending continuation key; the new story starts with exactly three healing potions and no other items.
5. No Git operation has been performed.
