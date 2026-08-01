# Chapter Quest Notifications and Music Loop Fade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reliable quest flows to Chapters 5, 7, 8, and 9, show a bobbing unread marker whenever quest content changes, and fade music in at the start of every playback cycle.

**Architecture:** Keep `QuestLog` as the single HUD owner and make chapter controllers publish story changes from explicit defeat and locked-door signals. Persist only the two new story decisions needed to reconstruct Chapter 7 and Chapter 8 state. Replace built-in MP3 music looping with an `AudioManager`-owned finished/restart cycle so every loop boundary can reuse the existing fade machinery without affecting run audio.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene resources, headless Godot runtime tests, POSIX shell test runners.

## Global Constraints

- Chapter 6 quest behavior remains functionally unchanged.
- Use `res://assets/ui/icon/split/icon_flame.png` for the unread quest marker.
- The unread marker disappears when `QuestButton` is pressed and is not saved.
- Chapter 7 completes its first quest after all three authored defenders are defeated.
- Chapter 8 changes quest only after a valid locked interaction with `RoomEntranceLeftUpper`.
- Chapter 9 changes from `ปราบทศกัณฐ์` to `กลับไปช่วยนางสีดา` when Thotsakan is defeated.
- Music fades from silence at initial start, track changes, and every natural loop restart; it does not fade out at a natural loop end.
- Existing gains, boss transitions, run audio, combat balance, portal positions, and portal locks remain unchanged.

---

## File Structure

- `scenes/ui/quest_log.gd` and `quest_log.tscn`: unread comparison, acknowledgement, texture, and bob animation.
- `scenes/core/game_state.gd` and `save_game.gd`: the two new cross-scene story flags.
- `scenes/props/portal.gd`: typed locked-activation signal.
- `scenes/chapter_5/chapter_5.gd`: Miyarap and Lanka-travel quests.
- `scenes/chapter_7/chapter_7.gd` and `chapter_7.tscn`: three-defender controller and infiltration quest.
- `scenes/chapter_8/chapter_8.gd` and `chapter_8_room.gd`: discovery, boss, rescue, and completion states.
- `scenes/chapter_9/chapter_9.gd`: Thotsakan and rescue states.
- `scenes/core/audio_manager.gd`: manual music loop lifecycle.
- `tests/test_quest_notifications_runtime.gd`: unread-marker behavior.
- `tests/test_chapter_quest_state_runtime.gd`: state and locked portal behavior.
- `tests/test_chapter_quest_flows_runtime.gd`: late-chapter quest transitions.
- `tests/test_audio_manager_runtime.gd`: music-loop fade regression coverage.

---

### Task 1: Shared Unread Quest Notification

**Files:**
- Create: `tests/test_quest_notifications_runtime.gd`
- Create: `tests/run_quest_notification_tests.sh`
- Modify: `scenes/ui/quest_log.gd`
- Modify: `scenes/ui/quest_log.tscn`

**Interfaces:**
- Consumes: existing `Quest.set_quest()`, `set_completed()`, `set_hud_visible()`, and `QuestButton.pressed`.
- Produces: `QuestNotification: TextureRect`, `has_unread_notification() -> bool`, and `_set_notification_unread(unread: bool) -> void`.

- [ ] **Step 1: Write the failing notification test**

Create a fresh `quest_log.tscn` instance and assert this exact sequence:

```gdscript
var quest := (load("res://scenes/ui/quest_log.tscn") as PackedScene).instantiate()
root.add_child(quest)
await process_frame
var button := quest.get_node("QuestButton") as TextureButton
var notice := quest.get_node_or_null("QuestNotification") as TextureRect
_expect(notice != null, "quest notification exists")
_expect(not notice.visible, "notification starts hidden")
quest.set_quest("เควสแรก", "รายละเอียดแรก")
_expect(quest.has_unread_notification() and notice.visible, "new quest notifies")
var start_y := notice.position.y
await create_timer(0.55).timeout
_expect(not is_equal_approx(notice.position.y, start_y), "notification bobs")
button.pressed.emit()
_expect(not quest.has_unread_notification() and not notice.visible, "press acknowledges")
quest.set_quest("เควสแรก", "รายละเอียดแรก")
_expect(not quest.has_unread_notification(), "identical refresh stays read")
quest.set_quest("เควสแรก", "รายละเอียดใหม่")
_expect(quest.has_unread_notification(), "detail change notifies")
button.pressed.emit()
quest.set_completed(true)
_expect(quest.has_unread_notification(), "completion change notifies")
button.pressed.emit()
quest.set_completed(true)
_expect(not quest.has_unread_notification(), "same completion stays read")
quest.set_quest("เควสซ่อน HUD", "ยังไม่ได้อ่าน")
quest.set_hud_visible(false)
_expect(not notice.visible and quest.has_unread_notification(), "hidden HUD preserves unread")
quest.set_hud_visible(true)
_expect(notice.visible, "restored HUD restores notification")
quest.clear()
_expect(not quest.has_unread_notification(), "clear removes unread")
```

Complete the file with `extends SceneTree`, `_failures: Array[String]`, a
deferred `_run()`, and these exact helpers:

```gdscript
func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("PASS: quest notifications runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

Create `tests/run_quest_notification_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-quest-notification-test.log \
  --path . --script res://tests/test_quest_notifications_runtime.gd
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/run_quest_notification_tests.sh`

Expected: FAIL because the node and unread API do not exist.

- [ ] **Step 3: Add the marker scene node**

Add an ext resource for `icon_flame.png`, then add:

```ini
[node name="QuestNotification" type="TextureRect" parent="."]
offset_left = 25.0
offset_top = 166.0
offset_right = 59.0
offset_bottom = 200.0
mouse_filter = 2
texture = ExtResource("11_quest_notification")
expand_mode = 1
stretch_mode = 5
```

- [ ] **Step 4: Implement unread state and bobbing**

Add these boundaries to `quest_log.gd`:

```gdscript
const NOTIFICATION_BOB_DISTANCE := 7.0
const NOTIFICATION_BOB_SECONDS := 0.45
var _notification_unread := false
var _notification_base_y := 0.0
var _notification_tween: Tween
@onready var _notification: TextureRect = $QuestNotification

func has_unread_notification() -> bool:
	return _notification_unread

func _set_notification_unread(unread: bool) -> void:
	_notification_unread = unread
	_notification.visible = _hud_allowed and _has_quest and unread
```

Start one infinite sine ping-pong tween between the authored Y and Y minus
`7.0`. In `set_quest()`, compare the previous active/title/detail/completed
state before assignment and notify only for a real change. Reset completion
internally without calling the public notifying setter. Make
`set_completed()` return early for identical values. Make `clear()` clear
unread state, `set_hud_visible()` refresh visibility without losing unread,
and `_on_quest_button_pressed()` acknowledge before toggling the page.

- [ ] **Step 5: Verify and commit**

Run:

```sh
sh tests/run_quest_notification_tests.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: the focused test passes and the whole project parses without changing
the existing Chapter 6 quest scripts. Then commit:

```sh
git add scenes/ui/quest_log.gd scenes/ui/quest_log.tscn \
  tests/test_quest_notifications_runtime.gd tests/run_quest_notification_tests.sh
git commit -m "feat: notify players of quest updates"
```

---

### Task 2: Persistent Story Flags and Locked Portal Signal

**Files:**
- Create: `tests/test_chapter_quest_state_runtime.gd`
- Create: `tests/run_chapter_quest_state_tests.sh`
- Modify: `scenes/core/game_state.gd`
- Modify: `scenes/core/save_game.gd`
- Modify: `scenes/props/portal.gd`

**Interfaces:**
- Produces: `GameState.chapter_7_defenders_cleared: bool`,
  `GameState.chapter_8_sida_room_discovered: bool`, and
  `Portal.locked_interaction(portal: Area2D)`.

- [ ] **Step 1: Write the failing state/portal test**

Use a headless `SceneTree` test to assert:

```gdscript
var state_dyn = load("res://scenes/core/game_state.gd")
_expect(state_dyn.get("chapter_7_defenders_cleared") == false, "Chapter 7 flag exists")
_expect(state_dyn.get("chapter_8_sida_room_discovered") == false, "Chapter 8 flag exists")
_expect("chapter_7_defenders_cleared" in SaveGame.STATE_KEYS, "Chapter 7 flag saves")
_expect("chapter_8_sida_room_discovered" in SaveGame.STATE_KEYS, "Chapter 8 flag saves")
state_dyn.set("chapter_7_defenders_cleared", true)
state_dyn.set("chapter_8_sida_room_discovered", true)
GameState.reset_progress()
_expect(not state_dyn.get("chapter_7_defenders_cleared"), "Chapter 7 flag resets")
_expect(not state_dyn.get("chapter_8_sida_room_discovered"), "Chapter 8 flag resets")

var portal := (load("res://scenes/props/portal.tscn") as PackedScene).instantiate()
root.add_child(portal)
await process_frame
var events: Array[Area2D] = []
portal.locked_interaction.connect(func(p: Area2D): events.append(p))
portal.locked = true
portal.call("_use_portal")
_expect(events == [portal], "locked use emits once")
```

Create `tests/run_chapter_quest_state_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-quest-state-test.log \
  --path . --script res://tests/test_chapter_quest_state_runtime.gd
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/run_chapter_quest_state_tests.sh`

Expected: FAIL because the properties and signal do not exist.

- [ ] **Step 3: Add persistence and reset behavior**

Add:

```gdscript
static var chapter_7_defenders_cleared := false
static var chapter_8_sida_room_discovered := false
```

Reset both in `GameState.reset_progress()` and add both exact strings to
`SaveGame.STATE_KEYS`.

- [ ] **Step 4: Add the portal boundary**

Add `signal locked_interaction(portal: Area2D)`. Change only the locked branch:

```gdscript
if locked:
	locked_interaction.emit(self)
	get_viewport().set_input_as_handled()
	return
```

The existing input handlers remain the nearby-player guard. Do not emit on
area entry or lock-state changes.

- [ ] **Step 5: Verify and commit**

Run:

```sh
sh tests/run_chapter_quest_state_tests.sh
sh tests/run_portal_audio_tests.sh
git diff --check
```

Expected: PASS, then commit the five files with
`git commit -m "feat: track quest story transitions"`.

---

### Task 3: Chapter 5, 7, 8, and 9 Quest Flows

**Files:**
- Create: `scenes/chapter_7/chapter_7.gd`
- Create: `tests/test_chapter_quest_flows_runtime.gd`
- Create: `tests/run_chapter_quest_flow_tests.sh`
- Modify: `scenes/chapter_5/chapter_5.gd`
- Modify: `scenes/chapter_7/chapter_7.tscn`
- Modify: `scenes/chapter_8/chapter_8.gd`
- Modify: `scenes/chapter_8/chapter_8_room.gd`
- Modify: `scenes/chapter_9/chapter_9.gd`

**Interfaces:**
- Consumes: Task 1 Quest API, Task 2 flags/signal, `Mob.defeated`,
  `Thotsakan.defeated`, cutscene `finished`, and Sida `following_started`.
- Produces: event-driven late-game quest transitions.

- [ ] **Step 1: Write the failing chapter flow test**

Create a source-contract check for the exact Chapter 5/8/9 copy and hooks, plus
a runtime Chapter 7 controller test. The runtime setup uses:

```gdscript
class FakeDefender extends CharacterBody2D:
	signal defeated(mob: CharacterBody2D)

GameState.chapter_7_defenders_cleared = false
Quest.clear()
var chapter := Node2D.new()
chapter.set_script(load("res://scenes/chapter_7/chapter_7.gd"))
var ysort := Node2D.new()
ysort.name = "YSortRoot"
chapter.add_child(ysort)
var defenders: Array[FakeDefender] = []
for index in range(3):
	var defender := FakeDefender.new()
	defender.name = "Mob%d" % (index + 1)
	ysort.add_child(defender)
	defenders.append(defender)
root.add_child(chapter)
await process_frame
_expect(Quest.snapshot().get("name") == "ปราบยักษ์ป้องกันเมือง", "starts defender quest")
defenders[0].defeated.emit(defenders[0])
defenders[1].defeated.emit(defenders[1])
_expect(not GameState.chapter_7_defenders_cleared, "two do not complete")
defenders[2].defeated.emit(defenders[2])
_expect(GameState.chapter_7_defenders_cleared, "three complete")
_expect(Quest.snapshot().get("name") == "ลักลอบเข้าไปในวังทศกัณฐ์",
	"changes to infiltration quest")
```

The source checks require:

- Chapter 5: `ปราบไมยราพ`, `เดินทางไปยังกรุงลงกา`, `Quest.set_quest`.
- Chapter 8 main: all three quest names and `locked_interaction`.
- Chapter 8 Sida room: `กลับไปช่วยนางสีดา` and `Quest.set_completed(true)`.
- Chapter 9: both quest names and `Quest.set_quest`.

Create `tests/run_chapter_quest_flow_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-quest-flow-test.log \
  --path . --script res://tests/test_chapter_quest_flows_runtime.gd
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/run_chapter_quest_flow_tests.sh`

Expected: FAIL because Chapter 7 has no controller and the copy/hooks are absent.

- [ ] **Step 3: Publish Chapter 5 quests**

Add these exact constants:

```gdscript
const QUEST_DEFEAT_NAME := "ปราบไมยราพ"
const QUEST_DEFEAT_DETAIL := "กำจัดไมยราพเพื่อช่วยพระรามและเปิดเส้นทางไปต่อ"
const QUEST_TRAVEL_NAME := "เดินทางไปยังกรุงลงกา"
const QUEST_TRAVEL_DETAIL := "ใช้เส้นทางที่เปิดแล้วเพื่อมุ่งหน้าไปยังกรุงลงกา"
```

Show the defeat quest when Miyarap is active. Show the travel quest in
already-completed/no-boss ready branches. In
`_on_post_boss_cutscene_finished()`, restore music and then publish the travel
quest so its marker appears after the cutscene.

- [ ] **Step 4: Create and attach the Chapter 7 controller**

The controller uses `Mob1`, `Mob2`, and `Mob3`, connects each `defeated`
signal, records instance IDs to ignore duplicates, and changes quest only at
three unique defeats:

```gdscript
func _on_defender_defeated(defender: CharacterBody2D) -> void:
	var defender_id := defender.get_instance_id()
	if _defeated_ids.has(defender_id):
		return
	_defeated_ids[defender_id] = true
	if _defeated_ids.size() < 3:
		return
	GameState.chapter_7_defenders_cleared = true
	Quest.set_quest(
		"ลักลอบเข้าไปในวังทศกัณฐ์",
		"เดินทางต่อและหาทางลักลอบเข้าไปในพระราชวังลงกา"
	)
```

If the cleared flag is already true, remove the three authored defenders and
reconstruct the infiltration quest. Attach the new script only to the Chapter 7
root; do not edit wall or portal properties.

- [ ] **Step 5: Publish Chapter 8 quests**

Use these exact title/detail pairs:

```gdscript
const QUEST_EXPLORE_NAME := "สำรวจพระราชวังเพื่อหานางสีดา"
const QUEST_EXPLORE_DETAIL := "สำรวจห้องต่าง ๆ ภายในพระราชวังและตามหานางสีดา"
const QUEST_BOSS_NAME := "เดินทางไปปราบทศกัณฐ์"
const QUEST_BOSS_DETAIL := "หาทางไปยังท้องพระโรงและปราบทศกัณฐ์เพื่อปลดล็อกห้องนางสีดา"
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"
```

Connect only `RoomEntranceLeftUpper.locked_interaction`:

```gdscript
func _on_sida_room_locked_interaction(_portal: Area2D) -> void:
	if GameState.chapter_8_sida_room_discovered:
		return
	GameState.chapter_8_sida_room_discovered = true
	_show_defeat_thotsakan_quest()
```

Choose ready-time state in this order:

```gdscript
if GameState.chapter_9_sida_rescued:
	_show_rescue_quest()
	Quest.set_completed(true)
elif GameState.chapter_9_thotsakan_defeated:
	_show_rescue_quest()
elif GameState.chapter_8_sida_room_discovered:
	_show_defeat_thotsakan_quest()
else:
	_show_explore_quest()
```

In `chapter_8_room.gd`, reconstruct `กลับไปช่วยนางสีดา` and mark it
completed after setting `chapter_9_sida_rescued = true`.

- [ ] **Step 6: Publish Chapter 9 quests**

Use these exact constants:

```gdscript
const QUEST_BOSS_NAME := "ปราบทศกัณฐ์"
const QUEST_BOSS_DETAIL := "เอาชนะทศกัณฐ์เพื่อปลดล็อกห้องที่คุมขังนางสีดา"
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"
```

Show the boss quest while Thotsakan is alive. After the existing defeat flag
and music restore, publish the rescue quest. On re-entry, reconstruct the rescue
quest and mark it complete only if Sida has already been rescued.

- [ ] **Step 7: Verify and commit**

Run:

```sh
sh tests/run_chapter_quest_flow_tests.sh
sh tests/run_chapter_quest_state_tests.sh
sh tests/run_boss_music_hook_tests.sh
sh tests/run_portal_audio_tests.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: all tests pass and the project parses. Confirm `git diff` contains no
Chapter 6 quest-script changes. Commit the eight implementation/test files with
`git commit -m "feat: add quests to late-game chapters"`.

---

### Task 4: Fade Every Music Playback Cycle

**Files:**
- Modify: `tests/test_audio_manager_runtime.gd`
- Modify: `scenes/core/audio_manager.gd`

**Interfaces:**
- Consumes: existing music request serials, `MUSIC_FADE_SECONDS`,
  `SILENT_MUSIC_DB`, and the single Music player.
- Produces: `_requested_music_gain: float`, `_on_music_finished() -> void`,
  and `_restart_requested_music_cycle() -> void`.

- [ ] **Step 1: Change the audio test to require manual loops**

Replace assertions that background/boss MP3 streams have `loop == true` with
`loop == false`. After an immediate background request establishes playback,
simulate natural completion:

```gdscript
audio.call("_on_music_finished")
_expect(music.playing, "finished music restarts")
_expect(music.volume_db <= audio.SILENT_MUSIC_DB + 0.1,
	"restarted cycle begins silent")
await create_timer(audio.MUSIC_FADE_SECONDS + 0.1).timeout
_expect(is_equal_approx(music.volume_db, linear_to_db(1.0)),
	"restarted menu cycle fades to menu gain")
```

Keep the current seek/same-track assertions to prove scene transitions preserve
the current cycle.

- [ ] **Step 2: Run the test to verify it fails**

Run: `sh tests/run_audio_manager_tests.sh`

Expected: FAIL because music still loops internally and has no restart handler.

- [ ] **Step 3: Implement AudioManager-owned loop starts**

Add `var _requested_music_gain := MENU_MUSIC_GAIN`, connect
`music.finished` to `_on_music_finished`, and set MP3 loop only for `RUN`:

```gdscript
if stream is AudioStreamMP3:
	stream.loop = key == RUN
```

Store every accepted target gain. Restart natural completions with a new request
serial and the existing fade-in helper:

```gdscript
func _on_music_finished() -> void:
	if _requested_music_key.is_empty() or not _streams.has(_requested_music_key):
		return
	_music_request_serial += 1
	var serial := _music_request_serial
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_swap_and_fade_in(
		_requested_music_key,
		_requested_music_gain,
		true,
		MUSIC_FADE_SECONDS,
		serial
	)
```

Use `MUSIC_FADE_SECONDS` for the first background request. Preserve the
same-key/already-playing branch so chapter changes do not restart music. Clear
the requested key before stopping music in unrelated scenes.

- [ ] **Step 4: Verify and commit**

Run:

```sh
sh tests/run_audio_manager_tests.sh
sh tests/run_boss_music_hook_tests.sh
sh tests/run_audio_settings_tests.sh
```

Expected: PASS. Commit with
`git commit -m "feat: fade each music loop from silence"`.

---

### Task 5: Full Verification and Handoff

**Files:**
- Verify only; modify only previously listed files if a focused regression is found.

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: a clean, verified implementation ready to integrate.

- [ ] **Step 1: Run all executable tests**

```sh
for test_runner in tests/run_*_tests.sh; do
  sh "$test_runner"
done
```

Expected: every repository test runner exits zero.

- [ ] **Step 2: Parse the project and inspect the repository**

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
git diff --check
git status --short
```

Expected: no parse errors, no whitespace errors, and no uncommitted
implementation files.

- [ ] **Step 3: Review scope**

```sh
git diff 451de05..HEAD --stat
git diff 451de05..HEAD -- scenes/ui/quest_log.gd scenes/core/audio_manager.gd \
  scenes/chapter_5 scenes/chapter_7 scenes/chapter_8 scenes/chapter_9 \
  scenes/core/game_state.gd scenes/core/save_game.gd scenes/props/portal.gd
```

Expected: only approved quest, notification, state, locked-interaction, and
music-loop changes; no portal positions, collisions, combat balance, or Chapter
6 flow changes.

- [ ] **Step 4: Provide manual playtest checkpoints**

1. Open Chapters 5, 7, 8, and 9 and confirm their specified quests.
2. Confirm the flame marker bobs after each quest change and disappears on scroll press.
3. Defeat all three Chapter 7 defenders and confirm the infiltration quest.
4. Press E at the locked upper-left Chapter 8 room and confirm the boss quest.
5. Defeat Thotsakan, return to Sida, and confirm rescue completion.
6. Let normal and boss music naturally loop and confirm every new cycle fades in.
