# Modal Pause and Run Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop world simulation and clear stale run audio while foreground cutscenes, dialogue, narration, quizzes, or puzzle modals are active, then resume held movement normally after the interaction closes.

**Architecture:** Keep the shared run loop centralized in `AudioManager`; its always-processing update clears movement owners whenever the `SceneTree` is paused. Make `DialogueManager` participate in the existing pause convention by capturing the prior tree pause state, pausing on open, and restoring the captured state before emitting `finished` on close.

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree runtime tests, Git.

## Global Constraints

- Existing cutscenes, quizzes, matching puzzles, and Chapter 6 puzzle modals keep their current pause calls and timings.
- Dialogue and narration pause player movement, enemies, combat, and world simulation while their UI remains interactive.
- Closing dialogue restores the tree state that existed before the dialogue opened.
- Unpausing alone never restarts a stale run owner; real movement must register again.
- A held movement key resumes movement and run audio on the first unpaused player physics update.
- Music, non-run SFX, scene transitions, question correctness, and pause-menu behavior remain unchanged.
- Preserve the user's uncommitted `scenes/chapter_1/chapter_1.tscn` modification and unrelated asset deletions.

---

### Task 1: Clear Shared Run Audio When Gameplay Pauses

**Files:**
- Modify: `tests/test_audio_manager_runtime.gd`
- Modify: `scenes/core/audio_manager.gd`

**Interfaces:**
- Consumes: `AudioManager.set_run_active(owner: Node, active: bool) -> void`
- Consumes: `AudioManager.stop_run_loop() -> void`
- Produces: `AudioManager._process(delta: float) -> void` clears the run loop and owner registry whenever `get_tree().paused` is true

- [ ] **Step 1: Write the failing runtime regression test**

In `tests/test_audio_manager_runtime.gd`, immediately after the existing final-owner run-loop assertion, add:

```gdscript
		audio.set_run_active(owner_a, true)
		_expect(audio.get_node("RunLoop").playing, "run loop is active before pause")
		paused = true
		audio._process(0.0)
		_expect(not audio.get_node("RunLoop").playing, "tree pause stops run loop")
		paused = false
		audio._process(0.0)
		_expect(
			not audio.get_node("RunLoop").playing,
			"unpause does not revive stale movement owner"
		)
		audio.set_run_active(owner_a, true)
		_expect(
			audio.get_node("RunLoop").playing,
			"fresh movement registration restarts run loop"
		)
		audio.set_run_active(owner_a, false)
```

The production mutation this test catches is removing the pause guard or retaining stale run owners across an unpause.

- [ ] **Step 2: Run the manager test and verify RED**

Run:

```bash
sh tests/run_audio_manager_tests.sh
```

Expected: FAIL at `tree pause stops run loop` because the existing always-processing manager continues refreshing the registered run owner while the player is frozen.

- [ ] **Step 3: Implement the minimal central pause guard**

In `scenes/core/audio_manager.gd`, change `_process` to preserve scene-music synchronization and stop before owner pruning while paused:

```gdscript
func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	if scene_id != _last_scene_id:
		_last_scene_id = scene_id
		_sync_music_for_current_scene()
	if get_tree().paused:
		stop_run_loop()
		return
	_prune_run_owners()
```

`stop_run_loop()` already clears `_run_owners` and stops `RunLoop`, so unpausing cannot revive a stale owner.

- [ ] **Step 4: Run focused audio tests and verify GREEN**

Run:

```bash
sh tests/run_audio_manager_tests.sh
sh tests/run_player_audio_tests.sh
sh tests/run_world_movement_audio_tests.sh
```

Expected: all three runners print `PASS` and exit 0.

- [ ] **Step 5: Commit the central run-loop fix**

```bash
git add scenes/core/audio_manager.gd tests/test_audio_manager_runtime.gd
git commit -m "fix: stop run audio while gameplay is paused"
```

### Task 2: Pause and Restore the World Around Dialogue

**Files:**
- Modify: `tests/test_story_advance_audio.gd`
- Modify: `scenes/ui/dialogue_manager.gd`

**Interfaces:**
- Consumes: `DialogueManager.start(speaker: String, lines: Array[String]) -> void`
- Consumes: `DialogueManager.start_narration(lines: Array[String], title: String = "", background: Texture2D = null) -> void`
- Produces: `DialogueManager._capture_and_pause_world() -> void`
- Produces: dialogue close restores the captured `SceneTree.paused` value before emitting `finished`

- [ ] **Step 1: Extend the dialogue runtime test with pause-state behavior**

In `tests/test_story_advance_audio.gd`, replace the existing final-dialogue block with the following literal behavior checks:

```gdscript
	_events.clear()
	var dialogue := root.get_node("Dialogue")
	var lines: Array[String] = ["บรรทัดสุดท้าย"]
	paused = false
	dialogue.start("", lines)
	_expect(paused, "dialogue pauses an active game world")
	dialogue._input(key_event)
	_expect(_events == [&"button_click"], "final dialogue close sounds once")
	_expect(not dialogue.is_active, "final dialogue input closes dialogue")
	_expect(not paused, "dialogue restores an originally active game world")

	_events.clear()
	paused = true
	dialogue.start("", lines)
	_expect(paused, "dialogue preserves an existing pause while open")
	dialogue._input(key_event)
	_expect(not dialogue.is_active, "paused-world dialogue still accepts input")
	_expect(paused, "dialogue does not unpause a previously paused world")
	paused = false

	var empty_lines: Array[String] = []
	dialogue.start("", empty_lines)
	_expect(not paused, "empty dialogue does not change pause state")
	dialogue.start_narration(lines)
	_expect(paused, "narration pauses an active game world")
	dialogue._input(key_event)
	_expect(not dialogue.is_active, "narration accepts final advance input")
	_expect(not paused, "narration restores the active game world")
```

The production mutations these assertions catch are failing to pause either dialogue path, pausing on an empty request, and unconditionally assigning `paused = false` on close.

- [ ] **Step 2: Run the story test and verify RED**

Run:

```bash
sh tests/run_story_advance_audio_tests.sh
```

Expected: FAIL at `dialogue pauses an active game world` because `DialogueManager` currently only shows UI and sets `is_active`.

- [ ] **Step 3: Add explicit pause ownership to DialogueManager**

In `scenes/ui/dialogue_manager.gd`, add state next to the existing dialogue fields:

```gdscript
var _pause_state_before_open := false
var _has_pause_snapshot := false
```

Add this helper before `start`:

```gdscript
func _capture_and_pause_world() -> void:
	if not is_active:
		_pause_state_before_open = get_tree().paused
		_has_pause_snapshot = true
	get_tree().paused = true
```

Call `_capture_and_pause_world()` after each empty-lines guard and before setting `is_active = true` in both `start` and `start_narration`:

```gdscript
func start(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_capture_and_pause_world()
	_lines = lines
	_index = 0
	_is_narration = false
	is_active = true
	_name_label.text = speaker
	_name_tag.visible = speaker != ""
	_box.show()
	_show_line()
```

```gdscript
func start_narration(lines: Array[String], title: String = "", background: Texture2D = null) -> void:
	if lines.is_empty():
		return
	_capture_and_pause_world()
	_lines = lines
	_index = 0
	_is_narration = true
	is_active = true
	_chapter_title.visible = title != ""
	_chapter_title_label.text = title
	_bg_image.texture = background
	_bg_image.visible = background != null
	_bg_tint.visible = background != null
	_backdrop.visible = background == null
	_narration.show()
	_show_line()
```

Replace `_close` with a restore-before-signal implementation:

```gdscript
func _close() -> void:
	is_active = false
	_box.hide()
	_narration.hide()
	if _has_pause_snapshot:
		get_tree().paused = _pause_state_before_open
		_has_pause_snapshot = false
	finished.emit()
```

Restoring before `finished.emit()` lets a signal listener safely open the next dialogue and capture the restored state.

- [ ] **Step 4: Run dialogue, player, and puzzle tests and verify GREEN**

Run:

```bash
sh tests/run_story_advance_audio_tests.sh
sh tests/run_player_audio_tests.sh
sh tests/run_puzzle_audio_tests.sh
```

Expected: all three runners print `PASS` and exit 0.

- [ ] **Step 5: Parse the project to verify always-processing UI remains valid**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-modal-pause-dialogue-parse.log \
  --editor --path . --quit
```

Expected: exit 0 with no `SCRIPT ERROR` or GDScript parse error.

- [ ] **Step 6: Commit dialogue pause ownership**

```bash
git add scenes/ui/dialogue_manager.gd tests/test_story_advance_audio.gd
git commit -m "fix: pause gameplay during dialogue"
```

### Task 3: Integrated Verification

**Files:**
- Verify only; do not stage or modify `scenes/chapter_1/chapter_1.tscn` or the user's unrelated asset deletions

**Interfaces:**
- Consumes: Task 1 central pause guard and Task 2 dialogue pause ownership
- Produces: fresh evidence that modal pause behavior works without audio or project regressions

- [ ] **Step 1: Run every runtime test runner**

Run:

```bash
for test_script in tests/run_*_tests.sh; do
  sh "$test_script" || exit 1
done
```

Expected: every runner prints `PASS` and the loop exits 0. Existing macOS certificate and ObjectDB shutdown diagnostics may still appear, but no test may fail.

- [ ] **Step 2: Parse/import the complete Godot project**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-modal-pause-final-parse.log \
  --editor --path . --quit
```

Expected: exit 0 with no `SCRIPT ERROR` or GDScript parse error.

- [ ] **Step 3: Smoke-launch the main scene**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-modal-pause-final-smoke.log \
  --path . --quit-after 120
```

Expected: exit 0 with no gameplay or script errors.

- [ ] **Step 4: Verify repository boundaries**

Run:

```bash
git diff --check
git status --short --branch
```

Expected: no whitespace errors. The user's pre-existing `scenes/chapter_1/chapter_1.tscn` modification and unrelated asset deletions remain outside all task commits.
