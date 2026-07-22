# Chapter 4 Hanuman Player After Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Phra Ram with Hanuman at the same position when the Chapter 4 cutscene finishes or is skipped.

**Architecture:** A focused script on the Chapter 4 root owns player replacement. The existing cutscene finish path asks the current Chapter 4 scene to perform the replacement before unpausing, keeping normal completion and skipping consistent.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene resources, shell structural regression test

## Global Constraints

- Chapter 4 must still start with `res://scenes/player/player.tscn`.
- Both normal completion and skipping must replace the player.
- Hanuman must be named `Player` and preserve the old player's position.
- Do not change shared player scenes, portals, map content, or unrelated user edits.

---

### Task 1: Replace the Chapter 4 player after the cutscene

**Files:**
- Create: `scenes/chapter_4/chapter_4.gd`
- Modify: `scenes/chapter_4/chapter_4.tscn`
- Modify: `scenes/cutscene/chapter_4_cutscene.gd`
- Create: `tests/test_chapter_4_hanuman_after_cutscene.sh`

**Interfaces:**
- Consumes: `YSortRoot/Player`, `res://scenes/player/hanuman_player.tscn`, and the existing `_finish_cutscene() -> void` callback.
- Produces: `switch_player_to_hanuman() -> void` on the Chapter 4 root.

- [ ] **Step 1: Write the failing structural regression test**

```sh
#!/bin/sh
set -eu

scene="scenes/chapter_4/chapter_4.tscn"
controller="scenes/chapter_4/chapter_4.gd"
cutscene="scenes/cutscene/chapter_4_cutscene.gd"

test -f "$controller"
grep -Fq 'script = ExtResource("chapter_4_script")' "$scene"
grep -Fq 'HANUMAN_SCENE.instantiate()' "$controller"
grep -Fq 'hanuman.name = "Player"' "$controller"
grep -Fq 'player_position = old_player.position' "$controller"
grep -Fq 'chapter.call("switch_player_to_hanuman")' "$cutscene"
```

- [ ] **Step 2: Run the test and confirm it fails because the controller is absent**

Run: `sh tests/test_chapter_4_hanuman_after_cutscene.sh`

Expected: exit code `1` at `test -f "$controller"`.

- [ ] **Step 3: Add the idempotent Chapter 4 controller**

```gdscript
extends Node2D

const HANUMAN_SCENE := preload("res://scenes/player/hanuman_player.tscn")

var _hanuman_active := false


func switch_player_to_hanuman() -> void:
	if _hanuman_active:
		return
	_hanuman_active = true

	var old_player := get_node_or_null("YSortRoot/Player") as Node2D
	var player_position := Vector2(691, 863)
	if old_player != null:
		player_position = old_player.position
		old_player.get_parent().remove_child(old_player)
		old_player.queue_free()

	var hanuman := HANUMAN_SCENE.instantiate() as Node2D
	hanuman.name = "Player"
	$YSortRoot.add_child(hanuman)
	hanuman.position = player_position
```

- [ ] **Step 4: Attach the controller without changing the initial Phra Ram instance**

Add this resource and root property to `chapter_4.tscn`:

```tscn
[ext_resource type="Script" path="res://scenes/chapter_4/chapter_4.gd" id="chapter_4_script"]

[node name="Chapter4" type="Node2D"]
script = ExtResource("chapter_4_script")
```

Keep the existing `Player` instance pointing to `ExtResource("2_player")`, which remains `res://scenes/player/player.tscn`.

- [ ] **Step 5: Call the replacement before unpausing**

Update the start of `_finish_cutscene()` after the `_finished` guard:

```gdscript
	_finished = true
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("switch_player_to_hanuman"):
		chapter.call("switch_player_to_hanuman")
	get_tree().paused = false
```

- [ ] **Step 6: Run focused verification**

Run: `sh tests/test_chapter_4_hanuman_after_cutscene.sh`

Expected: exit code `0` and `Chapter 4 Hanuman switch contract passed`.

Run: `git diff --check`

Expected: exit code `0` with no output.

- [ ] **Step 7: Review the diff for scope**

Run: `git diff -- scenes/chapter_4/chapter_4.tscn scenes/chapter_4/chapter_4.gd scenes/cutscene/chapter_4_cutscene.gd tests/test_chapter_4_hanuman_after_cutscene.sh`

Expected: only the controller resource/property, player-switch callback, controller implementation, and focused test are present.
