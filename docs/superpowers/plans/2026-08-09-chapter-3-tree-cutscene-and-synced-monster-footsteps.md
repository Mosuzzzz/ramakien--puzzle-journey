# Chapter 3 Tree Cutscene and Synced Monster Footsteps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve Chapter 3's post-battle tree cutscene after re-entry and play one overlapping ordinary-monster footstep SFX for each visible foot contact.

**Architecture:** Keep the shared Chapter 3 cutscene layer alive by freeing only the already-played intro control, then guard the post-battle call against stale instances. Replace ordinary monsters' shared run loop with per-instance `AnimatedSprite2D.frame_changed` cues at zero-based walk frames 2 and 8; route every cue through the existing SFX pool so different monsters can overlap.

**Tech Stack:** Godot 4.7, GDScript, `AnimatedSprite2D`, autoloaded `AudioManager`, headless Godot SceneTree tests.

## Global Constraints

- Only ordinary monsters using `scenes/props/mob.gd` receive the new step behavior.
- Miyarap and Thosakan movement audio must remain unchanged.
- Use the existing `res://assets/audio/sfx/giant_king.mp3` stream through `AudioManager.MONSTER_RUN`.
- One visible foot contact emits exactly one one-shot sound; different monsters may overlap.
- The real Chapter 3 hierarchy keeps intro and post-battle cutscenes as siblings under `Chapter3CutsceneLayer`.

---

### Task 1: Preserve the Chapter 3 Post-Battle Cutscene

**Files:**
- Modify: `tests/test_chapter_3_reentry_runtime.gd`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd:38-48`
- Modify: `scenes/chapter_3/chapter_3.gd:187-203`

**Interfaces:**
- Consumes: `Chapter3.restore_chapter_3_progress() -> void` and `PostBattleCutscene.show_cutscene() -> void`.
- Produces: re-entry behavior where `Chapter3Cutscene` frees only itself and `Chapter3._start_post_battle_cutscene() -> void` safely invokes a live post-battle cutscene.

- [ ] **Step 1: Make the runtime test reproduce the shared-layer bug**

Change `FakePostBattleCutscene` to record invocations:

```gdscript
class FakePostBattleCutscene extends Control:
	var show_count := 0

	func show_cutscene() -> void:
		show_count += 1
```

Attach the intro cutscene to the existing `Chapter3CutsceneLayer` in `_enter_chapter()` instead of creating `ReentryCutsceneLayer`:

```gdscript
var cutscene_layer := chapter.get_node("Chapter3CutsceneLayer") as CanvasLayer
var cutscene := _build_intro_cutscene()
cutscene.name = "Chapter3Cutscene"
cutscene_layer.add_child(cutscene)
```

Add a check before the existing re-entry cases:

```gdscript
func _check_shared_layer_preserves_post_battle_cutscene() -> void:
	GameState.chapter_3_post_battle_played = false
	_set_feather_count(3)
	var chapter := await _enter_chapter()
	var post := chapter.get_node_or_null("Chapter3CutsceneLayer/PostBattleCutscene") as FakePostBattleCutscene
	_expect(post != null, "re-entry keeps post-battle cutscene in shared layer")
	if post != null:
		chapter.call("_start_post_battle_cutscene")
		await create_timer(0.4).timeout
		_expect(post.show_count == 1, "great-tree event starts post-battle cutscene after re-entry")
	await _remove_chapter(chapter)
```

- [ ] **Step 2: Run the Chapter 3 test and verify RED**

Run: `sh tests/run_chapter_3_reentry_tests.sh`

Expected: FAIL because freeing `Chapter3CutsceneLayer` removes `PostBattleCutscene`, reproducing `previously freed instance` behavior or the explicit missing-node assertion.

- [ ] **Step 3: Free only the intro control**

Replace the parent-layer teardown in `chapter_3_cutscene.gd`:

```gdscript
if GameState.chapter_3_intro_played:
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("restore_chapter_3_progress"):
		chapter.call_deferred("restore_chapter_3_progress")
	queue_free()
	return
```

Guard the call in `chapter_3.gd` after the existing state assignments:

```gdscript
if not is_instance_valid(_post_battle_cutscene):
	push_error("Chapter 3 post-battle cutscene is missing or was freed")
	return
_post_battle_cutscene.call("show_cutscene")
```

- [ ] **Step 4: Run the Chapter 3 test and verify GREEN**

Run: `sh tests/run_chapter_3_reentry_tests.sh`

Expected: `PASS: Chapter 3 re-entry runtime` and exit code 0.

- [ ] **Step 5: Commit the cutscene fix**

```bash
git add tests/test_chapter_3_reentry_runtime.gd scenes/cutscene/chapter_3_cutscene.gd scenes/chapter_3/chapter_3.gd
git commit -m "fix: preserve chapter 3 tree cutscene on re-entry"
```

---

### Task 2: Emit Ordinary-Monster Steps at Foot-Contact Frames

**Files:**
- Modify: `tests/test_enemy_audio_hooks.gd`
- Modify: `tests/test_world_movement_audio.gd`
- Modify: `scenes/props/mob.gd`

**Interfaces:**
- Consumes: `AudioManager.play_sfx(sound_key: StringName) -> void`, `AudioManager.MONSTER_RUN`, and `AnimatedSprite2D.frame_changed`.
- Produces: `Mob._is_footstep_frame(animation: StringName, frame: int) -> bool` and `Mob._on_sprite_frame_changed() -> void`.

- [ ] **Step 1: Add failing contact-frame and overlap tests**

After constructing the ordinary mob in `test_enemy_audio_hooks.gd`, assert the selected contacts:

```gdscript
_expect(mob.has_method("_is_footstep_frame"), "ordinary monster footstep frames defined")
if mob.has_method("_is_footstep_frame"):
	_expect(mob._is_footstep_frame(&"walk", 2), "ordinary monster first foot contact")
	_expect(mob._is_footstep_frame(&"walk", 8), "ordinary monster second foot contact")
	_expect(not mob._is_footstep_frame(&"walk", 5), "ordinary monster non-contact frame is silent")
	_expect(not mob._is_footstep_frame(&"idle", 2), "ordinary monster idle frame is silent")
```

Create two ordinary mobs, set each sprite to `walk`, give each non-zero velocity, and call the frame handler once at contact frame 2:

```gdscript
var mob_b := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
stage.add_child(mob_b)
_events.clear()
for actor in [mob, mob_b]:
	actor.velocity = Vector2.RIGHT * actor.speed
	var sprite := actor.get_node("Sprite") as AnimatedSprite2D
	sprite.animation = &"walk"
	sprite.frame = 2
	actor.call("_on_sprite_frame_changed")
_expect(_events == [&"monster_run", &"monster_run"], "two monsters emit overlapping contact cues")
```

Then call the same handler again without changing frame and assert no duplicates. Set frame 5, call once, return to frame 2, and assert one new event. Set velocity to zero and assert contact is silent.

Update `test_world_movement_audio.gd` so an ordinary mob no longer starts `MonsterRunLoop` when `_update_run_audio(true)` is called:

```gdscript
mob._update_run_audio(true)
_expect(not monster_loop.playing, "ordinary monster no longer starts continuous loop")
```

- [ ] **Step 2: Run focused audio tests and verify RED**

Run:

```bash
sh tests/run_enemy_audio_tests.sh
sh tests/run_world_movement_audio_tests.sh
```

Expected: enemy audio test FAILS because `_is_footstep_frame` and `_on_sprite_frame_changed` do not exist; world movement test FAILS because the ordinary monster still starts `MonsterRunLoop`.

- [ ] **Step 3: Implement per-frame one-shot footsteps**

Add state and contact-frame constants to `mob.gd`:

```gdscript
const WALK_FOOTSTEP_FRAMES := {2: true, 8: true}

var _last_footstep_frame := -1
```

Connect the sprite frame signal in `_ready()`:

```gdscript
if not _sprite.frame_changed.is_connected(_on_sprite_frame_changed):
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
```

Keep `_update_run_audio(active)` as a compatibility cleanup hook, but ensure it never starts the continuous monster loop:

```gdscript
func _uses_shared_run_audio() -> bool:
	return false


func _update_run_audio(_active: bool) -> void:
	AudioManager.set_monster_run_active(self, false)
```

Add the frame policy and handler:

```gdscript
func _is_footstep_frame(animation: StringName, frame: int) -> bool:
	return animation == _animation_for(&"walk") and WALK_FOOTSTEP_FRAMES.has(frame)


func _on_sprite_frame_changed() -> void:
	var animation := _sprite.animation
	var frame := _sprite.frame
	if (
		_defeated
		or _attacking
		or not can_move
		or velocity.is_zero_approx()
		or not _is_footstep_frame(animation, frame)
	):
		_last_footstep_frame = -1
		return
	if frame == _last_footstep_frame:
		return
	_last_footstep_frame = frame
	AudioManager.play_sfx(AudioManager.MONSTER_RUN)
```

This emits on zero-based frames 2 and 8 (visible poses 3 and 9 in the 12-frame sheet) and uses separate pooled players for simultaneous monsters.

- [ ] **Step 4: Run focused audio tests and verify GREEN**

Run:

```bash
sh tests/run_enemy_audio_tests.sh
sh tests/run_world_movement_audio_tests.sh
sh tests/run_audio_manager_tests.sh
```

Expected: all three scripts exit 0; ordinary monster steps are one-shot while Miyarap and Thosakan assertions remain unchanged.

- [ ] **Step 5: Commit synchronized monster footsteps**

```bash
git add tests/test_enemy_audio_hooks.gd tests/test_world_movement_audio.gd scenes/props/mob.gd
git commit -m "fix: sync ordinary monster audio to foot contacts"
```

---

### Task 3: Full Regression Verification

**Files:**
- Verify only; no production changes expected.

**Interfaces:**
- Consumes: all repository `tests/run_*_tests.sh` runners.
- Produces: fresh evidence that the Chapter 3 and audio changes do not regress other chapters or combat systems.

- [ ] **Step 1: Run formatting and parse checks**

Run:

```bash
git diff --check
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
```

Expected: both commands exit 0 with no GDScript parse error.

- [ ] **Step 2: Run every project test runner**

Run each tracked shell runner and stop on the first failure:

```bash
for runner in tests/run_*_tests.sh; do sh "$runner" || exit 1; done
```

Expected: every runner exits 0. Existing non-fatal imported-resource warnings may remain, but there must be no new script error or failed assertion.

- [ ] **Step 3: Inspect the final diff and repository state**

Run:

```bash
git status --short
git diff HEAD~2 -- scenes/chapter_3/chapter_3.gd scenes/cutscene/chapter_3_cutscene.gd scenes/props/mob.gd tests/test_chapter_3_reentry_runtime.gd tests/test_enemy_audio_hooks.gd tests/test_world_movement_audio.gd
```

Expected: only the approved cutscene, footstep, and regression-test changes are present; no unrelated user files are modified.
