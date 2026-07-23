# Chapter 2 Post-Abduction and Sida Room Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Return Phra Ram to a walkable Chapter 2 position after the abduction cutscene and place Sida on the carpet before the bed in Chapter 8's first room.

**Architecture:** Keep the existing Chapter 2 story flags and scene-transition flow. Replace the duplicated collision-overlapping return coordinate with one named safe-spawn constant, then instance the existing Sida scene directly under the Chapter 8 room's `YSortRoot`.

**Tech Stack:** Godot 4.7.1, GDScript, Godot `.tscn` resources, POSIX shell contract tests

## Global Constraints

- Do not remove or disable Chapter 2 fence collisions.
- Keep Sida absent from Chapter 2 after `GameState.chapter_2_deer_defeated`.
- Do not add dialogue, quests, interaction prompts, movement behavior, or new GameState flags for Sida.
- Do not modify Chapter 7 opening cutscene files as part of this work.
- Preserve the user's existing uncommitted edits in `scenes/chapter_2/chapter_2.tscn`.

---

## File Structure

- `tests/test_chapter_2_post_abduction.sh`: Contract for safe return spawning and the existing Chapter 2 post-abduction cleanup.
- `scenes/chapter_2/chapter_2_second.gd`: Owns chase completion and return to the Chapter 2 ashram.
- `tests/test_chapter_8_sida_room.sh`: Contract for Sida's presence and placement in the first Chapter 8 room.
- `scenes/chapter_8/chapter_8_room.tscn`: Owns the first Chapter 8 room composition.

### Task 1: Safe Chapter 2 Return Spawn

**Files:**
- Create: `tests/test_chapter_2_post_abduction.sh`
- Modify: `scenes/chapter_2/chapter_2_second.gd:1-150`

**Interfaces:**
- Consumes: `GameState.next_spawn: Vector2` and `get_tree().change_scene_to_file(path: String)`.
- Produces: `const ASHRAM_RETURN_SPAWN := Vector2(1120, 680)` used by both successful and failed chase return paths.

- [ ] **Step 1: Write the failing contract test**

```sh
#!/bin/sh
set -eu

controller="scenes/chapter_2/chapter_2_second.gd"
chapter_scene="scenes/chapter_2/chapter_2.gd"

grep -Fq 'const ASHRAM_RETURN_SPAWN := Vector2(1120, 680)' "$controller"
count="$(grep -Fc 'GameState.next_spawn = ASHRAM_RETURN_SPAWN' "$controller")"
test "$count" -eq 2

if grep -Fq 'GameState.next_spawn = Vector2(1000, 600)' "$controller"; then
	echo "Chapter 2 still uses the collision-overlapping return spawn" >&2
	exit 1
fi

grep -Fq 'if GameState.chapter_2_deer_defeated:' "$chapter_scene"
grep -A4 -F 'if GameState.chapter_2_deer_defeated:' "$chapter_scene" | grep -Fq '_sida.queue_free()'

echo "Chapter 2 post-abduction return contract passed"
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
sh tests/test_chapter_2_post_abduction.sh
```

Expected: FAIL because `ASHRAM_RETURN_SPAWN` does not exist yet.

- [ ] **Step 3: Add and use one safe return coordinate**

Add near the other constants:

```gdscript
const ASHRAM_RETURN_SPAWN := Vector2(1120, 680)
```

Update both return handlers:

```gdscript
func _on_abduction_finished() -> void:
	GameState.next_spawn = ASHRAM_RETURN_SPAWN
	get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_2/chapter_2.tscn")


func _on_fail_finished() -> void:
	GameState.next_spawn = ASHRAM_RETURN_SPAWN
	get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_2/chapter_2.tscn")
```

- [ ] **Step 4: Run the test and verify GREEN**

Run:

```bash
sh tests/test_chapter_2_post_abduction.sh
```

Expected: `Chapter 2 post-abduction return contract passed`.

- [ ] **Step 5: Commit the focused change**

```bash
git add tests/test_chapter_2_post_abduction.sh scenes/chapter_2/chapter_2_second.gd
git commit -m "fix: use safe Chapter 2 return spawn"
```

### Task 2: Place Sida Before the Chapter 8 Bed

**Files:**
- Create: `tests/test_chapter_8_sida_room.sh`
- Modify: `scenes/chapter_8/chapter_8_room.tscn:1-320`

**Interfaces:**
- Consumes: existing packed scene `res://scenes/props/sida.tscn`.
- Produces: a `Sida` instance under `YSortRoot` at `Vector2(724, 365)`.

- [ ] **Step 1: Write the failing room contract test**

```sh
#!/bin/sh
set -eu

scene="scenes/chapter_8/chapter_8_room.tscn"

grep -Fq 'path="res://scenes/props/sida.tscn" id="4_sida"' "$scene"
grep -Fq '[node name="Sida" parent="YSortRoot"' "$scene"
grep -A3 -F '[node name="Sida" parent="YSortRoot"' "$scene" |
	grep -Fq 'position = Vector2(724, 365)'

echo "Chapter 8 Sida room contract passed"
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
sh tests/test_chapter_8_sida_room.sh
```

Expected: FAIL because the room does not reference or instance `sida.tscn`.

- [ ] **Step 3: Add the Sida resource and instance**

Add to the external resources:

```ini
[ext_resource type="PackedScene" uid="uid://cjdl5khb5p7r8" path="res://scenes/props/sida.tscn" id="4_sida"]
```

Add under `YSortRoot`, before the player node:

```ini
[node name="Sida" parent="YSortRoot" instance=ExtResource("4_sida")]
position = Vector2(724, 365)
```

- [ ] **Step 4: Run the focused contract tests**

Run:

```bash
sh tests/test_chapter_2_post_abduction.sh
sh tests/test_chapter_8_sida_room.sh
```

Expected: both contract tests pass.

- [ ] **Step 5: Validate the Godot resources**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: Godot imports and parses the changed scripts/scenes without an error attributable to `chapter_2_second.gd` or `chapter_8_room.tscn`. Existing unrelated missing-resource errors in other chapters must be reported separately rather than treated as regressions from this change.

- [ ] **Step 6: Check whitespace and the focused diff**

Run:

```bash
git diff --check -- scenes/chapter_2/chapter_2_second.gd scenes/chapter_8/chapter_8_room.tscn tests/test_chapter_2_post_abduction.sh tests/test_chapter_8_sida_room.sh
git diff -- scenes/chapter_2/chapter_2_second.gd scenes/chapter_8/chapter_8_room.tscn tests/test_chapter_2_post_abduction.sh tests/test_chapter_8_sida_room.sh
```

Expected: no whitespace errors; only the safe-spawn, Sida instance, and test changes are present.

- [ ] **Step 7: Commit the focused change**

```bash
git add tests/test_chapter_8_sida_room.sh scenes/chapter_8/chapter_8_room.tscn
git commit -m "feat: place Sida in Chapter 8 room"
```
