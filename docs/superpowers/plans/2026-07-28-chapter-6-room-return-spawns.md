# Chapter 6 Room Return Spawns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Return the player from each Chapter 6 tower room to a collision-free main-map point outside the corresponding tower entrance trigger.

**Architecture:** Keep the existing Portal and `GameState.next_spawn` flow unchanged. Update only the two room ExitPortal destination values, then extend the existing end-to-end runtime test to verify the destination, static-body clearance, and absence of immediate tower re-detection.

**Tech Stack:** Godot 4.7.1, GDScript, Godot 2D physics queries, POSIX shell contract tests.

## Global Constraints

- Left room return spawn must be exactly `Vector2(380, 525)`.
- Right room return spawn must be exactly `Vector2(1068, 525)`.
- Keep ExitPortal positions, tower portal positions, tower `Vector2(320, 220)` interaction sizes, destination scenes, prompt text, shared Portal behavior, player collision geometry, and all room collision walls unchanged.
- Preserve all existing uncommitted scene work; do not create a code commit that captures unrelated user edits.

---

### Task 1: Move Both Room Return Destinations to Clear Ground

**Files:**
- Modify: `tests/test_chapter_6_tower_rooms_playtest_runtime.gd`
- Modify: `tests/test_chapter_6_tower_rooms_runtime.gd`
- Modify: `tests/test_chapter_6_tower_rooms.sh`
- Modify: `scenes/chapter_6/chapter_6_room_left.tscn`
- Modify: `scenes/chapter_6/chapter_6_room_right.tscn`

**Interfaces:**
- Consumes: `ExitPortal.target_spawn: Vector2`, `GameState.next_spawn`, `PhysicsDirectSpaceState2D.intersect_shape(...)`, and each tower Portal's `_player` state.
- Produces: Collision-free return points that do not immediately reactivate the tower entrance prompt.

- [ ] **Step 1: Write failing destination assertions**

Change the two ExitPortal expectations in
`tests/test_chapter_6_tower_rooms_playtest_runtime.gd`:

```gdscript
Vector2(380, 525) # left room return
Vector2(1068, 525) # right room return
```

After each return, call an asynchronous helper:

```gdscript
if not await _verify_clear_return_spawn(
	current_scene,
	Vector2(380, 525),
	"YSortRoot/LeftTowerRoomPortal"
):
	return
```

Use the corresponding right-side values after the right room return.

Add the helper:

```gdscript
func _verify_clear_return_spawn(
	chapter: Node,
	expected_spawn: Vector2,
	tower_portal_path: String
) -> bool:
	await physics_frame
	var player := chapter.get_node_or_null("YSortRoot/Player") as CharacterBody2D
	var tower_portal := chapter.get_node_or_null(tower_portal_path) as Area2D
	if player == null or tower_portal == null:
		_fail("Chapter 6 is missing the returned player or tower portal")
		return false

	var player_shape := CircleShape2D.new()
	player_shape.radius = 9.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player_shape
	query.transform = Transform2D(0.0, expected_spawn)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var space: PhysicsDirectSpaceState2D = chapter.get_world_2d().direct_space_state
	var hits: Array[Dictionary] = space.intersect_shape(query, 32)
	if not hits.is_empty():
		_fail("Chapter 6 return spawn overlaps static collision")
		return false
	if tower_portal.get("_player") == player:
		_fail("Chapter 6 return spawn immediately re-enters the tower trigger")
		return false
	return true
```

Add exact-value checks to `tests/test_chapter_6_tower_rooms.sh`:

```sh
grep -Fq 'target_spawn = Vector2(380, 525)' "$LEFT_ROOM"
grep -Fq 'target_spawn = Vector2(1068, 525)' "$RIGHT_ROOM"
```

Update the existing per-room destination expectation in
`tests/test_chapter_6_tower_rooms_runtime.gd`:

```gdscript
var expected_spawn := Vector2(380, 525) if path == LEFT_ROOM else Vector2(1068, 525)
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: both commands exit 1 because the room scenes still contain the old
return destinations.

- [ ] **Step 3: Apply the minimal scene changes**

Change only the ExitPortal destination property in each room:

```text
# chapter_6_room_left.tscn
target_spawn = Vector2(380, 525)

# chapter_6_room_right.tscn
target_spawn = Vector2(1068, 525)
```

- [ ] **Step 4: Run focused verification**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: all three commands exit 0. The runtime test must reach both new
points, report no static collision overlap, and confirm neither tower portal
immediately detects the returned player.

- [ ] **Step 5: Verify scope and the full project**

Record the current SHA-256 hash of the text between each room's `Walls` and
`YSortRoot` nodes before the scene edits. After editing, require the hashes to
be identical. Then run:

```bash
git diff --check
for test_file in tests/*.sh; do bash "$test_file" || exit 1; done
env HOME=/private/tmp/codex-godot-chapter-6-return-spawns /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: unchanged room wall hashes, diff check exit 0, all 18 test scripts
exit 0, and Godot editor parse exit 0.
