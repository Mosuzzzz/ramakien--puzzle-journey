# Visible Potion Drop Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every enemy potion drop render above default-z foreground artwork so the drop remains visible on the Chapter 5 bridge.

**Architecture:** Keep the existing drop spawn, world position, animation, collision, inventory, and sound flows unchanged. Encode the rendering rule once on the reusable `PotionPickup` root node with a positive `z_index`, and protect it with a focused scene-runtime regression test.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene resources, headless `SceneTree` tests.

## Global Constraints

- Potion drops must remain at the defeated enemy's position and retain current collection behavior.
- `RockChapter5` ordering must not change because it provides intended foreground depth.
- The visibility rule must apply to potion drops in every chapter.
- Do not stage or modify unrelated user changes already present in the working tree.

---

## File Structure

- `scenes/props/potion_pickup.tscn` — owns the shared visual layer and existing pickup composition.
- `tests/test_potion_pickup_rendering.gd` — loads the real packed scene and verifies its root renders above the default world layer while retaining the expected collision configuration.
- `tests/run_potion_pickup_rendering_tests.sh` — runs the focused regression test with the project's Godot binary.

### Task 1: Protect Potion Drops From Foreground Occlusion

**Files:**
- Create: `tests/test_potion_pickup_rendering.gd`
- Create: `tests/run_potion_pickup_rendering_tests.sh`
- Modify: `scenes/props/potion_pickup.tscn:9-12`

**Interfaces:**
- Consumes: `res://scenes/props/potion_pickup.tscn` as a `PackedScene`.
- Produces: a `PotionPickup` root `Area2D` whose `z_index` is greater than the default world layer (`0`).

- [ ] **Step 1: Write the failing scene-runtime test**

Create `tests/test_potion_pickup_rendering.gd`:

```gdscript
extends SceneTree

const POTION_PICKUP := preload("res://scenes/props/potion_pickup.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var pickup := POTION_PICKUP.instantiate()
	root.add_child(pickup)
	_expect(pickup.z_index > 0, "potion pickup renders above default-z foreground art")
	_expect(pickup.collision_layer == 0, "rendering fix does not turn the pickup into a blocking body")
	_expect(pickup.collision_mask == 2, "rendering fix preserves player detection")
	pickup.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: potion pickup rendering")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

Create `tests/run_potion_pickup_rendering_tests.sh`:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-potion-pickup-rendering-test.log \
  --path . --script res://tests/test_potion_pickup_rendering.gd
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
sh tests/run_potion_pickup_rendering_tests.sh
```

Expected: exit code `1` with `potion pickup renders above default-z foreground art`, because the current root inherits `z_index = 0`.

- [ ] **Step 3: Apply the minimum rendering fix**

In `scenes/props/potion_pickup.tscn`, set the property on the root node only:

```ini
[node name="PotionPickup" type="Area2D"]
z_index = 1
collision_layer = 0
collision_mask = 2
script = ExtResource("1_script")
```

Do not reorder Chapter 5 nodes or change the pickup script.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run:

```bash
sh tests/run_potion_pickup_rendering_tests.sh
```

Expected: exit code `0` and `PASS: potion pickup rendering`.

- [ ] **Step 5: Run related pickup regression coverage**

Run:

```bash
sh tests/run_pickup_audio_tests.sh
```

Expected: exit code `0` and `PASS: pickup audio hooks`, proving the inventory pickup path remains intact.

- [ ] **Step 6: Parse and smoke-test the project**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-visible-potion-parse.log \
  --editor --path . --quit

/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-visible-potion-smoke.log \
  --path . --quit-after 120
```

Expected: both commands exit `0`; logs contain no script parse errors or invalid-resource errors.

- [ ] **Step 7: Review scope and commit only task files**

Run:

```bash
git diff --check
git diff -- scenes/props/potion_pickup.tscn tests/test_potion_pickup_rendering.gd tests/run_potion_pickup_rendering_tests.sh
git status --short
git add scenes/props/potion_pickup.tscn tests/test_potion_pickup_rendering.gd tests/run_potion_pickup_rendering_tests.sh
git commit -m "fix: keep potion drops above foreground"
```

Expected: the diff contains only the reusable pickup layer change and its focused test files; unrelated deleted assets and `scenes/chapter_1/chapter_1.tscn` remain unstaged.
