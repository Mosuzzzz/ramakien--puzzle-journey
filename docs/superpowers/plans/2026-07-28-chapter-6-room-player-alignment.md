# Chapter 6 Room Player Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Phra Ram's room visuals with his physics body, enlarge only his visuals by 1.5 times in both tower rooms, and preserve the user's custom wall layout.

**Architecture:** Override only the instantiated player's `AnimatedSprite2D`, `Shadow`, and `Camera2D` properties inside each room scene. Keep `CharacterBody2D`, `CollisionShape2D`, portal configuration, and every user-authored wall shape/position unchanged. Replace stale navigation assertions tied to the former sparse layout with runtime assertions based on visual/body alignment, the current spawn corridor, and image-bound containment.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` inherited scene overrides, headless Godot runtime tests.

## Global Constraints

- Preserve every current `Walls` child, collision shape, shape size, and position in `chapter_6_room_left.tscn`.
- Do not enlarge or move the player's `CharacterBody2D` or `CollisionShape2D`.
- Enlarge the player sprite and shadow to exactly 1.5 times their base visual sizes in both rooms.
- The displayed feet must remain aligned with the physics body.
- The camera must remain centered on the player body.
- Preserve all room textures, portal target scenes, return spawns, prompts, and interaction sizes.
- Set the left room entry spawn and exit interaction position to `Vector2(627, 880)`.
- Set the right room entry spawn and exit interaction position to `Vector2(627, 930)`.

---

### Task 1: Align and Enlarge the Room Player

**Files:**
- Modify: `tests/test_chapter_6_tower_rooms_playtest_runtime.gd`
- Modify: `scenes/chapter_6/chapter_6.tscn`
- Modify: `scenes/chapter_6/chapter_6_room_left.tscn`
- Modify: `scenes/chapter_6/chapter_6_room_right.tscn`

**Interfaces:**
- Consumes: Base visual values from `scenes/player/player.tscn`: sprite scale `Vector2(0.2353, 0.2353)`, shadow scale `Vector2(0.12828125, 0.044531252)`, and a radius-9 player collision.
- Produces: Both room players with a visual scale ratio of `1.5`, feet aligned near the collision body, a zero-offset camera, and unchanged collision scale.
- Produces: A left entry spawn of `Vector2(627, 880)` and right entry spawn of `Vector2(627, 930)`, each colocated with its room's exit interaction on the walkable side of the custom lower wall.

- [ ] **Step 1: Add failing runtime assertions for alignment and scale**

Add `_verify_room_player_visuals(room)` and call it for both room paths:

```gdscript
func _verify_room_player_visuals(room: Node) -> bool:
	var player := room.get_node("YSortRoot/Player") as CharacterBody2D
	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var shadow := player.get_node("Shadow") as Sprite2D
	var camera := player.get_node("Camera2D") as Camera2D
	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var base_player := load("res://scenes/player/player.tscn").instantiate()
	var base_sprite := base_player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var base_shadow := base_player.get_node("Shadow") as Sprite2D

	var sprite_ratio := sprite.scale.x / base_sprite.scale.x
	var shadow_ratio := shadow.scale.x / base_shadow.scale.x
	var rendered_half_height := sprite.sprite_frames.get_frame_texture(
		sprite.animation, sprite.frame
	).get_height() * sprite.scale.y * 0.5
	var visual_foot_y := sprite.position.y + rendered_half_height

	if not is_equal_approx(sprite_ratio, 1.5):
		_fail("%s player sprite is not 1.5x" % room.scene_file_path)
		return false
	if not is_equal_approx(shadow_ratio, 1.5):
		_fail("%s player shadow is not 1.5x" % room.scene_file_path)
		return false
	if visual_foot_y < -15.0 or visual_foot_y > -5.0:
		_fail("%s player visual is not aligned with its body" % room.scene_file_path)
		return false
	if not camera.position.is_equal_approx(Vector2.ZERO):
		_fail("%s camera is offset from the player body" % room.scene_file_path)
		return false
	if not player.scale.is_equal_approx(Vector2.ONE) or not collision.scale.is_equal_approx(Vector2.ONE):
		_fail("%s player collision was scaled" % room.scene_file_path)
		return false
	base_player.free()
	return true
```

Change the two tower-entry expectations to literal layout-specific spawn points:

```gdscript
LeftTowerRoomPortal expected spawn: Vector2(627, 880)
RightTowerRoomPortal expected spawn: Vector2(627, 930)
```

Replace the old sparse-layout movement checks with behavior that does not assume decorative floor positions remain empty:

```gdscript
var spawn := Vector2(627, 880) if room.scene_file_path == LEFT_ROOM else Vector2(627, 930)
var left_step := await _drive_player(player, spawn, Vector2(-300, 0), 10)
var right_step := await _drive_player(player, spawn, Vector2(300, 0), 10)
if left_step.x > spawn.x - 25.0 or right_step.x < spawn.x + 25.0:
	_fail("%s player cannot move through the spawn corridor" % room.scene_file_path)
	return false

for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
	var boundary_end := await _drive_player(player, spawn, direction * 600.0, 120)
	if (
		boundary_end.x < 0.0 or boundary_end.x > 1254.0
		or boundary_end.y < 0.0 or boundary_end.y > 1254.0
	):
		_fail("%s player escaped the room artwork" % room.scene_file_path)
		return false
```

Production mutations these assertions catch:

- Restoring the erroneous sprite position `Vector2(9, -181)`.
- Scaling the whole player instead of visual children.
- Omitting the 1.5 visual override from either room.
- Restoring the erroneous camera position `Vector2(6, -161)`.
- Removing the outer boundary while retaining the custom decorative walls.

- [ ] **Step 2: Run the focused test to verify RED**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
```

Expected: exit 1 because the left sprite is misaligned and neither room sprite is 1.5 times the base size.

- [ ] **Step 3: Apply minimal room-local visual overrides**

In both room scenes override the instantiated player children with these values:

```text
AnimatedSprite2D:
  position = Vector2(1, -42.3)
  scale = Vector2(0.35295, 0.35295)

Shadow:
  position = Vector2(0, -7)
  scale = Vector2(0.192421875, 0.066796878)

Camera2D:
  position = Vector2(0, 0)
```

Do not modify the `Player` node scale, its `CollisionShape2D`, or any node below either room's `Walls`.

Change scene transition positions without changing portal destinations:

```text
Chapter6/LeftTowerRoomPortal target_spawn = Vector2(627, 880)
Chapter6/RightTowerRoomPortal target_spawn = Vector2(627, 930)
Left room Player position and ExitPortal position = Vector2(627, 880)
Right room Player position and ExitPortal position = Vector2(627, 930)
```

- [ ] **Step 4: Run focused and full verification**

Run:

```bash
bash tests/test_chapter_6_tower_rooms_playtest_runtime.sh
bash tests/test_chapter_6_tower_rooms_runtime.sh
bash tests/test_chapter_6_tower_rooms.sh
```

Expected: all focused checks exit 0.

Run:

```bash
passed_count=0
total_count=0
for test_script in tests/*.sh; do
  total_count=$((total_count + 1))
  bash "$test_script"
  passed_count=$((passed_count + 1))
done
printf '%d/%d passed\n' "$passed_count" "$total_count"
```

Expected: `18/18 passed`.

Run:

```bash
HOME=/private/tmp/codex-godot-chapter-6-alignment /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
git diff --check
```

Expected: Godot exits 0 without parser or missing-resource errors, and `git diff --check` exits 0.

- [ ] **Step 5: Review and commit without absorbing unrelated edits**

Verify the left-room diff still contains every user-authored wall node and that
the task changed only its player child overrides. Stage only:

```bash
git add \
  scenes/chapter_6/chapter_6.tscn \
  scenes/chapter_6/chapter_6_room_left.tscn \
  scenes/chapter_6/chapter_6_room_right.tscn \
  tests/test_chapter_6_tower_rooms_playtest_runtime.gd \
  docs/superpowers/plans/2026-07-28-chapter-6-room-player-alignment.md
git commit -m "fix: align chapter 6 room player visuals"
```
