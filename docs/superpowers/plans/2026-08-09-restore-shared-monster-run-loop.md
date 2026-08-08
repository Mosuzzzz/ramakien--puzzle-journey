# Restore Shared Ordinary-Monster Run Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore ordinary monsters to one shared looping movement sound that stops when the final moving monster stops, dies, or leaves the scene.

**Architecture:** `mob.gd` reports whether each ordinary monster is actively walking to the existing owner registry in `AudioManager`. `AudioManager` alone owns and starts/stops `MonsterRunLoop`; ordinary monsters no longer emit frame-synchronized one-shot movement cues into the SFX pool.

**Tech Stack:** Godot 4.7.1, GDScript, headless SceneTree regression tests, Git

## Global Constraints

- Change only ordinary monsters implemented by `scenes/props/mob.gd`.
- Do not change Miyarap or Thosakan movement audio.
- Do not change player, Hanuman, Phalak, or Sida movement audio.
- Keep one shared `MonsterRunLoop` while one or more ordinary monsters are walking.
- Stop the shared loop when the final owner stops, dies, or exits the scene tree.

---

### Task 1: Specify the Restored Shared-Loop Contract

**Files:**
- Modify: `tests/test_enemy_audio_hooks.gd:30-79`
- Modify: `tests/test_world_movement_audio.gd:38-51`
- Modify: `tests/test_audio_manager_runtime.gd:76-95`

**Interfaces:**
- Consumes: `mob._uses_shared_run_audio() -> bool`, `mob._update_run_audio(active: bool) -> void`, `AudioManager.set_monster_run_active(owner: Node, active: bool) -> void`
- Produces: regression coverage for ordinary-monster shared-loop policy, last-owner shutdown, exit-tree shutdown, and looping `monster_run` stream configuration

- [ ] **Step 1: Replace the per-frame ordinary-monster assertions with shared-loop assertions**

In `tests/test_enemy_audio_hooks.gd`, remove the assertions for `_is_footstep_frame()` and `_on_sprite_frame_changed()`. Add:

```gdscript
_expect(mob.has_method("_uses_shared_run_audio"), "ordinary monster exposes run-audio policy")
if mob.has_method("_uses_shared_run_audio"):
	_expect(mob._uses_shared_run_audio(), "ordinary monster uses shared run loop")
_expect(
	not mob.has_method("_on_sprite_frame_changed"),
	"ordinary monster no longer emits pooled frame-contact cues"
)
```

In `tests/test_world_movement_audio.gd`, change the ordinary-monster expectations to:

```gdscript
mob._update_run_audio(true)
_expect(monster_loop.playing, "ordinary monster starts shared run loop")
_expect(not run_loop.playing, "ordinary monster does not start Rama run loop")
mob._update_run_audio(false)
_expect(not monster_loop.playing, "ordinary monster stops shared run loop")
mob._update_run_audio(true)
mob.free()
await process_frame
_expect(not monster_loop.playing, "defeated or removed final monster releases shared run loop")
```

In `tests/test_audio_manager_runtime.gd`, replace the pooled one-shot assertion with:

```gdscript
var monster_stream := audio._streams.get(&"monster_run") as AudioStreamMP3
_expect(monster_stream != null, "monster run stream is loaded")
if monster_stream != null:
	_expect(monster_stream.loop, "shared ordinary monster movement stream loops")
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```bash
sh tests/run_audio_manager_tests.sh
sh tests/run_enemy_audio_tests.sh
sh tests/run_world_movement_audio_tests.sh
```

Expected: at least one assertion fails because `mob.gd` still disables shared run audio and `MONSTER_RUN` is still configured as non-looping.

---

### Task 2: Restore Ordinary-Monster Shared Movement Audio

**Files:**
- Modify: `scenes/props/mob.gd:29-176`
- Modify: `scenes/core/audio_manager.gd:302-314`
- Test: `tests/test_audio_manager_runtime.gd`
- Test: `tests/test_enemy_audio_hooks.gd`
- Test: `tests/test_world_movement_audio.gd`

**Interfaces:**
- Consumes: `AudioManager.set_monster_run_active(owner: Node, active: bool) -> void`
- Produces: `mob._uses_shared_run_audio() -> bool` returning `true`; `_update_run_audio(active: bool)` registering/unregistering the monster; looping `MONSTER_RUN` stream used by `MonsterRunLoop`

- [ ] **Step 1: Remove per-frame movement cue state and callbacks from `mob.gd`**

Delete:

```gdscript
const WALK_FOOTSTEP_FRAMES := {2: true, 8: true}
var _last_footstep_frame := -1
```

Remove the `frame_changed` connection from `_ready()`, and delete `_is_footstep_frame()` plus `_on_sprite_frame_changed()` in full. This prevents ordinary monsters from calling `AudioManager.play_sfx(AudioManager.MONSTER_RUN)` through pooled SFX players.

- [ ] **Step 2: Restore the shared-loop policy in `mob.gd`**

Replace the policy functions with:

```gdscript
func _uses_shared_run_audio() -> bool:
	return true


func _update_run_audio(active: bool) -> void:
	AudioManager.set_monster_run_active(self, active and _uses_shared_run_audio())
```

Keep the existing `_update_run_audio(false)` calls when attacking, defeated, unable to move, or exiting the tree. These are the lifecycle paths that stop the sound.

- [ ] **Step 3: Restore looping on the dedicated monster stream**

In `AudioManager._load_streams()`, change:

```gdscript
stream.loop = key == RUN
```

to:

```gdscript
stream.loop = key in [RUN, MONSTER_RUN]
```

The ordinary-monster code no longer sends `MONSTER_RUN` to `play_sfx()`, so this loop flag is confined to the dedicated `MonsterRunLoop` player.

- [ ] **Step 4: Run the focused tests and verify GREEN**

Run:

```bash
sh tests/run_audio_manager_tests.sh
sh tests/run_enemy_audio_tests.sh
sh tests/run_world_movement_audio_tests.sh
```

Expected: all three runners print `PASS` and exit 0.

- [ ] **Step 5: Run formatting and full regression verification**

Run:

```bash
git diff --check
set -eu
count=0
for runner in tests/run_*_tests.sh; do
	sh "$runner"
	count=$((count + 1))
done
printf 'FINAL_ALL_RUNNERS_PASSED=%s\n' "$count"
```

Expected: `git diff --check` exits 0 and all test runners pass.

- [ ] **Step 6: Commit the implementation**

```bash
git add scenes/props/mob.gd scenes/core/audio_manager.gd \
	tests/test_audio_manager_runtime.gd tests/test_enemy_audio_hooks.gd \
	tests/test_world_movement_audio.gd
git commit -m "fix: restore shared ordinary monster run loop"
```
