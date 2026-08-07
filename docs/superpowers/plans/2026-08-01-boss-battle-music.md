# Boss Battle Music Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play the supplied looping boss track during undefeated Miyarap and Thotsakan encounters, then fade back to the normal gameplay track at the chapter-specific approved moment.

**Architecture:** Extend the global AudioManager as the sole music owner and use its existing Music player for sequential fade-out, stream replacement, and fade-in. Chapter 5 restores normal music from a new post-boss-cutscene completion signal, while Chapter 9 restores it directly from Thotsakan's defeated signal.

**Tech Stack:** Godot 4.7, GDScript, AudioStreamPlayer, Tween, MP3 imports, headless SceneTree tests

## Global Constraints

- Copy /Users/siwakornbundi/Downloads/Boss fight.mp3 to res://assets/audio/music/boss_fight.mp3; do not alter the source file.
- Use one global music player so the normal and boss tracks never overlap.
- Fade the outgoing track fully to silence over exactly 1.5 seconds before starting the incoming track.
- Fade the incoming track to GAMEPLAY_MUSIC_GAIN over exactly 1.5 seconds.
- Boss music must loop and finish at the same gain as normal gameplay music.
- Chapter 5 must keep boss music through the full post-Miyarap cutscene, including its skip flow.
- Chapter 9 must restore normal music immediately when Thotsakan emits defeated.
- Restored normal music must start from position zero.
- Saved chapters whose boss is already defeated must not start boss music.

---

## File Structure

- assets/audio/music/boss_fight.mp3: imported looping boss music asset.
- scenes/core/audio_manager.gd: registry, boss override state, and sequential transition API.
- scenes/cutscene/chapter_5_post_boss_cutscene.gd: authoritative completion event for normal completion and skip.
- scenes/chapter_5/chapter_5.gd: Miyarap music lifecycle.
- scenes/chapter_9/chapter_9.gd: Thotsakan music lifecycle.
- tests/test_audio_manager_runtime.gd: runtime transition coverage.
- tests/test_boss_music_hooks.gd: chapter and cutscene hook coverage.
- tests/run_boss_music_tests.sh: focused test runner.

### Task 1: Global boss-music transition API

**Files:**
- Create: assets/audio/music/boss_fight.mp3
- Generated: assets/audio/music/boss_fight.mp3.import
- Modify: scenes/core/audio_manager.gd
- Modify: tests/test_audio_manager_runtime.gd

**Interfaces:**
- Consumes: AudioManager.Music, BACKGROUND, GAMEPLAY_MUSIC_GAIN, and sync_music_for_scene_path(scene_path: String).
- Produces: BOSS_FIGHT: StringName, play_boss_music(fade_seconds: float = 1.5) -> void, and restore_background_music(fade_seconds: float = 1.5) -> void.

- [ ] **Step 1: Write the failing AudioManager assertions**

Add &"boss_fight" to the sound-key array in tests/test_audio_manager_runtime.gd. After the existing scene-music assertions, add:

    _expect(audio.has_method("play_boss_music"), "boss music start API exists")
    _expect(audio.has_method("restore_background_music"), "background restore API exists")
    audio.sync_music_for_scene_path("res://scenes/chapter_5/chapter_5.tscn")
    var music := audio.get_node("Music") as AudioStreamPlayer
    audio.play_boss_music(0.0)
    await process_frame
    _expect(
        music.stream != null and music.stream.resource_path.ends_with("boss_fight.mp3"),
        "boss request selects boss track"
    )
    _expect(music.playing, "boss track starts playing")
    _expect(
        is_equal_approx(music.volume_db, linear_to_db(0.3)),
        "boss track uses gameplay gain"
    )
    _expect(music.stream is AudioStreamMP3 and music.stream.loop, "boss MP3 loops")
    music.seek(2.0)
    audio.play_boss_music(0.0)
    _expect(music.get_playback_position() >= 1.9, "repeated boss request does not restart")
    audio.restore_background_music(0.0)
    await process_frame
    _expect(
        music.stream != null and music.stream.resource_path.ends_with("background.mp3"),
        "restore request selects normal track"
    )
    _expect(music.get_playback_position() < 0.5, "normal track restarts from beginning")
    _expect(music.stream is AudioStreamMP3 and music.stream.loop, "normal MP3 still loops")

- [ ] **Step 2: Run the test and verify the new contract fails**

Run: tests/run_audio_manager_tests.sh

Expected: FAIL because boss_fight and both public methods are missing.

- [ ] **Step 3: Add and import the boss asset**

Run:

    cp "/Users/siwakornbundi/Downloads/Boss fight.mp3" assets/audio/music/boss_fight.mp3
    /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit --log-file /tmp/ramakien-boss-music-import.log

Expected: assets/audio/music/boss_fight.mp3.import exists with no import error.

- [ ] **Step 4: Add transition state and public APIs**

In scenes/core/audio_manager.gd add:

    const BOSS_FIGHT := &"boss_fight"
    const MUSIC_FADE_SECONDS := 1.5
    const SILENT_MUSIC_DB := -80.0

Add BOSS_FIGHT: "res://assets/audio/music/boss_fight.mp3" to SOUND_PATHS. Add:

    var _music_tween: Tween
    var _music_request_serial := 0
    var _requested_music_key: StringName = &""
    var _boss_music_active := false
    var _last_scene_path := ""


    func play_boss_music(fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
        _boss_music_active = true
        _request_music(BOSS_FIGHT, GAMEPLAY_MUSIC_GAIN, true, fade_seconds)


    func restore_background_music(fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
        _boss_music_active = false
        _request_music(BACKGROUND, _music_gain_for_scene(_last_scene_path), true, fade_seconds)

Extend MP3 looping:

    if stream is AudioStreamMP3 and key in [BACKGROUND, BOSS_FIGHT, RUN]:
        stream.loop = true

Add these helpers:

    func _request_music(
        sound_key: StringName,
        target_gain: float,
        restart_from_beginning: bool,
        fade_seconds: float
    ) -> void:
        var music := get_node("Music") as AudioStreamPlayer
        if not _streams.has(sound_key):
            push_warning("AudioManager: unknown or missing music '%s'" % sound_key)
            return
        var target_stream := _streams[sound_key] as AudioStream
        if _requested_music_key == sound_key:
            if (
                _music_tween != null
                and _music_tween.is_valid()
                and _music_tween.is_running()
            ):
                return
            if music.stream == target_stream and music.playing:
                music.volume_db = linear_to_db(target_gain)
                return
        _requested_music_key = sound_key
        _music_request_serial += 1
        var serial := _music_request_serial
        if _music_tween != null and _music_tween.is_valid():
            _music_tween.kill()
        if fade_seconds <= 0.0 or not music.playing:
            _swap_and_fade_in(
                sound_key, target_gain, restart_from_beginning, fade_seconds, serial
            )
            return
        _music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        _music_tween.tween_property(music, "volume_db", SILENT_MUSIC_DB, fade_seconds)
        _music_tween.tween_callback(
            _swap_and_fade_in.bind(
                sound_key, target_gain, restart_from_beginning, fade_seconds, serial
            )
        )


    func _swap_and_fade_in(
        sound_key: StringName,
        target_gain: float,
        restart_from_beginning: bool,
        fade_seconds: float,
        serial: int
    ) -> void:
        if serial != _music_request_serial:
            return
        var music := get_node("Music") as AudioStreamPlayer
        var target_stream := _streams[sound_key] as AudioStream
        var start_position := 0.0
        if not restart_from_beginning and music.stream == target_stream and music.playing:
            start_position = music.get_playback_position()
        music.stream = target_stream
        music.volume_db = (
            SILENT_MUSIC_DB if fade_seconds > 0.0 else linear_to_db(target_gain)
        )
        music.play(start_position)
        if fade_seconds <= 0.0:
            return
        _music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        _music_tween.tween_property(
            music, "volume_db", linear_to_db(target_gain), fade_seconds
        )


    func _music_gain_for_scene(scene_path: String) -> float:
        return (
            MENU_MUSIC_GAIN
            if scene_path.begins_with("res://scenes/homepage/")
            else GAMEPLAY_MUSIC_GAIN
        )

Replace the body of `sync_music_for_scene_path` with the explicit override-aware flow below. This records the real scene, preserves boss music only in gameplay, restores background music without restarting an unchanged stream, and preserves the current behavior for an empty transient path:

    func sync_music_for_scene_path(scene_path: String) -> void:
        if scene_path.is_empty():
            return
        _last_scene_path = scene_path
        var is_menu := scene_path.begins_with("res://scenes/homepage/")
        var is_gameplay := (
            scene_path == "res://scenes/prologue/prologue.tscn"
            or scene_path.begins_with("res://scenes/chapter_")
            or scene_path.begins_with("res://scenes/cutscene/chapter_")
        )
        if not is_menu and not is_gameplay:
            _boss_music_active = false
            _music_request_serial += 1
            if _music_tween != null and _music_tween.is_valid():
                _music_tween.kill()
            _music_tween = null
            _requested_music_key = &""
            (get_node("Music") as AudioStreamPlayer).stop()
            return
        if _boss_music_active and is_gameplay:
            return
        _boss_music_active = false
        _request_music(
            BACKGROUND,
            GAMEPLAY_MUSIC_GAIN if is_gameplay else MENU_MUSIC_GAIN,
            false,
            0.0
        )

- [ ] **Step 5: Run the AudioManager test**

Run: tests/run_audio_manager_tests.sh

Expected: PASS: audio manager runtime, with no missing boss resource warning.

- [ ] **Step 6: Commit Task 1**

    git add assets/audio/music/boss_fight.mp3 assets/audio/music/boss_fight.mp3.import scenes/core/audio_manager.gd tests/test_audio_manager_runtime.gd
    git commit -m "feat: add boss battle music transitions"

### Task 2: Keep Miyarap music through the post-boss cutscene

**Files:**
- Create: tests/test_boss_music_hooks.gd
- Create: tests/run_boss_music_tests.sh
- Modify: scenes/cutscene/chapter_5_post_boss_cutscene.gd
- Modify: scenes/chapter_5/chapter_5.gd

**Interfaces:**
- Consumes: AudioManager.play_boss_music(), AudioManager.restore_background_music(), and GameState.chapter_5_post_boss_played.
- Produces: Chapter5PostBossCutscene.finished and _on_post_boss_cutscene_finished() -> void.

- [ ] **Step 1: Write the failing hook test**

Create tests/test_boss_music_hooks.gd:

    extends SceneTree

    var _failures: Array[String] = []


    func _initialize() -> void:
        call_deferred("_run")


    func _run() -> void:
        var chapter_5_source := FileAccess.get_file_as_string(
            "res://scenes/chapter_5/chapter_5.gd"
        )
        _expect(
            chapter_5_source.contains("AudioManager.play_boss_music()"),
            "Chapter 5 starts boss music"
        )
        _expect(
            chapter_5_source.contains("AudioManager.restore_background_music()"),
            "Chapter 5 restores normal music"
        )
        _expect(
            chapter_5_source.contains("_on_post_boss_cutscene_finished"),
            "Chapter 5 waits for the post-boss cutscene"
        )

        var cutscene := Control.new()
        cutscene.set_script(
            load("res://scenes/cutscene/chapter_5_post_boss_cutscene.gd")
        )
        root.add_child(cutscene)
        var finish_count := [0]
        cutscene.connect(&"finished", func(): finish_count[0] += 1)
        cutscene.call("_finish_cutscene")
        await process_frame
        _expect(finish_count[0] == 1, "post-boss cutscene emits finished")
        cutscene.call("_finish_cutscene")
        await process_frame
        _expect(finish_count[0] == 1, "post-boss cutscene emits finished once")
        cutscene.free()
        _finish()


    func _expect(condition: bool, message: String) -> void:
        if not condition:
            _failures.append(message)


    func _finish() -> void:
        if _failures.is_empty():
            print("PASS: boss music hooks")
            quit(0)
            return
        for failure in _failures:
            push_error(failure)
        quit(1)

Create tests/run_boss_music_tests.sh:

    #!/bin/sh
    set -eu
    exec /Applications/Godot.app/Contents/MacOS/Godot \
      --headless --log-file /tmp/ramakien-boss-music-hooks-test.log \
      --path . --script res://tests/test_boss_music_hooks.gd

Make it executable: chmod +x tests/run_boss_music_tests.sh

- [ ] **Step 2: Run it and verify failure**

Run: tests/run_boss_music_tests.sh

Expected: FAIL because the cutscene has no finished signal and Chapter 5 has no music calls.

- [ ] **Step 3: Emit one cutscene completion event**

At the top of scenes/cutscene/chapter_5_post_boss_cutscene.gd add:

    signal finished

At the end of _finish_cutscene, after hide() and get_tree().paused = false, add:

    finished.emit()

Do not emit elsewhere. Normal completion and skip converge on _finish_cutscene, whose _finished guard enforces exactly-once delivery.

- [ ] **Step 4: Integrate Chapter 5**

In _ready() of scenes/chapter_5/chapter_5.gd connect once:

    if not _post_boss_cutscene.is_connected(
        &"finished", _on_post_boss_cutscene_finished
    ):
        _post_boss_cutscene.connect(
            &"finished", _on_post_boss_cutscene_finished
        )

In the undefeated branch where boss != null:

    AudioManager.play_boss_music()

Do not restore music from _on_miyarap_removed. Add:

    func _on_post_boss_cutscene_finished() -> void:
        AudioManager.restore_background_music()

When chapter_5_post_boss_played is already true, call AudioManager.restore_background_music(0.0). The idempotent API must leave an unchanged normal track at its current position.

- [ ] **Step 5: Run focused tests**

Run:

    tests/run_boss_music_tests.sh
    tests/run_audio_manager_tests.sh

Expected: both scripts print PASS; calling _finish_cutscene twice emits once.

- [ ] **Step 6: Commit Task 2**

    git add scenes/chapter_5/chapter_5.gd scenes/cutscene/chapter_5_post_boss_cutscene.gd tests/test_boss_music_hooks.gd tests/run_boss_music_tests.sh
    git commit -m "feat: keep boss music through Miyarap cutscene"

### Task 3: Add Thotsakan boss-music lifecycle

**Files:**
- Modify: scenes/chapter_9/chapter_9.gd
- Modify: tests/test_boss_music_hooks.gd

**Interfaces:**
- Consumes: AudioManager.play_boss_music(), AudioManager.restore_background_music(), and GameState.chapter_9_thotsakan_defeated.
- Produces: Chapter 9 start and restore calls through _on_thotsakan_defeated(_defeated_thotsakan: CharacterBody2D).

- [ ] **Step 1: Add failing Chapter 9 assertions**

In tests/test_boss_music_hooks.gd add:

    var chapter_9_source := FileAccess.get_file_as_string(
        "res://scenes/chapter_9/chapter_9.gd"
    )
    _expect(
        chapter_9_source.contains("AudioManager.play_boss_music()"),
        "Chapter 9 starts boss music"
    )
    _expect(
        chapter_9_source.contains("AudioManager.restore_background_music()"),
        "Chapter 9 restores normal music"
    )
    var defeat_handler_start := chapter_9_source.find("func _on_thotsakan_defeated")
    var defeat_handler := chapter_9_source.substr(defeat_handler_start)
    _expect(
        defeat_handler.find("GameState.chapter_9_thotsakan_defeated = true")
            < defeat_handler.find("AudioManager.restore_background_music()"),
        "Chapter 9 saves defeat before restoring music"
    )

- [ ] **Step 2: Run and verify Chapter 9 failure**

Run: tests/run_boss_music_tests.sh

Expected: FAIL on the Chapter 9 start and restore assertions.

- [ ] **Step 3: Integrate Chapter 9**

Replace the opening saved-state branch with:

    if GameState.chapter_9_thotsakan_defeated:
        AudioManager.restore_background_music(0.0)
        _thotsakan.queue_free()
    elif not _thotsakan.defeated.is_connected(_on_thotsakan_defeated):
        AudioManager.play_boss_music()
        _thotsakan.defeated.connect(_on_thotsakan_defeated)

Extend the existing handler:

    func _on_thotsakan_defeated(
        _defeated_thotsakan: CharacterBody2D
    ) -> void:
        GameState.chapter_9_thotsakan_defeated = true
        AudioManager.restore_background_music()

- [ ] **Step 4: Run focused tests**

Run:

    tests/run_boss_music_tests.sh
    tests/run_audio_manager_tests.sh

Expected: both scripts print PASS with no parser errors.

- [ ] **Step 5: Commit Task 3**

    git add scenes/chapter_9/chapter_9.gd tests/test_boss_music_hooks.gd
    git commit -m "feat: score the Thotsakan boss fight"

### Task 4: Regression and scene-load verification

**Files:**
- Verify only; no planned source changes.

**Interfaces:**
- Consumes: Tasks 1-3.
- Produces: complete verification evidence.

- [ ] **Step 1: Run every audio and pickup regression**

Run:

    tests/run_audio_manager_tests.sh
    tests/run_audio_settings_tests.sh
    tests/run_enemy_audio_tests.sh
    tests/run_pickup_audio_tests.sh
    tests/run_player_audio_tests.sh
    tests/run_portal_audio_tests.sh
    tests/run_potion_pickup_rendering_tests.sh
    tests/run_puzzle_audio_tests.sh
    tests/run_story_advance_audio_tests.sh
    tests/run_world_movement_audio_tests.sh
    tests/run_boss_music_tests.sh

Expected: all eleven scripts print PASS and return exit code 0.

- [ ] **Step 2: Run full import and parse verification**

Run:

    /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit --log-file /tmp/ramakien-boss-music-final-parse.log

Expected: exit code 0, no GDScript parse error, and no missing boss resource.

- [ ] **Step 3: Inspect repository state**

Run:

    git status --short
    git diff --check
    git log -3 --oneline

Expected: no uncommitted implementation files, no whitespace errors, and the three planned implementation commits are present.

- [ ] **Step 4: Perform manual gameplay checks**

1. Enter fresh Chapter 5: normal music fades out, then boss music fades in.
2. Defeat Miyarap: boss music continues through all dialogue and the Lanka-march phase.
3. Finish and separately skip that cutscene: only then normal music restarts from its beginning.
4. Reload completed Chapter 5: boss music does not return.
5. Enter fresh Chapter 9: normal music fades out, then boss music fades in.
6. Defeat Thotsakan: normal music returns from its beginning.
7. Reload completed Chapter 9: boss music does not return.

If a manual check exposes a defect, add a focused failing assertion before modifying production code, then rerun Steps 1-3.
