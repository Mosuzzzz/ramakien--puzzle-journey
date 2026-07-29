# Chapter 6 Tower Portal Range Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both Chapter 6 tower entrance prompts appear from a comfortable horizontal approach distance.

**Architecture:** Keep the shared Portal implementation unchanged and override only the two Chapter 6 tower instances. Extend the existing runtime playtest so it approaches each tower 140 pixels from the portal center, proving the larger detection rectangle through the real `Area2D` behavior.

**Tech Stack:** Godot 4.7.1, GDScript, Godot headless runtime tests, POSIX shell contract tests.

## Global Constraints

- Set both tower entrance `interaction_size` values to exactly `Vector2(320, 220)`.
- Do not change the shared Portal default or behavior.
- Do not change portal positions, destinations, destination spawns, prompt text, room scenes, or collision walls.
- Preserve all existing uncommitted scene work; do not create a code commit that would capture unrelated user edits.

---

### Task 1: Widen Both Tower Entrance Detection Areas

**Files:**
- Modify: `tests/test_chapter_6_tower_rooms_playtest_runtime.gd`
- Modify: `tests/test_chapter_6_tower_rooms.sh`
- Modify: `scenes/chapter_6/chapter_6.tscn`

**Interfaces:**
- Consumes: `Portal.interaction_size: Vector2`, `Portal._player: Node2D`, and the existing `_activate_portal(...) -> bool` runtime helper.
- Produces: Two tower portal instances with `interaction_size = Vector2(320, 220)` and regression coverage for their configured and effective range.

- [ ] **Step 1: Write the failing runtime and contract assertions**

In `_activate_portal`, use a horizontal approach offset for the two tower
entrances before waiting for `Portal._player`:

```gdscript
var detection_position := portal.global_position
if portal_path.ends_with("LeftTowerRoomPortal"):
	detection_position += Vector2(140, 0)
elif portal_path.ends_with("RightTowerRoomPortal"):
	detection_position += Vector2(-140, 0)
player.global_position = detection_position
```

In `tests/test_chapter_6_tower_rooms.sh`, assert that
`interaction_size = Vector2(320, 220)` occurs exactly twice in the Chapter 6
scene.

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: runtime FAIL because a portal does not detect the player at the
140-pixel offset, and the contract test FAIL because the scene still contains
the old size.

- [ ] **Step 3: Apply the minimal scene change**

Change only these two instance properties in
`scenes/chapter_6/chapter_6.tscn`:

```text
[node name="LeftTowerRoomPortal" ...]
interaction_size = Vector2(320, 220)

[node name="RightTowerRoomPortal" ...]
interaction_size = Vector2(320, 220)
```

- [ ] **Step 4: Run focused verification**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: all three commands exit 0.

- [ ] **Step 5: Verify scope and the full project**

Run:

```bash
git diff --check
for test_file in tests/*.sh; do bash "$test_file" || exit 1; done
env HOME=/private/tmp/codex-godot-chapter-6-portal-range /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: diff check exits 0, all 18 test scripts exit 0, and Godot completes
the editor parse with exit 0. Recompute the saved SHA-256 hashes for the
`Walls` sections of both tower room scenes and require them to remain:

```text
left  5925ba1a10c1c9773b5564062c3649f9083597be3abf24d4ea0e3b8dd5943a74
right 90bfa2495f97b768b3873f0bcb10b30ef0be07d867e0411449e945fa41bf1c14
```
