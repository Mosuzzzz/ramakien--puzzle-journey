# Global Game Audio System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่มเพลงพื้นหลังและเสียงเอฟเฟกต์ที่ผู้ใช้ให้มาให้ครบทุกเหตุการณ์ที่เกี่ยวข้องใน Chapter 1–9 พร้อมปรับ Music/SFX แยกกันและบันทึกค่าได้

**Architecture:** ใช้ `AudioManager` Autoload เพียงจุดเดียวสำหรับเพลง, run loop, SFX pool และเสียงคลิกปุ่มอัตโนมัติ ทุก gameplay script เรียกด้วย sound key แทนการสร้าง `AudioStreamPlayer` เอง เพลงตรวจ scene ปัจจุบันและเล่นต่อเนื่องเมื่อเปลี่ยนระหว่าง Chapter/ห้องย่อย/คัตซีน ส่วน Settings ควบคุม bus `Master`, `Music`, `SFX` และเก็บค่าใน `user://settings.cfg`

**Tech Stack:** Godot 4.7.1, GDScript, AudioStreamMP3, Godot headless runtime tests, ConfigFile

## Global Constraints

- ห้ามเล่นเสียงโจมตีศัตรูทั่วไปซ้อนกับเสียงเฉพาะของทศกัณหรือไมยราพ
- เพลง `Background.mp3` ต้องไม่เริ่มใหม่เมื่อเปลี่ยนห้องใน Chapter 1–9
- `run.mp3` มีได้เพียงหนึ่ง loop และต้องหยุดเมื่อ idle, attack, hurt/knockback, death หรือ player ออกจาก tree
- SFX pool ต้องเล่นขณะเกม pause ในหน้า quiz/puzzle ได้
- ไฟล์เสียงที่หาไม่พบต้อง `push_warning()` และข้ามเสียงนั้น โดยเกมไม่ crash
- ทุกการเปลี่ยน behavior เริ่มจาก test ที่ล้มก่อน แล้วค่อยเขียน implementation
- ใช้ Godot executable: `/Applications/Godot.app/Contents/MacOS/Godot`

---

### Task 1: Import audio assets and define audio buses

**Files:**
- Create: `assets/audio/music/background.mp3`
- Create: `assets/audio/sfx/answer_correct.mp3`
- Create: `assets/audio/sfx/answer_wrong.mp3`
- Create: `assets/audio/sfx/button_click.mp3`
- Create: `assets/audio/sfx/enemy_attacking.mp3`
- Create: `assets/audio/sfx/enemy_hit.mp3`
- Create: `assets/audio/sfx/pickup.mp3`
- Create: `assets/audio/sfx/run.mp3`
- Create: `assets/audio/sfx/sword_attack.mp3`
- Create: `assets/audio/sfx/hurt.mp3`
- Create: `assets/audio/sfx/thrash.mp3`
- Create: `assets/audio/sfx/giant.mp3`
- Create: `assets/audio/sfx/wave.mp3`
- Create: `assets/audio/sfx/jump_throw.mp3`
- Create: `assets/audio/sfx/heal_and_pull.mp3`
- Create: `assets/audio/sfx/giant_attack.mp3`
- Create: `default_bus_layout.tres`

- [ ] **Step 1: Copy the supplied binary assets with stable lowercase names**

Run:

```bash
mkdir -p assets/audio/music assets/audio/sfx
cp "/Users/siwakornbundi/Downloads/Background.mp3" assets/audio/music/background.mp3
cp "/Users/siwakornbundi/Downloads/answer_correct.mp3" assets/audio/sfx/answer_correct.mp3
cp "/Users/siwakornbundi/Downloads/answer_wrong.mp3" assets/audio/sfx/answer_wrong.mp3
cp "/Users/siwakornbundi/Downloads/button_click.mp3" assets/audio/sfx/button_click.mp3
cp "/Users/siwakornbundi/Downloads/Enemy_attacking.mp3" assets/audio/sfx/enemy_attacking.mp3
cp "/Users/siwakornbundi/Downloads/enemy_hit.mp3" assets/audio/sfx/enemy_hit.mp3
cp "/Users/siwakornbundi/Downloads/pickup.mp3" assets/audio/sfx/pickup.mp3
cp "/Users/siwakornbundi/Downloads/run.mp3" assets/audio/sfx/run.mp3
cp "/Users/siwakornbundi/Downloads/sword_attack.mp3" assets/audio/sfx/sword_attack.mp3
cp "/Users/siwakornbundi/Downloads/hurt.mp3" assets/audio/sfx/hurt.mp3
cp "/Users/siwakornbundi/Downloads/thrash.mp3" assets/audio/sfx/thrash.mp3
cp "/Users/siwakornbundi/Downloads/giant.mp3" assets/audio/sfx/giant.mp3
cp "/Users/siwakornbundi/Downloads/Wave.mp3" assets/audio/sfx/wave.mp3
cp "/Users/siwakornbundi/Downloads/Jump throw.mp3" assets/audio/sfx/jump_throw.mp3
cp "/Users/siwakornbundi/Downloads/Heal and Pull.mp3" assets/audio/sfx/heal_and_pull.mp3
cp "/Users/siwakornbundi/Downloads/Giant Attack.mp3" assets/audio/sfx/giant_attack.mp3
```

- [ ] **Step 2: Create `default_bus_layout.tres`**

```ini
[gd_resource format=3]

[resource]
bus/0/name = &"Master"
bus/0/solo = false
bus/0/mute = false
bus/0/bypass_fx = false
bus/0/volume_db = 0.0
bus/0/send = &""
bus/1/name = &"Music"
bus/1/solo = false
bus/1/mute = false
bus/1/bypass_fx = false
bus/1/volume_db = 0.0
bus/1/send = &"Master"
bus/2/name = &"SFX"
bus/2/solo = false
bus/2/mute = false
bus/2/bypass_fx = false
bus/2/volume_db = 0.0
bus/2/send = &"Master"
```

- [ ] **Step 3: Trigger import and verify all resources load**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
```

Expected: exit 0, no MP3 import errors.

- [ ] **Step 4: Commit**

```bash
git add assets/audio default_bus_layout.tres
git commit -m "assets: add global music and sound effects"
```

---

### Task 2: Build the central AudioManager with runtime tests

**Files:**
- Create: `scenes/core/audio_manager.gd`
- Create: `tests/test_audio_manager_runtime.gd`
- Create: `tests/run_audio_manager_tests.sh`
- Modify: `project.godot`

- [ ] **Step 1: Write the failing runtime test**

`tests/test_audio_manager_runtime.gd`:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio := root.get_node_or_null("AudioManager")
	_expect(audio != null, "AudioManager autoload exists")
	if audio != null:
		_expect(audio.has_signal("sfx_played"), "SFX is observable")
		_expect(audio.has_method("play_sfx"), "play_sfx API exists")
		_expect(audio.has_method("set_run_active"), "run-loop API exists")
		_expect(audio.get_node_or_null("Music") != null, "dedicated Music player exists")
		_expect(audio.get_node_or_null("RunLoop") != null, "dedicated RunLoop player exists")
		var keys: Array[StringName] = [
			&"answer_correct", &"answer_wrong", &"button_click",
			&"enemy_attacking", &"enemy_hit", &"pickup", &"run",
			&"sword_attack", &"hurt", &"thrash", &"giant", &"wave",
			&"jump_throw", &"heal_and_pull", &"giant_attack",
		]
		for key in keys:
			_expect(audio.has_sound(key), "sound key loads: %s" % key)
		var heard: Array[StringName] = []
		audio.sfx_played.connect(func(key: StringName): heard.append(key))
		audio.play_sfx(&"pickup")
		await process_frame
		_expect(heard == [&"pickup"], "valid SFX emits exactly once")
		audio.play_sfx(&"missing_key")
		await process_frame
		_expect(heard == [&"pickup"], "unknown key is ignored")
		var owner := Node.new()
		root.add_child(owner)
		audio.set_run_active(owner, true)
		_expect(audio.get_node("RunLoop").playing, "run loop starts")
		audio.set_run_active(owner, false)
		_expect(not audio.get_node("RunLoop").playing, "run loop stops")
		owner.queue_free()
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS: audio manager runtime")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

`tests/run_audio_manager_tests.sh`:

```bash
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tests/test_audio_manager_runtime.gd
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: FAIL because `AudioManager` is not registered.

- [ ] **Step 3: Implement `AudioManager`**

Use these public constants and API in `scenes/core/audio_manager.gd`:

```gdscript
extends Node

signal sfx_played(sound_key: StringName)

const BACKGROUND := &"background"
const ANSWER_CORRECT := &"answer_correct"
const ANSWER_WRONG := &"answer_wrong"
const BUTTON_CLICK := &"button_click"
const ENEMY_ATTACKING := &"enemy_attacking"
const ENEMY_HIT := &"enemy_hit"
const PICKUP := &"pickup"
const RUN := &"run"
const SWORD_ATTACK := &"sword_attack"
const HURT := &"hurt"
const THRASH := &"thrash"
const GIANT := &"giant"
const WAVE := &"wave"
const JUMP_THROW := &"jump_throw"
const HEAL_AND_PULL := &"heal_and_pull"
const GIANT_ATTACK := &"giant_attack"
const SFX_POOL_SIZE := 12

const SOUND_PATHS := {
	BACKGROUND: "res://assets/audio/music/background.mp3",
	ANSWER_CORRECT: "res://assets/audio/sfx/answer_correct.mp3",
	ANSWER_WRONG: "res://assets/audio/sfx/answer_wrong.mp3",
	BUTTON_CLICK: "res://assets/audio/sfx/button_click.mp3",
	ENEMY_ATTACKING: "res://assets/audio/sfx/enemy_attacking.mp3",
	ENEMY_HIT: "res://assets/audio/sfx/enemy_hit.mp3",
	PICKUP: "res://assets/audio/sfx/pickup.mp3",
	RUN: "res://assets/audio/sfx/run.mp3",
	SWORD_ATTACK: "res://assets/audio/sfx/sword_attack.mp3",
	HURT: "res://assets/audio/sfx/hurt.mp3",
	THRASH: "res://assets/audio/sfx/thrash.mp3",
	GIANT: "res://assets/audio/sfx/giant.mp3",
	WAVE: "res://assets/audio/sfx/wave.mp3",
	JUMP_THROW: "res://assets/audio/sfx/jump_throw.mp3",
	HEAL_AND_PULL: "res://assets/audio/sfx/heal_and_pull.mp3",
	GIANT_ATTACK: "res://assets/audio/sfx/giant_attack.mp3",
}

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _pool_cursor := 0
var _run_owner: Node
var _last_scene_id := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_create_players()
	get_tree().node_added.connect(_on_node_added)
	_sync_music_for_current_scene.call_deferred()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	if scene_id != _last_scene_id:
		_last_scene_id = scene_id
		_sync_music_for_current_scene()
	if _run_owner != null and not is_instance_valid(_run_owner):
		stop_run_loop()

func has_sound(sound_key: StringName) -> bool:
	return _streams.has(sound_key)

func play_sfx(sound_key: StringName) -> void:
	if not _streams.has(sound_key):
		push_warning("AudioManager: unknown or missing sound '%s'" % sound_key)
		return
	var player := _next_sfx_player()
	player.stream = _streams[sound_key]
	player.play()
	sfx_played.emit(sound_key)

func set_run_active(owner: Node, active: bool) -> void:
	if active:
		_run_owner = owner
		var player := get_node("RunLoop") as AudioStreamPlayer
		if not player.playing and _streams.has(RUN):
			player.stream = _streams[RUN]
			player.play()
	else:
		if _run_owner == owner or _run_owner == null:
			stop_run_loop()

func stop_run_loop() -> void:
	_run_owner = null
	(get_node("RunLoop") as AudioStreamPlayer).stop()

func _load_streams() -> void:
	for key: StringName in SOUND_PATHS:
		var path := String(SOUND_PATHS[key])
		if not ResourceLoader.exists(path):
			push_warning("AudioManager: missing resource %s" % path)
			continue
		var stream := ResourceLoader.load(path) as AudioStream
		if stream == null:
			push_warning("AudioManager: failed to load %s" % path)
			continue
		if stream is AudioStreamMP3 and key in [BACKGROUND, RUN]:
			stream.loop = true
		_streams[key] = stream

func _create_players() -> void:
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.bus = &"Music"
	 add_child(music)
	var run_loop := AudioStreamPlayer.new()
	run_loop.name = "RunLoop"
	run_loop.bus = &"SFX"
	add_child(run_loop)
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%02d" % index
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

func _next_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	var player := _sfx_players[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % _sfx_players.size()
	return player
```

Add music/button helpers described in Task 4 rather than duplicating them here.

- [ ] **Step 4: Register the Autoload after Settings in `project.godot`**

```ini
Settings="*res://scenes/ui/settings.gd"
AudioManager="*res://scenes/core/audio_manager.gd"
```

- [ ] **Step 5: Run test and commit**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: PASS.

```bash
git add project.godot scenes/core/audio_manager.gd tests
git commit -m "feat: add central audio manager"
```

---

### Task 3: Persist independent Master, Music, and SFX settings

**Files:**
- Modify: `scenes/ui/settings.gd`
- Modify: `scenes/ui/pause_menu.gd`
- Modify: `scenes/homepage/settings_page.tscn`
- Modify: `scenes/ui/pause_menu.tscn`
- Create: `tests/test_audio_settings_runtime.gd`
- Create: `tests/run_audio_settings_tests.sh`

- [ ] **Step 1: Write a failing test for independent buses and persistence**

Test a temporary `ConfigFile` path by adding `Settings.save_to(path)` and `Settings.load_from(path)` public helpers. Assertions:

```gdscript
Settings.set_master_volume(0.9)
Settings.set_music_volume(0.25)
Settings.set_sfx_volume(0.7)
_expect(is_equal_approx(Settings.music_volume, 0.25), "music is independent")
_expect(is_equal_approx(Settings.sfx_volume, 0.7), "SFX is independent")
_expect(is_equal_approx(
	AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),
	linear_to_db(0.25)
), "Music bus updated")
_expect(is_equal_approx(
	AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")),
	linear_to_db(0.7)
), "SFX bus updated")
Settings.save_to("user://audio_settings_test.cfg")
Settings.music_volume = 1.0
Settings.sfx_volume = 1.0
Settings.load_from("user://audio_settings_test.cfg")
_expect(is_equal_approx(Settings.music_volume, 0.25), "music persisted")
_expect(is_equal_approx(Settings.sfx_volume, 0.7), "SFX persisted")
DirAccess.remove_absolute(ProjectSettings.globalize_path("user://audio_settings_test.cfg"))
```

- [ ] **Step 2: Run test and verify failure**

Run: `sh tests/run_audio_settings_tests.sh`

Expected: parse/runtime failure because Music/SFX APIs do not exist.

- [ ] **Step 3: Extend `Settings`**

Implement:

```gdscript
var music_volume := 1.0
var sfx_volume := 1.0

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(&"Music", music_volume)
	_save()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(&"SFX", sfx_volume)
	_save()

func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Settings: missing audio bus %s" % bus_name)
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
```

Load/save keys `audio/master`, `audio/music`, `audio/sfx`; old config without the new keys defaults both to `master_volume`. `_ready()` must apply all three buses.

- [ ] **Step 4: Wire all three rows on both settings screens**

In `settings.gd` and `pause_menu.gd`, add exact node references for `MasterVolumeRow`, `MusicVolumeRow`, and `SFXVolumeRow`, refresh each with `set_value_no_signal`, and handlers:

```gdscript
func _on_master_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_update_readout(_master_readout, value)

func _on_music_volume_changed(value: float) -> void:
	Settings.set_music_volume(value)
	_update_readout(_music_readout, value)

func _on_sfx_volume_changed(value: float) -> void:
	Settings.set_sfx_volume(value)
	_update_readout(_sfx_readout, value)
```

Connect each TSCN slider to its matching handler. Reset sets all three to `1.0`.

- [ ] **Step 5: Run tests and commit**

```bash
sh tests/run_audio_settings_tests.sh
sh tests/run_audio_manager_tests.sh
git add scenes/ui/settings.gd scenes/ui/pause_menu.gd scenes/homepage/settings_page.tscn scenes/ui/pause_menu.tscn tests
git commit -m "feat: persist independent music and SFX volume"
```

---

### Task 4: Keep Chapter 1–9 music continuous and auto-sound all buttons

**Files:**
- Modify: `scenes/core/audio_manager.gd`
- Modify: `tests/test_audio_manager_runtime.gd`

- [ ] **Step 1: Extend the failing test**

Add assertions using public `sync_music_for_scene_path(path)`:

```gdscript
audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6.tscn")
var music := audio.get_node("Music") as AudioStreamPlayer
_expect(music.playing, "chapter starts music")
var playback_position := music.get_playback_position()
audio.sync_music_for_scene_path("res://scenes/chapter_6/chapter_6_room_left.tscn")
_expect(music.playing, "subroom keeps music")
_expect(music.get_playback_position() >= playback_position, "music was not restarted")
audio.sync_music_for_scene_path("res://scenes/homepage/home_page.tscn")
_expect(not music.playing, "non-chapter stops chapter music")
```

Also create a `Button`, add it under root, emit `pressed`, and assert `sfx_played` receives `button_click` exactly once even after calling registration twice.

- [ ] **Step 2: Run test and verify failure**

Run: `sh tests/run_audio_manager_tests.sh`

- [ ] **Step 3: Implement scene-aware music**

```gdscript
func sync_music_for_scene_path(scene_path: String) -> void:
	var should_play := (
		scene_path.begins_with("res://scenes/chapter_")
		or scene_path.begins_with("res://scenes/cutscene/chapter_")
	)
	var music := get_node("Music") as AudioStreamPlayer
	if should_play:
		if not music.playing and _streams.has(BACKGROUND):
			music.stream = _streams[BACKGROUND]
			music.play()
	else:
		music.stop()

func _sync_music_for_current_scene() -> void:
	var scene := get_tree().current_scene
	sync_music_for_scene_path(scene.scene_file_path if scene != null else "")
```

- [ ] **Step 4: Implement idempotent button registration**

```gdscript
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_button(node)

func _register_button(button: BaseButton) -> void:
	if button.has_meta("audio_click_connected"):
		return
	button.set_meta("audio_click_connected", true)
	button.pressed.connect(play_sfx.bind(BUTTON_CLICK))
```

Register existing buttons recursively during `_ready()` as well as future buttons from `node_added`.

- [ ] **Step 5: Run tests and commit**

```bash
sh tests/run_audio_manager_tests.sh
git add scenes/core/audio_manager.gd tests/test_audio_manager_runtime.gd
git commit -m "feat: keep chapter music continuous and sound UI buttons"
```

---

### Task 5: Add Rama and Hanuman movement, attack, and hurt sounds

**Files:**
- Modify: `scenes/player/player.gd`
- Modify: `scenes/player/hanuman_player.gd`
- Create: `tests/test_player_audio_hooks.gd`
- Create: `tests/run_player_audio_tests.sh`

- [ ] **Step 1: Write failing integration tests**

Instantiate each player scene, connect `AudioManager.sfx_played`, then directly exercise safe hooks:

```gdscript
rama._shoot()
_expect(events.has(AudioManager.SWORD_ATTACK), "Rama uses sword attack sound")
rama.take_damage(1)
_expect(events.has(AudioManager.HURT), "Rama hurt sound")
hanuman._attack()
_expect(events.has(AudioManager.THRASH), "Hanuman uses thrash sound")
hanuman.take_damage(1)
_expect(events.count(AudioManager.HURT) == 2, "Hanuman hurt sound")
```

For movement, set `AudioManager.set_run_active(player, true/false)` through a new player helper `_update_run_audio(active)` and assert the dedicated loop starts/stops. Await/cancel attack coroutines safely by freeing the instantiated test node after the immediate sound assertion.

- [ ] **Step 2: Verify test fails**

Run: `sh tests/run_player_audio_tests.sh`

- [ ] **Step 3: Wire Rama**

- At the start of `_shoot()`: stop run, then `AudioManager.play_sfx(AudioManager.SWORD_ATTACK)`.
- After calculating movement state: `AudioManager.set_run_active(self, is_moving)`.
- Before every early return for dialogue, shooting, knockback, and death: deactivate run.
- In `take_damage`, after dash/dead guards: stop run and play `HURT` once.
- In `_exit_tree()`: `AudioManager.set_run_active(self, false)`.

- [ ] **Step 4: Wire Hanuman**

Apply the same run/hurt lifecycle, but `_attack()` plays `AudioManager.THRASH`.

- [ ] **Step 5: Test and commit**

```bash
sh tests/run_player_audio_tests.sh
git add scenes/player/player.gd scenes/player/hanuman_player.gd tests
git commit -m "feat: add Rama and Hanuman action sounds"
```

---

### Task 6: Add generic enemy attack/hit sounds without boss stacking

**Files:**
- Modify: `scenes/props/mob.gd`
- Modify: `scenes/props/thosakan.gd`
- Modify: `scenes/props/miyarap.gd`
- Create: `tests/test_enemy_audio_hooks.gd`
- Create: `tests/run_enemy_audio_tests.sh`

- [ ] **Step 1: Write the failing test around overridable attack keys**

Assert generic mob returns `ENEMY_ATTACKING`, Thosakan returns `GIANT_ATTACK`, and all damage paths emit `ENEMY_HIT` once.

- [ ] **Step 2: Add an overridable key in `mob.gd`**

```gdscript
func _attack_sound_key() -> StringName:
	return AudioManager.ENEMY_ATTACKING

func _start_attack() -> void:
	AudioManager.play_sfx(_attack_sound_key())
	# existing attack flow follows unchanged
```

At the start of `apply_authorized_damage`, after the defeated guard, call `AudioManager.play_sfx(AudioManager.ENEMY_HIT)`. Do not put the sound in `take_damage`, because gated damage later calls `apply_authorized_damage` and would double-play.

- [ ] **Step 3: Override Thosakan and cover standalone boss damage**

```gdscript
func _attack_sound_key() -> StringName:
	return AudioManager.GIANT_ATTACK
```

Because Thosakan overrides `take_damage`, play `ENEMY_HIT` after its amount/health guard. This makes normal Thosakan attack use only `giant_attack.mp3`, never generic `Enemy_attacking.mp3`.

- [ ] **Step 4: Cover Miyarap standalone damage**

Play `ENEMY_HIT` after the stunned guard and before health changes. Miyarap slam sound is implemented separately in Task 7.

- [ ] **Step 5: Test and commit**

```bash
sh tests/run_enemy_audio_tests.sh
git add scenes/props/mob.gd scenes/props/thosakan.gd scenes/props/miyarap.gd tests
git commit -m "feat: add enemy attack and hit sounds"
```

---

### Task 7: Synchronize Miyarap and Thosakan boss cues to animation events

**Files:**
- Modify: `scenes/props/miyarap.gd`
- Modify: `scenes/props/thosakan.gd`
- Modify: `tests/test_enemy_audio_hooks.gd`

- [ ] **Step 1: Add failing boss-cue assertions**

Test helper functions independently:

```gdscript
_expect(thosakan._sound_key_for_special(&"Jump attack") == AudioManager.JUMP_THROW,
	"jump maps to jump_throw")
_expect(thosakan._sound_key_for_special(&"Skill") == AudioManager.HEAL_AND_PULL,
	"heal maps to heal_and_pull")
_expect(thosakan._is_footstep_frame(&"run", 1), "first contact frame")
_expect(thosakan._is_footstep_frame(&"run", 3), "second contact frame")
```

- [ ] **Step 2: Synchronize Miyarap slam and wave**

In `_start_attack()`, after reaching `ATTACK_HIT_FRAME` and before damage:

```gdscript
AudioManager.play_sfx(AudioManager.GIANT)
```

After spawning both waves, call exactly once:

```gdscript
_spawn_wave(Vector2.LEFT)
_spawn_wave(Vector2.RIGHT)
AudioManager.play_sfx(AudioManager.WAVE)
```

- [ ] **Step 3: Synchronize Thosakan special skills**

- `_begin_jump_attack()` plays `JUMP_THROW` once at start.
- `_begin_heal_skill()` plays `HEAL_AND_PULL` once at start.
- `_begin_pull_attack()` plays `HEAL_AND_PULL` once at start.
- Normal attack remains `GIANT_ATTACK` through Task 6 override.

- [ ] **Step 4: Synchronize Thosakan footsteps**

Use the existing `frame_changed` connection and the verified five-frame `run` animation:

```gdscript
const RUN_ANIMATION := &"run"
const FOOTSTEP_FRAMES := [1, 3]

func _is_footstep_frame(animation: StringName, frame: int) -> bool:
	return animation == RUN_ANIMATION and frame in FOOTSTEP_FRAMES

func _on_sprite_frame_changed() -> void:
	if _is_footstep_frame(_sprite.animation, _sprite.frame) and velocity.length() > 0.0:
		AudioManager.play_sfx(AudioManager.GIANT)
	# preserve existing jump/pull handling below
```

The frame signal fires once per animation contact, so do not add a timer or `_physics_process` playback.

- [ ] **Step 5: Test and commit**

```bash
sh tests/run_enemy_audio_tests.sh
git add scenes/props/miyarap.gd scenes/props/thosakan.gd tests/test_enemy_audio_hooks.gd
git commit -m "feat: synchronize boss sounds with attack animations"
```

---

### Task 8: Add pickup sound to every successful inventory collection

**Files:**
- Modify: `scenes/props/potion_pickup.gd`
- Modify: `scenes/chapter_3/chapter_3.gd`
- Modify: `scenes/chapter_6/chapter_6.gd`
- Modify: `scenes/chapter_6/chapter_6_room_left.gd`
- Modify: `scenes/chapter_6/chapter_6_room_right.gd`
- Create: `tests/test_pickup_audio_hooks.gd`
- Create: `tests/run_pickup_audio_tests.sh`

- [ ] **Step 1: Write failing tests for successful collection only**

The test must verify:

- potion plays once before `queue_free()`;
- Jatayu feather plays only in the `correct` branch after `Inv.add_item()`;
- each Chapter 6 key fragment plays only when its count was zero and `add_item()` ran;
- repeated collection callback does not play again.

- [ ] **Step 2: Add pickup sound directly after each successful `add_item`**

Use this invariant at every site:

```gdscript
inventory.add_item(item_id)
AudioManager.play_sfx(AudioManager.PICKUP)
```

For the potion use `Inv.add_item(item_id)` followed by the same sound. Never play before success guards.

- [ ] **Step 3: Test and commit**

```bash
sh tests/run_pickup_audio_tests.sh
git add scenes/props/potion_pickup.gd scenes/chapter_3/chapter_3.gd scenes/chapter_6/chapter_6.gd scenes/chapter_6/chapter_6_room_left.gd scenes/chapter_6/chapter_6_room_right.gd tests
git commit -m "feat: sound successful item pickups"
```

---

### Task 9: Add correct/wrong feedback to shared and Chapter 6 puzzles

**Files:**
- Modify: `scenes/ui/question_quiz.gd`
- Modify: `scenes/ui/matching_puzzle.gd`
- Modify: `scenes/chapter_6/chapter_6_left_chest_puzzle.gd`
- Modify: `scenes/chapter_6/chapter_6_right_jar_modal.gd`
- Modify: `scenes/chapter_6/chapter_6_right_code_modal.gd`
- Create: `tests/test_puzzle_audio_hooks.gd`
- Create: `tests/run_puzzle_audio_tests.sh`

- [ ] **Step 1: Write failing puzzle tests**

Observe `AudioManager.sfx_played` and assert:

- QuestionQuiz correct/wrong emits the matching key once;
- MatchingPuzzle emits correct for a matched pair and wrong for a mismatch;
- left chest emits wrong before its retry/reset and correct for each correct answer;
- right jar emits wrong before shuffle/retry, correct once, waits one second, then reveals the jar;
- right code emits wrong on invalid complete code and correct once on `273`.

Because button clicks are automatic, assertions must expect `button_click` first and answer feedback second when testing by `pressed.emit()`.

- [ ] **Step 2: Wire the shared quiz**

```gdscript
func _on_choice_pressed(index: int) -> void:
	var is_correct := index == _correct_index
	AudioManager.play_sfx(
		AudioManager.ANSWER_CORRECT if is_correct else AudioManager.ANSWER_WRONG
	)
	get_tree().paused = false
	hide()
	answered.emit(is_correct)
```

- [ ] **Step 3: Wire matching puzzle per attempted pair**

Play `ANSWER_CORRECT` at the start of the match branch and `ANSWER_WRONG` at the start of the mismatch branch.

- [ ] **Step 4: Wire left chest, right jar, and right code**

- Left chest: correct key before advancing; wrong key before `_flash_wrong_answer()`.
- Right jar: wrong key before the one-second red feedback and answer shuffle; correct key before the one-second green feedback, then hide question overlay and reveal the jar normally.
- Right code: after third digit, valid `273` plays correct before green hold; invalid code plays wrong before red blink and clear.

- [ ] **Step 5: Run tests and commit**

```bash
sh tests/run_puzzle_audio_tests.sh
git add scenes/ui/question_quiz.gd scenes/ui/matching_puzzle.gd scenes/chapter_6/chapter_6_left_chest_puzzle.gd scenes/chapter_6/chapter_6_right_jar_modal.gd scenes/chapter_6/chapter_6_right_code_modal.gd tests
git commit -m "feat: add puzzle answer feedback sounds"
```

---

### Task 10: Full verification and manual Chapter 1–9 smoke test

**Files:**
- Modify only if a verified defect is found.

- [ ] **Step 1: Run every automated test**

```bash
for test_script in tests/run_*_tests.sh; do sh "$test_script"; done
```

Expected: all PASS, exit 0.

- [ ] **Step 2: Run project parse/import validation**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit 0, no GDScript parse errors, no missing audio resources.

- [ ] **Step 3: Run the game and smoke-test the matrix**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Verify manually:

1. Enter each Chapter 1–9: background starts and remains continuous through subrooms/cutscenes.
2. Move/stop/attack/hurt/die as Rama and Hanuman: run loop lifecycle is correct and character attacks differ.
3. Fight regular enemy: start attack and hit sounds fire once.
4. Fight Miyarap: slam at impact, then Wave once when both purple waves appear.
5. Fight Thosakan: giant footsteps per contact; normal, jump, heal, pull each use the intended unique sound.
6. Pick potion, feather, and all three key fragments: pickup sound once per actual inventory addition.
7. Exercise shared quizzes, matching puzzle, Chapter 6 chest/jars/code: click then correct/wrong feedback in that order while paused.
8. Change Master/Music/SFX independently in homepage settings and pause menu, restart game, and confirm persistence.

- [ ] **Step 4: Inspect final diff and commit any verification-only fixes**

```bash
git status --short
git diff --check
git diff --stat
```

If verification fixes were necessary:

```bash
git add <verified-files>
git commit -m "fix: polish global audio integration"
```

- [ ] **Step 5: Request code review before integration**

Use `superpowers:requesting-code-review`, address only evidence-backed findings, rerun the full suite, then use `superpowers:finishing-a-development-branch` for the merge decision.
