# Ordinary Monster Footsteps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every ordinary `mob.gd` monster use the supplied `Giant King.mp3` walking loop while preserving all allied, Miyarap, Thosakan, attack, impact, and boss sounds.

**Architecture:** Extend the global `AudioManager` with a second weak-owner locomotion registry and dedicated `MonsterRunLoop` player. Route only the base ordinary-monster movement lifecycle through this API; Thosakan's existing `_uses_shared_run_audio() == false` override keeps it out, and Miyarap remains untouched because it does not inherit `mob.gd`.

**Tech Stack:** Godot 4.7, GDScript, MP3 resources, SceneTree headless runtime tests.

## Global Constraints

- `Giant King.mp3` applies only to ordinary monsters based on `mob.gd`.
- Do not change Rama, Hanuman, Phalak, Sida, Miyarap, or Thosakan sounds.
- Do not replace `AudioManager.GIANT` or any attack, impact, summon, wave, jump, heal, or pull key.
- Multiple moving monsters share one loop; the loop stops only after the final active owner stops or becomes invalid.
- Modal/cutscene locomotion shutdown must stop both allied and monster loops.

---

## File map

- `assets/audio/sfx/giant_king.mp3`: stable project copy of the user-supplied ordinary-monster walking sound.
- `scenes/core/audio_manager.gd`: owns `MONSTER_RUN`, `MonsterRunLoop`, and the weak multi-owner monster movement lifecycle.
- `scenes/props/mob.gd`: registers ordinary monster walking with the new API and unregisters on attack, defeat, stop, and exit.
- `tests/test_audio_manager_runtime.gd`: verifies resource loading, loop creation, multi-owner behavior, invalid-owner pruning, and global stopping.
- `tests/test_world_movement_audio.gd`: verifies ordinary monsters use only `MonsterRunLoop`, allies use only `RunLoop`, and Thosakan remains excluded.

### Task 1: Specify the separate monster movement channel

**Files:**
- Modify: `tests/test_audio_manager_runtime.gd:11-90`
- Modify: `tests/test_world_movement_audio.gd:8-48`

**Interfaces:**
- Consumes: existing `AudioManager.set_run_active(owner: Node, active: bool) -> void`.
- Produces: failing contracts for `MONSTER_RUN`, `set_monster_run_active(owner: Node, active: bool) -> void`, and `MonsterRunLoop`.

- [ ] **Step 1: Extend the AudioManager test with the monster loop contract**

Add `&"monster_run"` to the required key list, assert `set_monster_run_active` and `MonsterRunLoop` exist, then exercise two independent owners:

```gdscript
_expect(audio.has_method("set_monster_run_active"), "monster run-loop API exists")
_expect(audio.get_node_or_null("MonsterRunLoop") != null, "MonsterRunLoop player exists")

var monster_a := Node.new()
var monster_b := Node.new()
root.add_child(monster_a)
root.add_child(monster_b)
audio.set_monster_run_active(monster_a, true)
_expect(audio.get_node("MonsterRunLoop").playing, "monster run loop starts")
_expect(not audio.get_node("RunLoop").playing, "monster movement does not start allied loop")
audio.set_monster_run_active(monster_b, true)
audio.set_monster_run_active(monster_a, false)
_expect(audio.get_node("MonsterRunLoop").playing, "one monster owner keeps loop active")
audio.set_monster_run_active(monster_b, false)
_expect(not audio.get_node("MonsterRunLoop").playing, "final monster owner stops loop")
audio.set_monster_run_active(monster_a, true)
monster_a.free()
await process_frame
_expect(not audio.get_node("MonsterRunLoop").playing, "invalid monster owner is pruned")
monster_b.free()
```

Also activate one allied owner and one monster owner together, call `stop_run_loop()`, and assert both players stop.

- [ ] **Step 2: Update the world-movement actor expectations**

Change `test_world_movement_audio.gd` so only `sida.tscn`, `hanuman.tscn`, and `phalak.tscn` are tested against `RunLoop`. Test `mob.tscn` separately:

```gdscript
var monster_loop := audio.get_node("MonsterRunLoop") as AudioStreamPlayer
var mob := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
stage.add_child(mob)
mob._update_run_audio(true)
_expect(monster_loop.playing, "ordinary monster starts monster loop")
_expect(not run_loop.playing, "ordinary monster does not start Rama loop")
mob._update_run_audio(false)
_expect(not monster_loop.playing, "ordinary monster stops monster loop")
mob._update_run_audio(true)
mob.free()
await process_frame
_expect(not monster_loop.playing, "ordinary monster releases monster loop on exit")
```

Keep the existing Thosakan assertions, and additionally assert neither loop starts when `_update_run_audio(true)` is invoked on Thosakan.

- [ ] **Step 3: Run both tests and confirm failure**

```bash
sh tests/run_audio_manager_tests.sh
sh tests/run_world_movement_audio_tests.sh
```

Expected: FAIL because `monster_run`, `MonsterRunLoop`, and `set_monster_run_active()` do not exist and `mob.gd` still starts `RunLoop`.

- [ ] **Step 4: Commit the failing tests**

```bash
git add tests/test_audio_manager_runtime.gd tests/test_world_movement_audio.gd
git commit -m "test: specify ordinary monster footsteps"
```

### Task 2: Add the dedicated monster walking asset and AudioManager loop

**Files:**
- Create: `assets/audio/sfx/giant_king.mp3`
- Modify: `scenes/core/audio_manager.gd:5-60,79-143,268-297`
- Test: `tests/test_audio_manager_runtime.gd`

**Interfaces:**
- Consumes: `/Users/siwakornbundi/Downloads/Giant King.mp3`.
- Produces: `AudioManager.MONSTER_RUN`, `set_monster_run_active(owner: Node, active: bool) -> void`, and a child `AudioStreamPlayer` named `MonsterRunLoop` on the `SFX` bus.

- [ ] **Step 1: Copy the supplied asset into the project**

Run:

```bash
cp "/Users/siwakornbundi/Downloads/Giant King.mp3" assets/audio/sfx/giant_king.mp3
```

Confirm: `test -s assets/audio/sfx/giant_king.mp3` exits 0.

- [ ] **Step 2: Register the new loop without changing existing keys**

Add:

```gdscript
const MONSTER_RUN := &"monster_run"
```

and map it in `SOUND_PATHS`:

```gdscript
MONSTER_RUN: "res://assets/audio/sfx/giant_king.mp3",
```

Change MP3 loop assignment to:

```gdscript
stream.loop = key in [RUN, MONSTER_RUN]
```

Do not modify `GIANT`, `GIANT_ATTACK`, or their paths.

- [ ] **Step 3: Add a separate weak-owner lifecycle**

Add `_monster_run_owners: Dictionary[int, WeakRef] = {}` and the public method:

```gdscript
func set_monster_run_active(owner: Node, active: bool) -> void:
	if owner == null:
		return
	var owner_id := owner.get_instance_id()
	if active:
		_monster_run_owners[owner_id] = weakref(owner)
	else:
		_monster_run_owners.erase(owner_id)
	_refresh_monster_run_loop()
```

Add pruning and refresh methods parallel to the existing allied registry:

```gdscript
func _prune_monster_run_owners() -> void:
	for owner_id: int in _monster_run_owners.keys():
		var owner_ref := _monster_run_owners[owner_id] as WeakRef
		if owner_ref.get_ref() == null:
			_monster_run_owners.erase(owner_id)
	_refresh_monster_run_loop()

func _refresh_monster_run_loop() -> void:
	var player := get_node("MonsterRunLoop") as AudioStreamPlayer
	if _monster_run_owners.is_empty():
		player.stop()
	elif not player.playing and _streams.has(MONSTER_RUN):
		player.stream = _streams[MONSTER_RUN]
		player.play()
```

Call `_prune_monster_run_owners()` from `_process()`. Extend `stop_run_loop()` to clear `_monster_run_owners` and stop `MonsterRunLoop` as well as the existing allied state.

- [ ] **Step 4: Create the dedicated runtime player**

In `_create_players()` add:

```gdscript
var monster_run_loop := AudioStreamPlayer.new()
monster_run_loop.name = "MonsterRunLoop"
monster_run_loop.bus = &"SFX"
add_child(monster_run_loop)
```

- [ ] **Step 5: Run the AudioManager test**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: PASS, including the new resource, player, independent owners, pruning, and combined stop assertions.

- [ ] **Step 6: Commit the AudioManager change and asset**

```bash
git add assets/audio/sfx/giant_king.mp3 scenes/core/audio_manager.gd
git commit -m "feat: add ordinary monster footstep loop"
```

### Task 3: Route only ordinary monsters to the new loop

**Files:**
- Modify: `scenes/props/mob.gd:141-150`
- Test: `tests/test_world_movement_audio.gd`

**Interfaces:**
- Consumes: `AudioManager.set_monster_run_active(owner: Node, active: bool) -> void`.
- Produces: ordinary-monster movement registration with no allied-loop ownership.

- [ ] **Step 1: Replace the base mob movement registration**

Change only the shared base methods in `mob.gd`:

```gdscript
func _update_run_audio(active: bool) -> void:
	AudioManager.set_monster_run_active(self, active and _uses_shared_run_audio())

func _exit_tree() -> void:
	AudioManager.set_monster_run_active(self, false)
```

Keep `_uses_shared_run_audio()` unchanged. Its existing `false` override in `thosakan.gd` therefore prevents Thosakan from using the new monster loop. Do not edit `miyarap.gd` or `thosakan.gd`.

- [ ] **Step 2: Run focused movement and enemy regressions**

```bash
sh tests/run_world_movement_audio_tests.sh
sh tests/run_enemy_audio_tests.sh
sh tests/run_player_audio_tests.sh
```

Expected: all three commands exit 0. The ordinary mob uses only `MonsterRunLoop`; allied characters still use `RunLoop`; boss attack and movement contracts remain unchanged.

- [ ] **Step 3: Commit ordinary-monster routing**

```bash
git add scenes/props/mob.gd
git commit -m "fix: separate ordinary monster walking audio"
```

### Task 4: Verify audio isolation end to end

**Files:**
- Verify: `assets/audio/sfx/giant_king.mp3`
- Verify: `scenes/core/audio_manager.gd`
- Verify: `scenes/props/mob.gd`
- Test: all audio runner scripts below.

**Interfaces:**
- Consumes: completed AudioManager and mob routing tasks.
- Produces: evidence that the new sound is isolated to ordinary monsters.

- [ ] **Step 1: Run the complete audio regression set**

```bash
sh tests/run_audio_manager_tests.sh
sh tests/run_world_movement_audio_tests.sh
sh tests/run_enemy_audio_tests.sh
sh tests/run_player_audio_tests.sh
sh tests/run_pickup_audio_tests.sh
sh tests/run_puzzle_audio_tests.sh
sh tests/run_portal_audio_tests.sh
sh tests/run_story_advance_audio_tests.sh
```

Expected: all eight commands exit 0.

- [ ] **Step 2: Confirm boss files were untouched**

Run:

```bash
git diff --name-only HEAD~3..HEAD
```

Expected: neither `scenes/props/miyarap.gd` nor `scenes/props/thosakan.gd` appears.

- [ ] **Step 3: Manually listen in gameplay**

Walk Rama near a moving ordinary monster and confirm Rama uses `run.mp3` while the monster uses `giant_king.mp3`. Enter Miyarap and Thosakan encounters and confirm their existing sounds are unchanged.

- [ ] **Step 4: Inspect the final diff**

Run: `git diff --check HEAD~3..HEAD`

Expected: no whitespace errors or unrelated scene changes.

