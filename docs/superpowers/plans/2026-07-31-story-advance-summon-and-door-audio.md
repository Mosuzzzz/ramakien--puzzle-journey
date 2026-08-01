# Story Advance, Repeated Summon, and Door Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play one button cue for every accepted story advance or close action, guarantee one invite cue for each Miyarap summon cycle, and raise only the door cue to 1.5 gain.

**Architecture:** Keep story-input validation in the existing shared `CutsceneAdvanceInput` helper, and route accepted events through one new consuming method that plays the cue exactly once. DialogueManager and every dedicated cutscene call that helper; skip buttons continue through AudioManager's existing global button hook. Extend AudioManager with per-sound gain applied on every pooled-player reuse, and protect Miyarap's already per-cycle summon call with a repeated-cycle regression test.

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree runtime tests, Git.

## Global Constraints

- Use the existing `assets/audio/sfx/button_click.mp3`; it is byte-identical to the newly supplied file.
- Accepted E, accepted left-click, and the final close input each play exactly one `button_click` cue.
- A cutscene skip button plays exactly one cue through the existing `BaseButton` hook.
- Invalid inputs, repeated key events, right clicks, button-hover clicks, and transition-blocked inputs stay silent.
- Each Miyarap summon cycle plays one `invite` cue, not one cue per spawned minion.
- Door gain is 1.5 linear; every other SFX defaults to 1.0.
- Do not alter user Music/SFX bus settings, story timing, scene transitions, cooldowns, or minion limits.
- Preserve the user's uncommitted `scenes/chapter_1/chapter_1.tscn` change.

---

### Task 1: Shared accepted-story-input audio and DialogueManager

**Files:**
- Create: `tests/test_story_advance_audio.gd`
- Create: `tests/run_story_advance_audio_tests.sh`
- Modify: `scenes/ui/cutscene_advance_input.gd`
- Modify: `scenes/ui/dialogue_manager.gd`

**Interfaces:**
- Consumes: `AudioManager.play_sfx(sound_key: StringName) -> void` and `AudioManager.BUTTON_CLICK`
- Produces: `CutsceneAdvanceInput.consume_advance_event(event: InputEvent, hovered_control: Control) -> bool`

- [ ] **Step 1: Write the failing real-input runtime test**

Create `tests/test_story_advance_audio.gd`. Connect to `AudioManager.sfx_played`, build literal key and mouse events, and assert the new consuming API:

```gdscript
extends SceneTree

const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

var _failures: Array[String] = []
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioManager")
	audio.sfx_played.connect(func(key: StringName): _events.append(key))

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	_expect(
		CutsceneAdvanceInput.consume_advance_event(key_event, null),
		"accepted E is consumed"
	)
	_expect(_events == [&"button_click"], "accepted E sounds once")

	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	_events.clear()
	_expect(
		CutsceneAdvanceInput.consume_advance_event(click_event, null),
		"accepted click is consumed"
	)
	_expect(_events == [&"button_click"], "accepted click sounds once")

	_events.clear()
	var button := Button.new()
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(click_event, button),
		"button-hover click belongs to the button"
	)
	_expect(_events.is_empty(), "button-hover click does not add story sound")
	button.free()

	_events.clear()
	Dialogue.start("", ["บรรทัดสุดท้าย"])
	Dialogue._input(key_event)
	_expect(_events == [&"button_click"], "final dialogue close sounds once")
	_expect(not Dialogue.is_active, "final dialogue input closes dialogue")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: story advance audio")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

Create `tests/run_story_advance_audio_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-story-advance-audio-test.log \
  --path . --script res://tests/test_story_advance_audio.gd
```

- [ ] **Step 2: Run the new test and verify RED**

Run: `chmod +x tests/run_story_advance_audio_tests.sh && sh tests/run_story_advance_audio_tests.sh`

Expected: FAIL because `consume_advance_event` does not exist and DialogueManager does not play the cue.

- [ ] **Step 3: Implement the shared consuming helper**

Add to `scenes/ui/cutscene_advance_input.gd`:

```gdscript
static func consume_advance_event(event: InputEvent, hovered_control: Control) -> bool:
	if not is_advance_event(event, hovered_control):
		return false
	AudioManager.play_sfx(AudioManager.BUTTON_CLICK)
	return true
```

This method keeps `is_advance_event` pure so existing mouse prefilters do not produce duplicate sounds.

- [ ] **Step 4: Route DialogueManager through the shared helper**

At the top of `scenes/ui/dialogue_manager.gd`, add:

```gdscript
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")
```

Replace `_input` with:

```gdscript
func _input(event: InputEvent) -> void:
	if not is_active:
		return
	var hovered_control := get_viewport().gui_get_hovered_control()
	if not CutsceneAdvanceInput.consume_advance_event(event, hovered_control):
		return
	_advance()
	get_viewport().set_input_as_handled()
```

- [ ] **Step 5: Run the focused and existing manager tests**

Run: `sh tests/run_story_advance_audio_tests.sh && sh tests/run_audio_manager_tests.sh`

Expected: both runners print `PASS` and exit 0.

- [ ] **Step 6: Commit the shared story input behavior**

```bash
git add scenes/ui/cutscene_advance_input.gd scenes/ui/dialogue_manager.gd tests/test_story_advance_audio.gd tests/run_story_advance_audio_tests.sh
git commit -m "feat: sound accepted story advances"
```

### Task 2: Dedicated cutscene integration

**Files:**
- Modify: `scenes/cutscene/chapter_2_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_deer_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_abduction_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_post_battle_cutscene.gd`
- Modify: `scenes/cutscene/chapter_4_cutscene.gd`
- Modify: `scenes/cutscene/chapter_5_post_boss_cutscene.gd`
- Modify: `scenes/cutscene/chapter_6_cutscene.gd`
- Modify: `scenes/cutscene/chapter_8_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_ending_cutscene.gd`
- Test: `tests/test_story_advance_audio.gd`

**Interfaces:**
- Consumes: `CutsceneAdvanceInput.consume_advance_event(event, hovered_control) -> bool` from Task 1
- Produces: one cue for every accepted dedicated-cutscene advance while retaining every existing `_transitioning`, `_finished`, and `_active` guard

- [ ] **Step 1: Strengthen the helper test for invalid and repeated input**

Before `_finish()` in `tests/test_story_advance_audio.gd`, add literal negative cases:

```gdscript
	_events.clear()
	key_event.echo = true
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(key_event, null),
		"repeated E is rejected"
	)
	_expect(_events.is_empty(), "repeated E stays silent")
	key_event.echo = false

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	_expect(
		not CutsceneAdvanceInput.consume_advance_event(right_click, null),
		"right click is rejected"
	)
	_expect(_events.is_empty(), "right click stays silent")
```

- [ ] **Step 2: Run the story test as a green characterization gate**

Run: `sh tests/run_story_advance_audio_tests.sh`

Expected: PASS, proving the shared helper rejects inputs that dedicated cutscenes must ignore.

- [ ] **Step 3: Replace only the final accepted-event check in every dedicated cutscene**

In each of the eleven files listed above, preserve the initial pure mouse filter and all existing state guards. Replace:

```gdscript
if CutsceneAdvanceInput.is_advance_event(event, hovered_control):
	_advance_dialogue()
```

with:

```gdscript
if CutsceneAdvanceInput.consume_advance_event(event, hovered_control):
	_advance_dialogue()
```

Do not replace the earlier `is_advance_event` mouse prefilter; it must remain side-effect free.

- [ ] **Step 4: Verify all eleven scripts use the consuming path once**

Run:

```bash
rg -n "consume_advance_event" scenes/cutscene --glob '*.gd'
```

Expected: exactly eleven matches, one in each listed cutscene script. This is a review check; runtime behavior remains covered by `test_story_advance_audio.gd` and final Godot parsing.

- [ ] **Step 5: Run story, audio-manager, and parse tests**

Run:

```bash
sh tests/run_story_advance_audio_tests.sh
sh tests/run_audio_manager_tests.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-story-cutscene-parse.log --editor --path . --quit
```

Expected: both test runners print `PASS`; Godot exits 0 with no `SCRIPT ERROR` or parse error.

- [ ] **Step 6: Commit cutscene wiring**

```bash
git add scenes/cutscene/chapter_2_cutscene.gd scenes/cutscene/chapter_2_deer_cutscene.gd scenes/cutscene/chapter_2_abduction_cutscene.gd scenes/cutscene/chapter_3_cutscene.gd scenes/cutscene/chapter_3_post_battle_cutscene.gd scenes/cutscene/chapter_4_cutscene.gd scenes/cutscene/chapter_5_post_boss_cutscene.gd scenes/cutscene/chapter_6_cutscene.gd scenes/cutscene/chapter_8_cutscene.gd scenes/cutscene/chapter_9_cutscene.gd scenes/cutscene/chapter_9_ending_cutscene.gd tests/test_story_advance_audio.gd
git commit -m "feat: sound cutscene progression"
```

### Task 3: Door gain and repeated Miyarap summon cadence

**Files:**
- Modify: `tests/test_audio_manager_runtime.gd`
- Modify: `tests/test_enemy_audio_hooks.gd`
- Modify: `scenes/core/audio_manager.gd`
- Verify: `scenes/props/miyarap.gd`

**Interfaces:**
- Consumes: `AudioManager.play_sfx(sound_key: StringName) -> void`
- Produces: `SOUND_GAINS` with `DOOR: 1.5`; pooled players always receive the current sound's gain

- [ ] **Step 1: Add the failing observable door-gain test**

In `tests/test_audio_manager_runtime.gd`, stop every `AudioStreamPlayer` whose name starts with `SFX`, play the door cue, and find the real player by its stream resource path:

```gdscript
		for child in audio.get_children():
			if child is AudioStreamPlayer and child.name.begins_with("SFX"):
				child.stop()
		audio.play_sfx(&"door")
		var door_player: AudioStreamPlayer = null
		for child in audio.get_children():
			if (
				child is AudioStreamPlayer
				and child.stream != null
				and child.stream.resource_path.ends_with("door.mp3")
			):
				door_player = child
				break
		_expect(door_player != null, "door uses a pooled SFX player")
		if door_player != null:
			_expect(
				is_equal_approx(door_player.volume_db, linear_to_db(1.5)),
				"door cue uses 1.5 gain"
			)
```

Then stop the pool, play pickup, locate its real player, and assert `linear_to_db(1.0)` so reuse cannot leak the door gain.

- [ ] **Step 2: Run the manager test and verify RED**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: FAIL because door currently uses the default 1.0 gain.

- [ ] **Step 3: Add a five-cycle Miyarap regression assertion**

Replace the one-cycle summon assertion in `tests/test_enemy_audio_hooks.gd` with:

```gdscript
	_events.clear()
	for cycle in 5:
		miyarap._start_summon()
	_expect(
		_events == [&"invite", &"invite", &"invite", &"invite", &"invite"],
		"five Miyarap summon starts produce five invite cues"
	)
```

Run: `sh tests/run_enemy_audio_tests.sh`

Expected: PASS as a regression characterization of the existing per-cycle hook. If it fails, remove any one-shot suppression found during diagnosis while preserving cooldown and minion limits.

- [ ] **Step 4: Implement per-sound gain with reset-on-reuse**

In `scenes/core/audio_manager.gd`, add:

```gdscript
const SOUND_GAINS := {
	DOOR: 1.5,
}
```

In `play_sfx`, immediately before `player.play()` add:

```gdscript
player.volume_db = linear_to_db(float(SOUND_GAINS.get(sound_key, 1.0)))
```

Setting the value for every play resets a previously amplified pooled player when it is reused by another sound.

- [ ] **Step 5: Run focused audio tests**

Run: `sh tests/run_audio_manager_tests.sh && sh tests/run_enemy_audio_tests.sh && sh tests/run_portal_audio_tests.sh`

Expected: all three runners print `PASS` and exit 0.

- [ ] **Step 6: Commit gain and repeated-summon coverage**

```bash
git add scenes/core/audio_manager.gd tests/test_audio_manager_runtime.gd tests/test_enemy_audio_hooks.gd
git commit -m "fix: reinforce summon and door audio"
```

### Task 4: Integrated verification

**Files:**
- Verify only; do not stage or modify `scenes/chapter_1/chapter_1.tscn`

**Interfaces:**
- Consumes: Tasks 1–3
- Produces: fresh completion evidence

- [ ] **Step 1: Run every runtime test runner**

Run: `for test_script in tests/run_*_tests.sh; do sh "$test_script" || exit 1; done`

Expected: every runner prints `PASS` and the loop exits 0.

- [ ] **Step 2: Parse/import the complete Godot project**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-story-audio-final-parse.log --editor --path . --quit`

Expected: exit 0 with no GDScript parse errors.

- [ ] **Step 3: Smoke-launch the main scene**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-story-audio-final-smoke.log --path . --quit-after 120`

Expected: exit 0 with no gameplay/script errors.

- [ ] **Step 4: Verify Git boundaries**

Run:

```bash
git diff --check
git status --short --branch
```

Expected: no whitespace errors; only the user's pre-existing `scenes/chapter_1/chapter_1.tscn` modification remains outside commits.
