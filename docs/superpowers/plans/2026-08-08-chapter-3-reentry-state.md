# Chapter 3 Re-entry State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the correct Chapter 3 quest UI and remaining Jatayu feather pickups whenever the player returns from Chapter 2 without duplicating inventory rewards.

**Architecture:** Keep `GameState` and `Inv` as the persistent sources of truth. Add one idempotent Chapter 3 restoration entry point and let the already-played intro-cutscene branch defer that entry point until the chapter parent has finished `_ready()` signal wiring.

**Tech Stack:** Godot 4.7, GDScript, SceneTree headless runtime tests, POSIX shell test runner.

## Global Constraints

- The Chapter 3 introduction still plays only once.
- Do not add or migrate save fields.
- `Inv.count("jatayu_feather")` is the authoritative collected count.
- Never grant inventory items while reconstructing a scene.
- Remaining feathers may use new valid spawn points after re-entry.
- A completed Chapter 3 restores its Chapter 4 portal and exit quest without moving the player.

---

## File map

- `scenes/chapter_3/chapter_3.gd`: owns the public progress-restoration entry point and maps persistent state to the current quest/pickup presentation.
- `scenes/cutscene/chapter_3_cutscene.gd`: detects a previously played intro and defers restoration to the chapter controller.
- `tests/test_chapter_3_reentry_runtime.gd`: exercises inventory counts, visible pickups, quest text, completed-story state, and no-duplicate guarantees.
- `tests/run_chapter_3_reentry_tests.sh`: launches the focused headless test.

### Task 1: Specify Chapter 3 re-entry behavior with a failing runtime test

**Files:**
- Create: `tests/test_chapter_3_reentry_runtime.gd`
- Create: `tests/run_chapter_3_reentry_tests.sh`

**Interfaces:**
- Consumes: `Inv.restore_items(snapshot: Dictionary) -> void`, `Quest.snapshot() -> Dictionary`, `Quest.get_target_count() -> int`.
- Produces: a failing contract for `restore_chapter_3_progress() -> void` and the skipped-intro deferred hook.

- [ ] **Step 1: Add the focused headless test**

Create `tests/test_chapter_3_reentry_runtime.gd` with helpers that enter
`res://scenes/chapter_3/chapter_3.tscn` through the real `SceneTree`, set
`GameState.chapter_3_intro_played = true`, allow the skipped-intro branch to
run, and assert consumer-visible quest and pickup state:

```gdscript
extends SceneTree

const GameStateScript := preload("res://scenes/core/game_state.gd")
const CHAPTER_SCENE := preload("res://scenes/chapter_3/chapter_3.tscn")
var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for collected in [0, 1, 2]:
		await _check_feather_progress(collected)
	await _check_rest_quest()
	await _check_completed_story()
	_finish()

func _check_feather_progress(collected: int) -> void:
	var chapter := await _enter_chapter(collected, false)
	var before := Inv.count("jatayu_feather")
	var snapshot: Dictionary = Quest.snapshot()
	_expect(snapshot.get("name") == "ตามหาขนนกพญาชฎายุ", "feather quest restored")
	_expect(snapshot.get("detail", "").contains("%d/3" % collected), "saved count restored")
	_expect(Quest.get_target_count() == 3 - collected, "remaining targets restored")
	_expect(_visible_feather_count(chapter) == 3 - collected, "remaining pickups restored")
	_expect(Inv.count("jatayu_feather") == before, "restoration grants no feather")

func _check_rest_quest() -> void:
	await _enter_chapter(3, false)
	_expect(Quest.snapshot().get("name") == "พักผ่อนใต้ต้นไม้ใหญ่", "rest quest restored")
	_expect(Inv.count("jatayu_feather") == 3, "completed inventory remains unchanged")

func _check_completed_story() -> void:
	var chapter := await _enter_chapter(3, true)
	_expect(Quest.snapshot().get("name") == "ตามรอยทศกัณฐ์", "exit quest restored")
	_expect(not chapter.get_node("YSortRoot/Chapter4Portal").locked, "Chapter 4 portal restored")
	_expect(Inv.count("jatayu_feather") == 3, "story restoration grants no feather")

func _enter_chapter(collected: int, post_battle: bool) -> Node2D:
	Quest.clear()
	Inv.restore_items({"potion": 3, "jatayu_feather": collected})
	GameStateScript.chapter_3_intro_played = true
	GameStateScript.chapter_3_post_battle_played = post_battle
	var error := change_scene_to_packed(CHAPTER_SCENE)
	_expect(error == OK, "Chapter 3 scene change starts")
	await process_frame
	await process_frame
	return current_scene

func _visible_feather_count(chapter: Node2D) -> int:
	var visible_count := 0
	for feather_name in ["Feather1", "Feather2", "Feather3"]:
		var feather := chapter.get_node("YSortRoot/%s" % feather_name) as Area2D
		if feather.visible and feather.monitoring:
			visible_count += 1
	return visible_count

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	GameStateScript.reset_progress()
	Inv.reset_for_new_story()
	if _failures.is_empty():
		print("PASS: Chapter 3 re-entry state")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

Create `tests/run_chapter_3_reentry_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-3-reentry-test.log \
  --path . --script res://tests/test_chapter_3_reentry_runtime.gd
```

- [ ] **Step 2: Run the focused test and confirm the new contract fails**

Run: `sh tests/run_chapter_3_reentry_tests.sh`

Expected: FAIL because `restore_chapter_3_progress()` and the skipped-intro hook do not exist; current re-entry leaves no quest and zero active feathers.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/test_chapter_3_reentry_runtime.gd tests/run_chapter_3_reentry_tests.sh
git commit -m "test: cover chapter 3 re-entry state"
```

### Task 2: Restore Chapter 3 from GameState and inventory

**Files:**
- Modify: `scenes/chapter_3/chapter_3.gd:57-83,198-202`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd:39-48`
- Test: `tests/test_chapter_3_reentry_runtime.gd`

**Interfaces:**
- Consumes: `start_feather_quest() -> void`, `Inv.count(id: String) -> int`, `GameState.chapter_3_post_battle_played`.
- Produces: `restore_chapter_3_progress() -> void`, safe to call more than once per scene instance.

- [ ] **Step 1: Add the idempotent restoration entry point**

Add to `chapter_3.gd`:

```gdscript
func restore_chapter_3_progress() -> void:
	if GameState.chapter_3_post_battle_played:
		_chapter4_portal.set_locked(false)
		Quest.set_quest(EXIT_QUEST_NAME, EXIT_QUEST_DETAIL, _chapter4_portal.global_position)
		return
	start_feather_quest()
```

Keep `_ready()` responsible for clearing old presentation, hiding all feather nodes, and connecting every signal before restoration can run. Remove no inventory items and do not call `finish_chapter_3_story()`, because that method deliberately moves the player for the cutscene ending.

- [ ] **Step 2: Defer restoration only when the intro is skipped**

In the `GameState.chapter_3_intro_played` branch of `chapter_3_cutscene.gd`, resolve the chapter node before freeing the cutscene layer and schedule restoration after the parent `_ready()` completes:

```gdscript
if GameState.chapter_3_intro_played:
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("restore_chapter_3_progress"):
		chapter.call_deferred("restore_chapter_3_progress")
	var cutscene_layer := get_parent()
	if cutscene_layer is CanvasLayer:
		cutscene_layer.queue_free()
	else:
		queue_free()
	return
```

Do not call this branch during the first intro. `_finish_cutscene()` remains the first-visit path that calls `start_feather_quest()`.

- [ ] **Step 3: Run the focused test**

Run: `sh tests/run_chapter_3_reentry_tests.sh`

Expected: PASS with `PASS: Chapter 3 re-entry state`.

- [ ] **Step 4: Run existing Chapter quest regressions**

Run:

```bash
sh tests/run_chapter_quest_flow_tests.sh
sh tests/run_chapter_quest_state_tests.sh
```

Expected: both runners exit 0 and print their existing PASS messages.

- [ ] **Step 5: Commit the restoration fix**

```bash
git add scenes/chapter_3/chapter_3.gd scenes/cutscene/chapter_3_cutscene.gd
git commit -m "fix: restore chapter 3 feather quest on re-entry"
```

### Task 3: Verify the reported transition path

**Files:**
- Verify: `scenes/chapter_3/chapter_3.gd`
- Verify: `scenes/cutscene/chapter_3_cutscene.gd`
- Test: `tests/test_chapter_3_reentry_runtime.gd`

**Interfaces:**
- Consumes: the completed restoration implementation.
- Produces: evidence that the reported Chapter 3 → Chapter 2 → Chapter 3 path is fixed.

- [ ] **Step 1: Run the complete focused and quest test set from a clean process**

```bash
sh tests/run_chapter_3_reentry_tests.sh
sh tests/run_chapter_quest_flow_tests.sh
sh tests/run_chapter_quest_state_tests.sh
```

Expected: all three commands exit 0.

- [ ] **Step 2: Manually reproduce in Godot**

Start a game, finish the Chapter 3 intro, collect zero or some feathers, press E to return to Chapter 2, press E to enter Chapter 3 again, and verify the quest UI count matches inventory and exactly the uncollected feathers remain visible and interactive.

- [ ] **Step 3: Inspect the final diff**

Run: `git diff --check HEAD~2..HEAD`

Expected: no whitespace errors or unrelated Chapter/audio changes.
