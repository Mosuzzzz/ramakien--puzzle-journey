# Chapter 6 Tower Rooms Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add independently loadable left and right tower rooms to Chapter 6, with E/click portals that return the player to the corresponding tower without replaying the chapter intro.

**Architecture:** Reuse `scenes/props/portal.tscn` for all four transitions and keep each interior as a self-contained `.tscn` scene. Store the Chapter 6 intro completion state in the existing static `GameState`, and verify scene resources and portal contracts with both shell and headless Godot runtime tests.

**Tech Stack:** Godot 4, GDScript, Godot `.tscn` scene resources, POSIX shell contract tests.

## Global Constraints

- Left tower artwork: `res://assets/map/chapter_6/ChatGPT Image 27 ก.ค. 2569 20_32_50.png`.
- Right tower artwork: `res://assets/map/chapter_6/ChatGPT Image 27 ก.ค. 2569 20_33_55.png`.
- Both entrance and exit portals must support nearby E input and nearby left-click through the existing `portal.gd`.
- Leaving a room returns the player near the corresponding Chapter 6 tower entrance.
- Returning from a room must not replay the Chapter 6 opening cutscene.
- Do not alter the existing Chapter 5 or Chapter 7 portals.
- Keep the user-provided PNG files and `.import` files intact.

---

### Task 1: Persistent Chapter 6 Intro State

**Files:**
- Modify: `tests/test_chapter_6_tower_rooms.sh`
- Modify: `scenes/core/game_state.gd:28`
- Modify: `scenes/cutscene/chapter_6_cutscene.gd:1-29,92-101`
- Modify: `scenes/homepage/home_page.gd:20-31`

**Interfaces:**
- Consumes: Existing static state pattern in `scenes/core/game_state.gd`.
- Produces: `GameState.chapter_6_intro_played: bool`, read and written by the Chapter 6 cutscene and reset by a new game.

- [ ] **Step 1: Narrow the failing contract to the intro-state behavior**

Add these exact assertions to `tests/test_chapter_6_tower_rooms.sh` before the room assertions:

```sh
grep -Fq 'static var chapter_6_intro_played := false' "$GAME_STATE"
grep -Fq 'const GameState := preload("res://scenes/core/game_state.gd")' "$CUTSCENE"
grep -Fq 'if GameState.chapter_6_intro_played:' "$CUTSCENE"
grep -Fq 'GameState.chapter_6_intro_played = true' "$CUTSCENE"
grep -Fq 'GameState.chapter_6_intro_played = false' "$HOME_PAGE"
```

- [ ] **Step 2: Run the test to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: non-zero exit at `static var chapter_6_intro_played := false`, because the state does not exist yet.

- [ ] **Step 3: Add and reset the state**

Add to `scenes/core/game_state.gd` after the Chapter 2 state:

```gdscript
# whether the Chapter 6 Lanka gate intro cutscene has already played this run
static var chapter_6_intro_played := false
```

Add to `_on_start_pressed()` in `scenes/homepage/home_page.gd`:

```gdscript
GameState.chapter_6_intro_played = false
```

Preload `GameState` in `scenes/cutscene/chapter_6_cutscene.gd`:

```gdscript
const GameState := preload("res://scenes/core/game_state.gd")
```

At the start of `_ready()`, skip the cutscene when returning from a room:

```gdscript
if GameState.chapter_6_intro_played:
	queue_free()
	return
```

In `_finish_cutscene()`, set the state before unpausing:

```gdscript
GameState.chapter_6_intro_played = true
```

- [ ] **Step 4: Run focused state assertions**

Run:

```bash
grep -Fq 'static var chapter_6_intro_played := false' scenes/core/game_state.gd
grep -Fq 'if GameState.chapter_6_intro_played:' scenes/cutscene/chapter_6_cutscene.gd
grep -Fq 'GameState.chapter_6_intro_played = true' scenes/cutscene/chapter_6_cutscene.gd
grep -Fq 'GameState.chapter_6_intro_played = false' scenes/homepage/home_page.gd
```

Expected: all commands exit 0.

- [ ] **Step 5: Commit the intro-state behavior**

```bash
git add tests/test_chapter_6_tower_rooms.sh scenes/core/game_state.gd scenes/cutscene/chapter_6_cutscene.gd scenes/homepage/home_page.gd
git commit -m "fix: prevent chapter 6 intro replay"
```

---

### Task 2: Left and Right Interior Scenes

**Files:**
- Create: `scenes/chapter_6/chapter_6_room_left.tscn`
- Create: `scenes/chapter_6/chapter_6_room_right.tscn`
- Create: `tests/test_chapter_6_tower_rooms_runtime.gd`
- Create: `tests/test_chapter_6_tower_rooms_runtime.sh`
- Test: `tests/test_chapter_6_tower_rooms.sh`

**Interfaces:**
- Consumes: `res://scenes/player/player.tscn`, `res://scenes/props/portal.tscn`, and the two assigned room textures.
- Produces: Two `Node2D` scenes with nodes `Background`, `Walls`, `YSortRoot/Player`, and `YSortRoot/ExitPortal`.

- [ ] **Step 1: Write the runtime test before creating either scene**

Create `tests/test_chapter_6_tower_rooms_runtime.gd`:

```gdscript
extends SceneTree

const LEFT_ROOM := "res://scenes/chapter_6/chapter_6_room_left.tscn"
const RIGHT_ROOM := "res://scenes/chapter_6/chapter_6_room_right.tscn"
const CHAPTER_6 := "res://scenes/chapter_6/chapter_6.tscn"

func _init() -> void:
	for path: String in [LEFT_ROOM, RIGHT_ROOM]:
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("Could not load %s" % path)
			return
		var room := packed.instantiate()
		root.add_child(room)
		var player := room.get_node_or_null("YSortRoot/Player")
		var exit_portal := room.get_node_or_null("YSortRoot/ExitPortal")
		var background := room.get_node_or_null("Background")
		var walls := room.get_node_or_null("Walls")
		if player == null or exit_portal == null or background == null or walls == null:
			_fail("%s is missing required room nodes" % path)
			return
		if String(exit_portal.get("target_scene")) != CHAPTER_6:
			_fail("%s exit does not target Chapter 6" % path)
			return
		if Vector2(exit_portal.get("target_spawn")) == Vector2.ZERO:
			_fail("%s exit has no return spawn" % path)
			return
		room.queue_free()
	print("Chapter 6 tower room runtime passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
```

Create `tests/test_chapter_6_tower_rooms_runtime.sh`:

```sh
#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-rooms}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_tower_rooms_runtime.gd
```

- [ ] **Step 2: Run the runtime test to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected: FAIL with `Could not load res://scenes/chapter_6/chapter_6_room_left.tscn`.

- [ ] **Step 3: Create the left room scene**

Create a Godot scene with:

```text
Chapter6RoomLeft (Node2D)
├── Background (Sprite2D, position 627,627)
├── Walls (StaticBody2D)
│   ├── TopWall (RectangleShape2D)
│   ├── BottomLeftWall (RectangleShape2D)
│   ├── BottomRightWall (RectangleShape2D)
│   ├── LeftWall (RectangleShape2D)
│   ├── RightWall (RectangleShape2D)
│   └── CenterObstacle (CircleShape2D)
└── YSortRoot (Node2D, y_sort_enabled)
    ├── Player (player.tscn, position 627,1040)
    └── ExitPortal (portal.tscn, position 627,1110)
```

Use these collision values:

```text
TopWall: position (627,210), size (780,80)
BottomLeftWall: position (330,1115), size (460,80)
BottomRightWall: position (924,1115), size (460,80)
LeftWall: position (225,660), size (80,900)
RightWall: position (1029,660), size (80,900)
CenterObstacle: position (627,680), radius 105
```

Set the exit portal properties:

```text
target_scene = "res://scenes/chapter_6/chapter_6.tscn"
target_spawn = Vector2(190, 650)
prompt_text = "กด E เพื่อออกจากหอคอย"
interaction_size = Vector2(150, 90)
```

Set the player camera limits to `left = 0`, `top = 0`, `right = 1254`, `bottom = 1254`.

- [ ] **Step 4: Create the right room scene**

Repeat the same focused scene structure and collision values, changing:

```text
Root name: Chapter6RoomRight
Background texture: res://assets/map/chapter_6/ChatGPT Image 27 ก.ค. 2569 20_33_55.png
ExitPortal target_spawn: Vector2(1258, 650)
```

The left scene must use:

```text
Background texture: res://assets/map/chapter_6/ChatGPT Image 27 ก.ค. 2569 20_32_50.png
```

- [ ] **Step 5: Run room contracts and runtime test to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_tower_rooms.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected at this stage: the runtime test passes; the shell contract may still fail only at missing Chapter 6 entrance portals, which Task 3 adds.

- [ ] **Step 6: Commit both interior scenes and runtime test**

```bash
git add assets/map/chapter_6 scenes/chapter_6/chapter_6_room_left.tscn scenes/chapter_6/chapter_6_room_right.tscn tests/test_chapter_6_tower_rooms_runtime.gd tests/test_chapter_6_tower_rooms_runtime.sh
git commit -m "feat: add chapter 6 tower interiors"
```

---

### Task 3: Chapter 6 Tower Entrance Portals

**Files:**
- Modify: `scenes/chapter_6/chapter_6.tscn:550-566`
- Modify: `tests/test_chapter_6_tower_rooms_runtime.gd`
- Test: `tests/test_chapter_6_tower_rooms.sh`

**Interfaces:**
- Consumes: `chapter_6_room_left.tscn`, `chapter_6_room_right.tscn`, and `portal.tscn`.
- Produces: `YSortRoot/LeftTowerRoomPortal` and `YSortRoot/RightTowerRoomPortal`.

- [ ] **Step 1: Extend the runtime test with entrance assertions**

Before testing the rooms in `_init()`, load Chapter 6 and assert:

```gdscript
var chapter_packed := load(CHAPTER_6) as PackedScene
if chapter_packed == null:
	_fail("Could not load Chapter 6")
	return
var chapter := chapter_packed.instantiate()
root.add_child(chapter)
var left_entrance := chapter.get_node_or_null("YSortRoot/LeftTowerRoomPortal")
var right_entrance := chapter.get_node_or_null("YSortRoot/RightTowerRoomPortal")
if left_entrance == null or right_entrance == null:
	_fail("Chapter 6 is missing tower room entrances")
	return
if String(left_entrance.get("target_scene")) != LEFT_ROOM:
	_fail("Left tower targets the wrong room")
	return
if String(right_entrance.get("target_scene")) != RIGHT_ROOM:
	_fail("Right tower targets the wrong room")
	return
chapter.queue_free()
```

- [ ] **Step 2: Run the runtime test to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_runtime.sh
```

Expected: FAIL with `Chapter 6 is missing tower room entrances`.

- [ ] **Step 3: Add both portal instances to Chapter 6**

Under `YSortRoot`, after `Player`, add:

```text
LeftTowerRoomPortal:
  position = Vector2(190, 610)
  target_scene = "res://scenes/chapter_6/chapter_6_room_left.tscn"
  target_spawn = Vector2(627, 1010)
  prompt_text = "กด E เพื่อเข้าไปในหอคอย"
  interaction_size = Vector2(150, 100)

RightTowerRoomPortal:
  position = Vector2(1258, 610)
  target_scene = "res://scenes/chapter_6/chapter_6_room_right.tscn"
  target_spawn = Vector2(627, 1010)
  prompt_text = "กด E เพื่อเข้าไปในหอคอย"
  interaction_size = Vector2(150, 100)
```

Both nodes must be instances of existing `ExtResource("90_portal")`. Do not change `Chapter7Portal` or `Chapter5Portal`.

- [ ] **Step 4: Run all Chapter 6 checks to verify GREEN**

Run:

```bash
bash tests/test_chapter_6_tower_rooms.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
bash tests/test_chapter_6_opening_cutscene.sh
```

Expected: all three commands exit 0 and print their pass messages.

- [ ] **Step 5: Commit the entrance portals**

```bash
git add scenes/chapter_6/chapter_6.tscn tests/test_chapter_6_tower_rooms_runtime.gd
git commit -m "feat: connect chapter 6 tower rooms"
```

---

### Task 4: Full Verification and Visual Playtest

**Files:**
- Verify: all files changed by Tasks 1-3.

**Interfaces:**
- Consumes: Completed Chapter 6 room feature.
- Produces: Fresh evidence that scenes parse, tests pass, and transitions are positioned correctly.

- [ ] **Step 1: Run the Godot project parse check**

Run:

```bash
HOME=/private/tmp/codex-godot-chapter-6-rooms /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit 0 with no parser errors or missing resources for the new room scenes.

- [ ] **Step 2: Run the focused regression suite**

Run:

```bash
for test_script in \
  tests/test_chapter_6_opening_cutscene.sh \
  tests/test_chapter_6_tower_rooms.sh \
  tests/test_chapter_6_tower_rooms_runtime.sh; do
  bash "$test_script"
done
```

Expected: all three pass messages appear and the loop exits 0.

- [ ] **Step 3: Launch Chapter 6 for a visual playtest**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor scenes/chapter_6/chapter_6.tscn
```

Verify manually:

- E and nearby left-click enter the correct room.
- Each image fills the room without exposing space outside the texture.
- The player can move around the visible floor and cannot cross the outer walls.
- The central altar collision does not trap the player.
- Each exit returns to the correct tower.
- The Chapter 6 cutscene does not replay after returning.
- Chapter 5 and Chapter 7 portals remain usable.

- [ ] **Step 4: Inspect the final diff**

Run:

```bash
git diff --check HEAD~3..HEAD
git status --short
```

Expected: no whitespace errors; only intentionally changed or pre-existing untracked files appear.
