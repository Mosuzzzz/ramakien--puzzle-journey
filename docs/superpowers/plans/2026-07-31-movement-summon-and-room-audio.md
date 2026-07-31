# Movement, Summon, and Room Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add non-layering shared walk audio to world actors, an invite cue to Miyarap's summon, door audio to successful room transitions, and reduce gameplay music to 30%.

**Architecture:** Extend the existing `AudioManager` rather than adding scene-local audio players. Replace the single run owner with a weak multi-owner registry, register the two supplied SFX centrally, keep room classification in the shared portal, and leave saved Music/SFX bus values untouched.

**Tech Stack:** Godot 4.7, GDScript, MP3 resources, headless SceneTree runtime tests, Git.

## Global Constraints

- Keep one shared `run.mp3` loop even when several actors move simultaneously.
- Include Rama, playable Hanuman, generic mobs, Chapter 6 Yak Captain, Miyarap minions, Sida, Chapter 3 Hanuman NPC, and future Phalak `walk` animation calls.
- Keep Thosakan on frame-based `giant.mp3` footsteps and exclude the golden deer.
- Play `invite.mp3` once when Miyarap begins summoning.
- Play `door.mp3` once on both entry and exit for the specified room scenes; locked and outdoor portals stay silent.
- Homepage music remains 100%; prologue and Chapter 1–9 music uses 30% gain.
- Preserve the user's uncommitted `scenes/chapter_1/chapter_1.tscn` change.

---

### Task 1: Audio resources, 30% gameplay mix, and multi-owner run loop

**Files:**
- Create: `assets/audio/sfx/invite.mp3`
- Create: `assets/audio/sfx/door.mp3`
- Modify: `tests/test_audio_manager_runtime.gd`
- Modify: `scenes/core/audio_manager.gd`

**Interfaces:**
- Consumes: `AudioManager.set_run_active(owner: Node, active: bool) -> void`
- Produces: `INVITE`, `DOOR`, `GAMEPLAY_MUSIC_GAIN = 0.3`, and a weak owner registry used by all walking actors

- [ ] **Step 1: Extend the runtime test before adding assets or implementation**

Add `invite` and `door` to the required sound-key list, change all gameplay-gain expectations from `linear_to_db(0.4)` to `linear_to_db(0.3)`, and replace the one-owner run assertion with:

```gdscript
var owner_a := Node.new()
var owner_b := Node.new()
root.add_child(owner_a)
root.add_child(owner_b)
audio.set_run_active(owner_a, true)
audio.set_run_active(owner_b, true)
audio.set_run_active(owner_a, false)
_expect(audio.get_node("RunLoop").playing, "one stopped owner does not silence another")
audio.set_run_active(owner_b, false)
_expect(not audio.get_node("RunLoop").playing, "run loop stops after final owner")
audio.set_run_active(owner_a, true)
owner_a.free()
await process_frame
_expect(not audio.get_node("RunLoop").playing, "invalid owner is pruned")
owner_b.free()
```

- [ ] **Step 2: Run the audio-manager test and verify RED**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: FAIL because the new resources do not exist, gameplay gain is 40%, and stopping one owner silences/invalidates the single-owner loop behavior.

- [ ] **Step 3: Copy the approved assets into stable project paths**

```bash
cp /Users/siwakornbundi/Downloads/invite.mp3 assets/audio/sfx/invite.mp3
cp /Users/siwakornbundi/Downloads/door.mp3 assets/audio/sfx/door.mp3
```

- [ ] **Step 4: Implement the resource keys, 30% gain, and owner registry**

Add `INVITE`, `DOOR`, their paths, and set `GAMEPLAY_MUSIC_GAIN := 0.3`. Replace `_run_owner` with a dictionary of `WeakRef` values keyed by instance ID:

```gdscript
var _run_owners: Dictionary[int, WeakRef] = {}

func set_run_active(owner: Node, active: bool) -> void:
    if owner == null:
        return
    var owner_id := owner.get_instance_id()
    if active:
        _run_owners[owner_id] = weakref(owner)
    else:
        _run_owners.erase(owner_id)
    _refresh_run_loop()

func stop_run_loop() -> void:
    _run_owners.clear()
    (get_node("RunLoop") as AudioStreamPlayer).stop()

func _prune_run_owners() -> void:
    for owner_id: int in _run_owners.keys():
        var owner_ref := _run_owners[owner_id] as WeakRef
        if owner_ref.get_ref() == null:
            _run_owners.erase(owner_id)
    _refresh_run_loop()

func _refresh_run_loop() -> void:
    var player := get_node("RunLoop") as AudioStreamPlayer
    if _run_owners.is_empty():
        player.stop()
    elif not player.playing and _streams.has(RUN):
        player.stream = _streams[RUN]
        player.play()
```

Call `_prune_run_owners()` from `_process`.

- [ ] **Step 5: Import and run focused audio tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-new-audio-import.log --editor --path . --quit && sh tests/run_audio_manager_tests.sh && sh tests/run_audio_settings_tests.sh`

Expected: both test scripts print `PASS` and exit 0.

- [ ] **Step 6: Commit the audio core**

```bash
git add assets/audio/sfx/invite.mp3 assets/audio/sfx/invite.mp3.import assets/audio/sfx/door.mp3 assets/audio/sfx/door.mp3.import scenes/core/audio_manager.gd tests/test_audio_manager_runtime.gd
git commit -m "feat: add shared movement and transition sounds"
```

### Task 2: World actor movement lifecycle

**Files:**
- Create: `tests/test_world_movement_audio.gd`
- Create: `tests/run_world_movement_audio_tests.sh`
- Modify: `scenes/props/mob.gd`
- Modify: `scenes/props/thosakan.gd`
- Modify: `scenes/props/sida.gd`
- Modify: `scenes/props/hanuman.gd`
- Modify: `scenes/props/phalak.gd`

**Interfaces:**
- Consumes: multi-owner `AudioManager.set_run_active(owner, active)` from Task 1
- Produces: `_update_run_audio(active: bool)` actor hooks and `_uses_shared_run_audio() -> bool` mob policy

- [ ] **Step 1: Write a failing real-scene lifecycle test**

Instantiate `mob.tscn`, `thosakan.tscn`, `sida.tscn`, `hanuman.tscn`, and `phalak.tscn` under a stage with a `Player`. For each requested actor, assert `_update_run_audio(true)` starts `RunLoop`, `_update_run_audio(false)` stops it, and `_exit_tree()` cleanup removes ownership. Assert Thosakan's `_uses_shared_run_audio()` is false.

```gdscript
_expect(mob.has_method("_update_run_audio"), "generic mob exposes run lifecycle")
mob._update_run_audio(true)
_expect(run_loop.playing, "generic mob starts shared run loop")
mob._update_run_audio(false)
_expect(not run_loop.playing, "generic mob stops shared run loop")
_expect(not thosakan._uses_shared_run_audio(), "Thosakan keeps giant footsteps")
```

The runner uses the same Godot command shape as the existing audio test scripts and prints `PASS: world movement audio` on success.

- [ ] **Step 2: Run the new test and verify RED**

Run: `sh tests/run_world_movement_audio_tests.sh`

Expected: FAIL because world actors do not yet expose the shared run lifecycle.

- [ ] **Step 3: Implement generic mob hooks and Thosakan exclusion**

In `mob.gd`, update movement state every physics frame, stop before attacks/death, and clean up on exit:

```gdscript
func _uses_shared_run_audio() -> bool:
    return true

func _update_run_audio(active: bool) -> void:
    AudioManager.set_run_active(self, active and _uses_shared_run_audio())

func _exit_tree() -> void:
    AudioManager.set_run_active(self, false)
```

In `thosakan.gd`:

```gdscript
func _uses_shared_run_audio() -> bool:
    return false
```

- [ ] **Step 4: Implement companion/NPC hooks**

Add `_update_run_audio(active)` and `_exit_tree()` to Sida, Hanuman NPC, and Phalak. Sida and Hanuman call it from their real movement/idle branches. Phalak calls it from `_play(anim)` with `anim == "walk"`.

- [ ] **Step 5: Run movement, player, and enemy audio tests**

Run: `sh tests/run_world_movement_audio_tests.sh && sh tests/run_player_audio_tests.sh && sh tests/run_enemy_audio_tests.sh`

Expected: all print `PASS` and exit 0.

- [ ] **Step 6: Commit actor integration**

```bash
git add tests/test_world_movement_audio.gd tests/run_world_movement_audio_tests.sh scenes/props/mob.gd scenes/props/thosakan.gd scenes/props/sida.gd scenes/props/hanuman.gd scenes/props/phalak.gd
git commit -m "feat: sound world actor movement"
```

### Task 3: Miyarap summon and room portal cues

**Files:**
- Modify: `tests/test_enemy_audio_hooks.gd`
- Create: `tests/test_portal_audio.gd`
- Create: `tests/run_portal_audio_tests.sh`
- Modify: `scenes/props/miyarap.gd`
- Modify: `scenes/props/portal.gd`

**Interfaces:**
- Consumes: `AudioManager.INVITE`, `AudioManager.DOOR`
- Produces: one summon-start cue and `Portal.play_transition_sound_for_scene_path(current_scene_path: String) -> void`

- [ ] **Step 1: Add failing Miyarap summon assertion**

Before freeing Miyarap in `test_enemy_audio_hooks.gd`:

```gdscript
_events.clear()
miyarap._start_summon()
_expect(_events == [&"invite"], "Miyarap summon starts with one invite cue")
```

- [ ] **Step 2: Add failing portal classification/feedback test**

Instantiate `portal.tscn`, collect `AudioManager.sfx_played`, set `target_scene`, and call `play_transition_sound_for_scene_path` for:

```gdscript
portal.target_scene = "res://scenes/chapter_1/throne_room.tscn"
portal.play_transition_sound_for_scene_path("res://scenes/chapter_1/chapter_1.tscn")
_expect(_events == [&"door"], "entering throne room sounds door")

portal.target_scene = "res://scenes/chapter_6/chapter_6.tscn"
portal.play_transition_sound_for_scene_path("res://scenes/chapter_6/chapter_6_room_left.tscn")
_expect(_events == [&"door"], "leaving Chapter 6 room sounds door")

portal.target_scene = "res://scenes/chapter_8/chapter_8_room_4.tscn"
portal.play_transition_sound_for_scene_path("res://scenes/chapter_8/chapter_8.tscn")
_expect(_events == [&"door"], "entering Chapter 8 room sounds door")

portal.locked = true
portal.play_transition_sound_for_scene_path("res://scenes/chapter_8/chapter_8.tscn")
_expect(_events.is_empty(), "locked room portal stays silent")

portal.locked = false
portal.target_scene = "res://scenes/chapter_7/chapter_7.tscn"
portal.play_transition_sound_for_scene_path("res://scenes/chapter_6/chapter_6.tscn")
_expect(_events.is_empty(), "outdoor chapter portal stays silent")
```

- [ ] **Step 3: Run both focused tests and verify RED**

Run: `sh tests/run_enemy_audio_tests.sh && sh tests/run_portal_audio_tests.sh`

Expected: FAIL because Miyarap and Portal do not emit the new cues.

- [ ] **Step 4: Add the summon-start cue**

At the beginning of `_start_summon()` after state is accepted:

```gdscript
AudioManager.play_sfx(AudioManager.INVITE)
```

- [ ] **Step 5: Add centralized room-transition classification**

In `portal.gd`, add exact room detection and call it after the locked guard and before changing scenes:

```gdscript
func play_transition_sound_for_scene_path(current_scene_path: String) -> void:
    if locked:
        return
    if _is_room_scene_path(current_scene_path) or _is_room_scene_path(target_scene):
        AudioManager.play_sfx(AudioManager.DOOR)

func _is_room_scene_path(scene_path: String) -> bool:
    return (
        scene_path == "res://scenes/chapter_1/throne_room.tscn"
        or scene_path.contains("/chapter_6/chapter_6_room_")
        or scene_path.contains("/chapter_8/chapter_8_room")
    )
```

`_use_portal()` derives the current scene path and invokes the helper only after confirming the portal is unlocked.

- [ ] **Step 6: Run enemy and portal audio tests**

Run: `sh tests/run_enemy_audio_tests.sh && sh tests/run_portal_audio_tests.sh`

Expected: both print `PASS` and exit 0.

- [ ] **Step 7: Commit interaction cues**

```bash
git add tests/test_enemy_audio_hooks.gd tests/test_portal_audio.gd tests/run_portal_audio_tests.sh scenes/props/miyarap.gd scenes/props/portal.gd
git commit -m "feat: sound summons and room transitions"
```

### Task 4: Integrated verification

**Files:**
- Verify only; never stage or modify `scenes/chapter_1/chapter_1.tscn`

**Interfaces:**
- Consumes: all audio behavior from Tasks 1–3
- Produces: fresh completion evidence

- [ ] **Step 1: Run all audio test scripts**

Run: `for test_script in tests/run_*_tests.sh; do sh "$test_script"; done`

Expected: every runner prints `PASS` and exits 0.

- [ ] **Step 2: Parse/import the project**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-movement-room-parse.log --editor --path . --quit`

Expected: exit 0 with no GDScript parse errors.

- [ ] **Step 3: Smoke-test the main scene**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-movement-room-smoke.log --path . --quit-after 120`

Expected: exit 0 with no gameplay/script errors.

- [ ] **Step 4: Verify repository scope**

Run: `git diff --check && git status --short --branch`

Expected: no whitespace failures; only the user's pre-existing `scenes/chapter_1/chapter_1.tscn` modification remains outside implementation commits.
