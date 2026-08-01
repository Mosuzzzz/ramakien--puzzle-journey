# Menu, Gameplay, and Thosakan Jump Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play background music normally on menu screens, attenuate it to 40% after gameplay starts, and play Thosakan's jump sound exactly when jump damage lands.

**Architecture:** Keep `AudioManager` as the sole music/SFX owner. Extend its scene-path synchronization to classify menu and gameplay paths and apply a per-player gain without modifying the saved Music or SFX bus values; move the existing Thosakan cue inside the guarded jump-impact damage boundary.

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree regression tests, Git.

## Global Constraints

- Menu paths under `res://scenes/homepage/` play background music at 100% of the user's Music setting.
- The prologue, Chapter 1–9, chapter subrooms, and chapter cutscenes play background music at 40% of the user's Music setting.
- Empty transition paths preserve playback and gain; unrelated non-empty scenes stop music.
- Master and SFX bus values remain unchanged.
- Thosakan's jump cue plays once only at successful jump damage, never at take-off or cancelled jumps.
- Preserve the user's existing uncommitted `scenes/chapter_1/chapter_1.tscn` change.

---

### Task 1: Scene-aware background music gain

**Files:**
- Modify: `tests/test_audio_manager_runtime.gd`
- Modify: `scenes/core/audio_manager.gd`

**Interfaces:**
- Consumes: `AudioManager.sync_music_for_scene_path(scene_path: String) -> void`
- Produces: `MENU_MUSIC_GAIN: float = 1.0`, `GAMEPLAY_MUSIC_GAIN: float = 0.4`, and scene synchronization that controls `Music.volume_db`

- [ ] **Step 1: Write the failing runtime assertions**

Replace the old expectation that the home page stops music with assertions covering menu, gameplay, subroom, cutscene, prologue, return-to-menu, transition preservation, and SFX bus isolation:

```gdscript
var sfx_bus := AudioServer.get_bus_index(&"SFX")
var sfx_before := AudioServer.get_bus_volume_db(sfx_bus)
audio.sync_music_for_scene_path("res://scenes/homepage/home_page.tscn")
var music := audio.get_node("Music") as AudioStreamPlayer
_expect(music.playing, "home page starts music")
_expect(is_equal_approx(music.volume_db, linear_to_db(1.0)), "menu music uses full gain")
audio.sync_music_for_scene_path("res://scenes/prologue/prologue.tscn")
_expect(is_equal_approx(music.volume_db, linear_to_db(0.4)), "prologue music uses gameplay gain")
audio.sync_music_for_scene_path("res://scenes/chapter_1/chapter_1.tscn")
_expect(is_equal_approx(music.volume_db, linear_to_db(0.4)), "chapter music uses gameplay gain")
audio.sync_music_for_scene_path("res://scenes/cutscene/chapter_9_cutscene.tscn")
_expect(is_equal_approx(music.volume_db, linear_to_db(0.4)), "chapter cutscene uses gameplay gain")
var gain_before_transition := music.volume_db
audio.sync_music_for_scene_path("")
_expect(is_equal_approx(music.volume_db, gain_before_transition), "empty scene preserves music gain")
audio.sync_music_for_scene_path("res://scenes/homepage/settings_page.tscn")
_expect(is_equal_approx(music.volume_db, linear_to_db(1.0)), "returning to menu restores full gain")
_expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), sfx_before), "scene music sync leaves SFX bus unchanged")
```

- [ ] **Step 2: Run the audio-manager test and verify RED**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: FAIL because the home page currently stops music and scene synchronization does not apply per-scene `Music.volume_db`.

- [ ] **Step 3: Implement minimal scene classification and gain**

Add constants and update `sync_music_for_scene_path`:

```gdscript
const MENU_MUSIC_GAIN := 1.0
const GAMEPLAY_MUSIC_GAIN := 0.4

func sync_music_for_scene_path(scene_path: String) -> void:
    if scene_path.is_empty():
        return
    var is_menu := scene_path.begins_with("res://scenes/homepage/")
    var is_gameplay := (
        scene_path == "res://scenes/prologue/prologue.tscn"
        or scene_path.begins_with("res://scenes/chapter_")
        or scene_path.begins_with("res://scenes/cutscene/chapter_")
    )
    var music := get_node("Music") as AudioStreamPlayer
    if is_menu or is_gameplay:
        music.volume_db = linear_to_db(
            GAMEPLAY_MUSIC_GAIN if is_gameplay else MENU_MUSIC_GAIN
        )
        if not music.playing and _streams.has(BACKGROUND):
            music.stream = _streams[BACKGROUND]
            music.play()
    else:
        music.stop()
```

- [ ] **Step 4: Run the focused and settings tests**

Run: `sh tests/run_audio_manager_tests.sh && sh tests/run_audio_settings_tests.sh`

Expected: both print `PASS` and exit 0.

- [ ] **Step 5: Commit the music behavior**

```bash
git add tests/test_audio_manager_runtime.gd scenes/core/audio_manager.gd
git commit -m "fix: balance menu and gameplay music"
```

### Task 2: Thosakan jump-impact cue

**Files:**
- Modify: `tests/test_enemy_audio_hooks.gd`
- Modify: `scenes/props/thosakan.gd`

**Interfaces:**
- Consumes: `AudioManager.play_sfx(AudioManager.JUMP_THROW)` and Thosakan's existing `_jump_damage_done` guard
- Produces: `_begin_jump_attack()` with no jump cue and `_begin_jump_impact()` with one cue at successful player damage

- [ ] **Step 1: Add a real damage receiver and failing timing assertions**

Define a minimal receiver in the test and use it as the stage's `Player`:

```gdscript
class DamageReceiver:
    extends Node2D
    var current_health := 100
    var damage_taken := 0
    func take_damage(amount: int) -> void:
        damage_taken += amount
        current_health -= amount
```

Then assert take-off silence, one impact cue, real damage, and duplicate protection:

```gdscript
_events.clear()
thosakan._begin_jump_attack()
_expect(not _events.has(&"jump_throw"), "Thosakan jump take-off is silent")
var damage_before := player.damage_taken
thosakan._begin_jump_impact()
_expect(_events == [&"jump_throw"], "Thosakan jump cue plays at impact")
_expect(player.damage_taken == damage_before + thosakan.jump_damage, "jump impact damages player")
thosakan._begin_jump_impact()
_expect(_events == [&"jump_throw"], "jump impact cue cannot duplicate")
```

- [ ] **Step 2: Run the enemy audio test and verify RED**

Run: `sh tests/run_enemy_audio_tests.sh`

Expected: FAIL because `_begin_jump_attack()` currently emits `jump_throw` before damage.

- [ ] **Step 3: Move the cue into the guarded damage boundary**

Remove the cue from `_begin_jump_attack()` and add it beside the successful damage call:

```gdscript
func _begin_jump_impact() -> void:
    _jump_impact = true
    velocity = Vector2.ZERO
    _sprite.play(JUMP_ANIMATION)
    _sprite.frame = JUMP_IMPACT_FRAME
    _sprite.frame_progress = 0.0
    if not _jump_damage_done and is_instance_valid(_player):
        AudioManager.play_sfx(_special_sound_key(JUMP_ANIMATION))
        _player.take_damage(jump_damage)
        _jump_damage_done = true
```

- [ ] **Step 4: Run the enemy test**

Run: `sh tests/run_enemy_audio_tests.sh`

Expected: `PASS: enemy audio hooks`, exit 0.

- [ ] **Step 5: Commit the jump timing fix**

```bash
git add tests/test_enemy_audio_hooks.gd scenes/props/thosakan.gd
git commit -m "fix: sync Thosakan jump sound with damage"
```

### Task 3: Integrated verification

**Files:**
- Verify only; do not modify `scenes/chapter_1/chapter_1.tscn`

**Interfaces:**
- Consumes: all global audio behavior from Tasks 1–2
- Produces: fresh verification evidence for the completed change

- [ ] **Step 1: Run every audio regression suite**

Run: `for test_script in tests/run_*_tests.sh; do sh "$test_script"; done`

Expected: all scripts print `PASS` and exit 0.

- [ ] **Step 2: Parse the full project headlessly**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-music-jump-parse.log --editor --path . --quit`

Expected: exit 0 with no GDScript parse error.

- [ ] **Step 3: Smoke-test the main scene**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/ramakien-music-jump-smoke.log --path . --quit-after 120`

Expected: exit 0 with no gameplay/script error.

- [ ] **Step 4: Check whitespace and repository scope**

Run: `git diff --check && git status --short --branch`

Expected: no whitespace errors; only the pre-existing user modification to `scenes/chapter_1/chapter_1.tscn` remains unstaged after implementation commits.
