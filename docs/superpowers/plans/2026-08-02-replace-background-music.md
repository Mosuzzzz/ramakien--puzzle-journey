# Replace Background Music Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the normal game background track with the supplied `sound.mp3` without changing any music logic.

**Architecture:** Preserve the existing `res://assets/audio/music/background.mp3` resource path and replace only its binary contents. Godot will reimport that resource, so every existing menu, chapter, volume, loop, fade, and restoration path continues working without GDScript changes.

**Tech Stack:** Godot 4.7.1, MP3 resources, GDScript runtime tests, POSIX shell verification

## Global Constraints

- Keep the destination resource path exactly `res://assets/audio/music/background.mp3`.
- Preserve current menu/gameplay volume levels, looping, audio buses, fade behavior, and boss-music behavior.
- Do not modify sound effects or `assets/audio/music/boss_fight.mp3`.
- The destination binary must match `/Users/siwakornbundi/Downloads/sound.mp3` by SHA-256.

---

### Task 1: Replace and Reimport the Normal Background Track

**Files:**
- Modify: `assets/audio/music/background.mp3`
- Generated/possibly refreshed: `assets/audio/music/background.mp3.import`
- Verify: `tests/test_audio_manager_runtime.gd`
- Verify: `tests/run_audio_manager_tests.sh`

**Interfaces:**
- Consumes: `AudioManager.SOUND_PATHS[BACKGROUND]` at `res://assets/audio/music/background.mp3`
- Produces: the same looping `AudioStreamMP3` resource path containing the supplied new audio

- [ ] **Step 1: Verify the supplied file exists and reproduce the current mismatch**

Run:

```bash
test -f /Users/siwakornbundi/Downloads/sound.mp3
shasum -a 256 assets/audio/music/background.mp3 /Users/siwakornbundi/Downloads/sound.mp3
```

Expected: both hashes are printed and differ, proving the project still contains the old track.

- [ ] **Step 2: Replace the destination binary without changing its resource path**

Run:

```bash
cp /Users/siwakornbundi/Downloads/sound.mp3 assets/audio/music/background.mp3
```

Expected: `assets/audio/music/background.mp3` remains at the same path and now contains the new audio.

- [ ] **Step 3: Verify the replacement exactly matches the supplied file**

Run:

```bash
shasum -a 256 assets/audio/music/background.mp3 /Users/siwakornbundi/Downloads/sound.mp3
```

Expected: both SHA-256 values equal `d0c21acb518ec227f6569f13dfe4a4b31a100304c44dd9479a80918f27106dd3`.

- [ ] **Step 4: Reimport the changed resource in Godot**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit --log-file /tmp/ramakien-background-music-import.log
```

Expected: exit code 0 and the import log processes `background.mp3` without a resource-load failure.

- [ ] **Step 5: Run the focused AudioManager test**

Run:

```bash
sh tests/run_audio_manager_tests.sh
```

Expected: exit code 0 and `PASS: audio manager runtime`, proving the replacement loads, loops, and preserves music selection behavior.

- [ ] **Step 6: Run the full audio regression suite**

Run:

```bash
for test_script in tests/run_audio_manager_tests.sh tests/run_audio_settings_tests.sh tests/run_boss_music_hook_tests.sh tests/run_enemy_audio_tests.sh tests/run_pickup_audio_tests.sh tests/run_player_audio_tests.sh tests/run_portal_audio_tests.sh tests/run_potion_pickup_rendering_tests.sh tests/run_puzzle_audio_tests.sh tests/run_story_advance_audio_tests.sh tests/run_world_movement_audio_tests.sh; do sh "$test_script" || exit 1; done
```

Expected: exit code 0 and all 11 test scripts print `PASS`.

- [ ] **Step 7: Check the final diff and commit the replacement**

Run:

```bash
git diff --check
git status --short
git add assets/audio/music/background.mp3 assets/audio/music/background.mp3.import
git commit -m "feat: replace background music track"
```

Expected: only the background MP3 and any Godot-refreshed import metadata are committed; no sound effects, boss track, or GDScript files change.
