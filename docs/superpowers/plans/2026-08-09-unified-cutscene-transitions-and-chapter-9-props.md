# Unified Cutscene Transitions and Chapter 9 Props Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one pause-safe one-second fade system for chapter changes and cutscene entry/exit without double fades, and stage all four supplied Chapter 9 props in the Chapter 9 scene.

**Architecture:** A persistent `SceneTransition` autoload owns the black overlay, transition lock, and scene-handoff state. Chapter portals and story scene changes call it instead of changing scenes directly; every cutscene delegates its opening and closing sequence to the same service so a cutscene in a newly loaded chapter can consume the already-black handoff. Four passive `Sprite2D` nodes are grouped under `Chapter9Props` for later editor placement.

**Tech Stack:** Godot 4.7.1, GDScript, `.tscn` scene resources, headless Godot runtime tests, shell test launchers.

## Global Constraints

- Fade from clear to black in exactly 1.0 second and from black to clear in exactly 1.0 second.
- A chapter change followed immediately by an opening cutscene performs one fade-out and one fade-in only.
- Cutscene completion and skip both fade to black before restoring gameplay and fade back into gameplay.
- Room entrance and exit behavior and door audio remain unchanged.
- Existing internal panel-to-panel cutscene fades remain unchanged.
- Transition input is locked until the reveal finishes, and movement loops stop before darkening.
- Existing quest, save, health, spawn, music, and cutscene completion state must remain intact.
- Chapter 9 prop nodes receive no scripts or collision shapes; final placement remains user-controlled.
- Preserve the current uncommitted Chapter 6 right-room interaction fix and its regression tests.

---

### Task 1: Persistent Scene Transition Service

**Files:**
- Create: `scenes/core/scene_transition.gd`
- Modify: `project.godot`
- Create: `tests/test_scene_transition_runtime.gd`
- Create: `tests/run_scene_transition_tests.sh`
- Create: `tests/fixtures/transition_cutscene_destination.gd`
- Create: `tests/fixtures/transition_cutscene_destination.tscn`

**Interfaces:**
- Produces: `SceneTransition.is_busy() -> bool`
- Produces: `SceneTransition.open_cutscene(prepare: Callable) -> void`
- Produces: `SceneTransition.close_cutscene(finalize: Callable) -> void`
- Produces: `SceneTransition.change_chapter(scene_path: String) -> Error`
- Produces: `SceneTransition.fade_duration: float`, default `1.0`, overridden only by tests.
- Produces: `SceneTransition.fade_started(target_alpha: float)` for runtime observability.
- Consumes: `AudioManager.stop_run_loop()` before every transition.

- [ ] **Step 1: Write the failing runtime test**

Create `tests/fixtures/transition_cutscene_destination.gd`:

```gdscript
extends Node


func _ready() -> void:
	SceneTransition.open_cutscene(func():
		get_tree().root.set_meta("transition_handoff_prepared", true)
	)
```

Create a matching `tests/fixtures/transition_cutscene_destination.tscn` with one root `Node` using that script.

Create `tests/test_scene_transition_runtime.gd`. First instantiate `scene_transition.gd`, set `fade_duration = 0.01`, and verify ordinary cutscene entry/exit:

```gdscript
extends SceneTree

const TransitionScript := preload("res://scenes/core/scene_transition.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var transition := TransitionScript.new()
	transition.name = "SceneTransitionUnderTest"
	_expect(is_equal_approx(transition.fade_duration, 1.0), "production fade duration defaults to one second")
	transition.fade_duration = 0.01
	root.add_child(transition)
	await process_frame

	var first_prepare_called := false
	transition.open_cutscene(func(): first_prepare_called = true)
	await process_frame
	_expect(transition.is_busy(), "opening locks overlapping transition input")
	var rejected_finalize_called := false
	transition.close_cutscene(func(): rejected_finalize_called = true)
	_expect(not rejected_finalize_called, "busy transition rejects overlapping close")
	while transition.is_busy():
		await process_frame
	_expect(first_prepare_called, "accepted opening still completes")

	var prepared := false
	await transition.open_cutscene(func(): prepared = true)
	_expect(prepared, "opening prepares cutscene while black")
	_expect(not transition.is_busy(), "opening unlocks after reveal")
	_expect(is_zero_approx(transition.overlay_alpha()), "opening ends clear")

	var finalized := false
	await transition.close_cutscene(func(): finalized = true)
	_expect(finalized, "closing finalizes cutscene while black")
	_expect(not transition.is_busy(), "closing unlocks after reveal")
	_expect(is_zero_approx(transition.overlay_alpha()), "closing ends clear")

	transition.free()

	root.set_meta("transition_handoff_prepared", false)
	SceneTransition.fade_duration = 0.01
	var handoff_fades: Array[float] = []
	SceneTransition.fade_started.connect(func(alpha: float): handoff_fades.append(alpha))
	var error := await SceneTransition.change_chapter(
		"res://tests/fixtures/transition_cutscene_destination.tscn"
	)
	while SceneTransition.is_busy():
		await process_frame
	_expect(error == OK, "chapter handoff loads destination")
	_expect(root.get_meta("transition_handoff_prepared", false), "destination cutscene claims handoff")
	_expect(handoff_fades == [1.0, 0.0], "chapter plus cutscene uses one fade pair")
	SceneTransition.fade_duration = SceneTransition.DEFAULT_FADE_DURATION
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: scene transition runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
```

Create `tests/run_scene_transition_tests.sh` using the existing runner convention:

```sh
#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-scene-transition-test.log \
  --path . --script res://tests/test_scene_transition_runtime.gd
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `sh tests/run_scene_transition_tests.sh`

Expected: FAIL because `res://scenes/core/scene_transition.gd` does not exist.

- [ ] **Step 3: Implement the minimal pause-safe service**

Create `scenes/core/scene_transition.gd` as a `CanvasLayer` with:

```gdscript
extends CanvasLayer

const DEFAULT_FADE_DURATION := 1.0
enum HandoffState { NONE, PENDING, CLAIMED }

signal fade_started(target_alpha: float)

var fade_duration := DEFAULT_FADE_DURATION
var _busy := false
var _handoff_state := HandoffState.NONE
var _shade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5000
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = Color(0, 0, 0, 0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func is_busy() -> bool:
	return _busy


func overlay_alpha() -> float:
	return _shade.color.a if is_instance_valid(_shade) else 0.0


func open_cutscene(prepare: Callable) -> void:
	if _handoff_state == HandoffState.PENDING and _busy:
		_handoff_state = HandoffState.CLAIMED
		prepare.call()
		await _fade_to(0.0)
		_release()
		_handoff_state = HandoffState.NONE
		return
	if _busy:
		return
	_acquire()
	await _fade_to(1.0)
	prepare.call()
	await _fade_to(0.0)
	_release()


func close_cutscene(finalize: Callable) -> void:
	if _busy:
		return
	_acquire()
	await _fade_to(1.0)
	finalize.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_release()


func change_chapter(scene_path: String) -> Error:
	if _busy:
		return ERR_BUSY
	_acquire()
	await _fade_to(1.0)
	_handoff_state = HandoffState.PENDING
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_handoff_state = HandoffState.NONE
		await _fade_to(0.0)
		_release()
		return error
	await get_tree().process_frame
	await get_tree().process_frame
	if _handoff_state == HandoffState.PENDING:
		_handoff_state = HandoffState.NONE
		await _fade_to(0.0)
		_release()
	# CLAIMED means the destination cutscene owns reveal/release. NONE means
	# that fast reveal already completed before this coroutine resumed.
	return OK


func _acquire() -> void:
	_busy = true
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	AudioManager.stop_run_loop()


func _release() -> void:
	_busy = false
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_to(alpha: float) -> void:
	fade_started.emit(alpha)
	var tween := create_tween()
	tween.tween_property(_shade, "color:a", alpha, fade_duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
```

Register it before gameplay UI autoloads in `project.godot`:

```ini
[autoload]

SceneTransition="*res://scenes/core/scene_transition.gd"
ScreenDim="*res://scenes/ui/screen_dim.tscn"
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `sh tests/run_scene_transition_tests.sh`

Expected: `PASS: scene transition runtime` with exit code 0.

- [ ] **Step 5: Commit Task 1**

```bash
git add project.godot scenes/core/scene_transition.gd tests/test_scene_transition_runtime.gd tests/run_scene_transition_tests.sh tests/fixtures/transition_cutscene_destination.gd tests/fixtures/transition_cutscene_destination.tscn
git commit -m "feat: add persistent scene transition service"
```

---

### Task 2: Route Chapter Changes Through the Service

**Files:**
- Modify: `scenes/props/portal.gd`
- Modify: `scenes/prologue/prologue.gd`
- Modify: `scenes/chapter_2/chapter_2_second.gd`
- Test: `tests/test_portal_audio.gd`
- Create: `tests/test_chapter_transition_hooks.gd`
- Create: `tests/run_chapter_transition_tests.sh`

**Interfaces:**
- Consumes: `SceneTransition.is_busy() -> bool`
- Consumes: `SceneTransition.change_chapter(scene_path: String) -> Error`
- Preserves: direct room changes when either scene path is a known room path.
- Produces: `portal.uses_chapter_transition(current_scene_path: String) -> bool` for deterministic testing.

- [ ] **Step 1: Extend tests for chapter-versus-room routing**

Add to `tests/test_portal_audio.gd` after the existing outdoor chapter portal assertion:

```gdscript
	portal.target_scene = "res://scenes/chapter_7/chapter_7.tscn"
	_expect(
		portal.uses_chapter_transition("res://scenes/chapter_6/chapter_6.tscn"),
		"outdoor chapter portal uses screen transition"
	)
	portal.target_scene = "res://scenes/chapter_6/chapter_6_room_left.tscn"
	_expect(
		not portal.uses_chapter_transition("res://scenes/chapter_6/chapter_6.tscn"),
		"room portal keeps direct door flow"
	)
```

Create `tests/test_chapter_transition_hooks.gd` as a source contract test that reads the three scripts and requires these exact calls:

```gdscript
extends SceneTree

const EXPECTED := {
	"res://scenes/props/portal.gd": "SceneTransition.change_chapter(target_scene)",
	"res://scenes/prologue/prologue.gd": "SceneTransition.change_chapter(NEXT_SCENE)",
	"res://scenes/chapter_2/chapter_2_second.gd": "SceneTransition.change_chapter(\"res://scenes/chapter_2/chapter_2.tscn\")",
}


func _initialize() -> void:
	var failures: Array[String] = []
	for path: String in EXPECTED:
		var source := FileAccess.get_file_as_string(path)
		if not source.contains(EXPECTED[path]):
			failures.append("missing transition hook in %s" % path)
	if failures.is_empty():
		print("PASS: chapter transition hooks")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
```

- [ ] **Step 2: Run tests and verify RED**

Run: `sh tests/run_portal_audio_tests.sh`

Expected: FAIL because `uses_chapter_transition()` is missing.

Run: `sh tests/run_chapter_transition_tests.sh`

Expected: FAIL because the three scripts still change scenes directly.

- [ ] **Step 3: Implement chapter routing while preserving save order**

In `portal.gd`, reject activation while the central service is busy, preserve the existing synchronous state/save work, and choose the transition only after those operations:

```gdscript
func _use_portal() -> void:
	if locked:
		locked_interaction.emit(self)
		get_viewport().set_input_as_handled()
		return
	if SceneTransition.is_busy():
		return
	var current_scene := get_tree().current_scene
	var current_scene_path := current_scene.scene_file_path if current_scene != null else ""
	play_transition_sound_for_scene_path(current_scene_path)
	activated.emit(self)
	GameState.next_spawn = target_spawn
	GameState.next_health = _player.current_health
	if Settings.auto_save_enabled:
		SaveGame.save_autosave()
	get_viewport().set_input_as_handled()
	if uses_chapter_transition(current_scene_path):
		await SceneTransition.change_chapter(target_scene)
	else:
		get_tree().change_scene_to_file.call_deferred(target_scene)


func uses_chapter_transition(current_scene_path: String) -> bool:
	return not (_is_room_scene_path(current_scene_path) or _is_room_scene_path(target_scene))
```

Replace story-driven direct changes in `prologue.gd` and both return paths in `chapter_2_second.gd` with awaited `SceneTransition.change_chapter(...)`. Keep all state updates before the await.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `sh tests/run_portal_audio_tests.sh`

Expected: `PASS: portal audio`.

Run: `sh tests/run_chapter_transition_tests.sh`

Expected: `PASS: chapter transition hooks`.

- [ ] **Step 5: Commit Task 2**

```bash
git add scenes/props/portal.gd scenes/prologue/prologue.gd scenes/chapter_2/chapter_2_second.gd tests/test_portal_audio.gd tests/test_chapter_transition_hooks.gd tests/run_chapter_transition_tests.sh
git commit -m "feat: fade chapter scene changes"
```

---

### Task 3: Use the Shared Service for Every Cutscene Entry and Exit

**Files:**
- Modify: `scenes/ui/cutscene_skip.gd`
- Modify: `scenes/cutscene/chapter_2_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_deer_cutscene.gd`
- Modify: `scenes/cutscene/chapter_2_abduction_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_cutscene.gd`
- Modify: `scenes/cutscene/chapter_3_post_battle_cutscene.gd`
- Modify: `scenes/cutscene/chapter_4_cutscene.gd`
- Modify: `scenes/cutscene/chapter_5_post_boss_cutscene.gd`
- Modify: `scenes/cutscene/chapter_6_cutscene.gd`
- Modify: `scenes/cutscene/chapter_8_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_cutscene.gd`
- Modify: `scenes/cutscene/chapter_9_ending_cutscene.gd`
- Create: `tests/test_cutscene_transition_hooks.gd`
- Create: `tests/run_cutscene_transition_tests.sh`
- Test: `tests/test_story_advance_audio.gd`

**Interfaces:**
- Consumes: `SceneTransition.open_cutscene(prepare: Callable) -> void`
- Consumes: `SceneTransition.close_cutscene(finalize: Callable) -> void`
- Preserves: each cutscene's `_transitioning` guard and all internal dialogue/panel fades.
- Preserves: `CutsceneSkip.attach(host, finish_callable) -> Button`, but the button no longer creates a second overlay.

- [ ] **Step 1: Write the failing cutscene source-contract test**

Create `tests/test_cutscene_transition_hooks.gd` with the exact script list above and assert that each source contains both `SceneTransition.open_cutscene` and `SceneTransition.close_cutscene`. Separately assert that `cutscene_skip.gd` does not contain `tween_property(shade, "color:a"`.

Core loop:

```gdscript
for path: String in CUTSCENE_SCRIPTS:
	var source := FileAccess.get_file_as_string(path)
	_expect(source.contains("SceneTransition.open_cutscene"), "%s opens through service" % path)
	_expect(source.contains("SceneTransition.close_cutscene"), "%s closes through service" % path)
var skip_source := FileAccess.get_file_as_string("res://scenes/ui/cutscene_skip.gd")
_expect(
	not skip_source.contains("tween_property(shade, \"color:a\""),
	"skip relies on cutscene close transition instead of a second overlay"
)
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `sh tests/run_cutscene_transition_tests.sh`

Expected: FAIL listing cutscene scripts without shared opening/closing hooks.

- [ ] **Step 3: Replace duplicated opening transitions**

For each cutscene, keep its existing content array and initial hidden state, but replace its local black-overlay tween with:

```gdscript
func _play_intro_transition() -> void:
	_transitioning = true
	var content: Array[CanvasItem] = [
		_cutscene_image,
		_background_dim,
		_title_banner,
		_dialogue_label,
		_prompt_label,
	]
	for item: CanvasItem in content:
		item.hide()
	await SceneTransition.open_cutscene(func():
		for item: CanvasItem in content:
			item.show()
	)
	_transitioning = false
```

For cutscenes whose content arrays differ, retain their existing exact array members and use the same hide/prepare/open sequence. Do not change Chapter 4's `_transition_to_second_cutscene()`, `_transition_to_third_cutscene()`, `_transition_to_fourth_cutscene()`, or `_transition_to_fifth_cutscene()` functions.

- [ ] **Step 4: Route completion through a finalize callback**

Split each current `_finish_cutscene()` into a guarded transition request and a synchronous `_complete_cutscene()` callback:

```gdscript
func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	_transitioning = true
	await SceneTransition.close_cutscene(_complete_cutscene)


func _complete_cutscene() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()
```

The example callback above applies only to the simple emit/free shape. Preserve these exact per-file completion effects inside `_complete_cutscene()`:

| Script | Guard before awaiting | Callback effects while black |
|---|---|---|
| `chapter_2_cutscene.gd` | `_finished` | unpause, emit `finished`, free its cutscene layer or itself |
| `chapter_2_deer_cutscene.gd` | return unless `_active`, then set `_active = false` | hide, unpause, emit `finished` |
| `chapter_2_abduction_cutscene.gd` | return unless `_active`, then set `_active = false` | hide, unpause, emit `finished` |
| `chapter_3_cutscene.gd` | `_finished` | unpause, call `start_feather_quest()` on the current Chapter 3 scene, queue free |
| `chapter_3_post_battle_cutscene.gd` | return unless `_active`, then set `_active = false` | hide, unpause, call `finish_chapter_3_story()` |
| `chapter_4_cutscene.gd` | `_finished` | call `switch_player_to_hanuman()`, unpause, free its cutscene layer or itself |
| `chapter_5_post_boss_cutscene.gd` | `_finished`, also set `_active = false` | call `restore_phra_ram_after_cutscene()`, hide, unpause, emit `finished` |
| `chapter_6_cutscene.gd` | `_finished` | set `GameState.chapter_6_intro_played`, unpause, call `start_key_fragment_quest()`, free its cutscene layer or itself |
| `chapter_8_cutscene.gd` | `_finished` | unpause, free its cutscene layer or itself |
| `chapter_9_cutscene.gd` | `_finished` | unpause, free its cutscene layer or itself |
| `chapter_9_ending_cutscene.gd` | `_finished`, also set `_active = false` | unpause and defer the existing change to `ENDING_SCENE` |

For `chapter_9_ending_cutscene.gd`, the two process-frame waits in `SceneTransition.close_cutscene()` allow the deferred ending-scene load to complete while black before the shared overlay reveals it. For all other cutscenes, the same method reveals gameplay. Set `_transitioning = true` before awaiting in every finish path so dialogue input cannot advance during the closing fade.

- [ ] **Step 5: Remove the skip-specific 0.4-second overlay**

Replace `_skip_with_fade` in `cutscene_skip.gd` with a single guarded callback:

```gdscript
static func _skip_with_fade(b: Button, on_skip: Callable) -> void:
	if b.disabled or SceneTransition.is_busy():
		return
	b.disabled = true
	on_skip.call()
```

The callback reaches the same `_finish_cutscene()` path as normal completion, so it receives the required one-second closing transition exactly once.

- [ ] **Step 6: Run focused transition and story-input tests**

Run: `sh tests/run_cutscene_transition_tests.sh`

Expected: `PASS: cutscene transition hooks`.

Run: `sh tests/run_story_advance_audio_tests.sh`

Expected: `PASS: story advance audio`.

- [ ] **Step 7: Commit Task 3**

```bash
git add scenes/ui/cutscene_skip.gd scenes/cutscene tests/test_cutscene_transition_hooks.gd tests/run_cutscene_transition_tests.sh
git commit -m "feat: unify cutscene entry and exit fades"
```

---

### Task 4: Stage the Four Chapter 9 Props

**Files:**
- Modify: `scenes/chapter_9/chapter_9.tscn`
- Add existing untracked assets: `assets/props/chapter9/image-removebg-preview.png`
- Add existing untracked assets: `assets/props/chapter9/image-removebg-preview (1).png`
- Add existing untracked assets: `assets/props/chapter9/image-removebg-preview (2).png`
- Add existing untracked assets: `assets/props/chapter9/image-removebg-preview (3).png`
- Add their four Godot `.import` metadata files.
- Create: `tests/test_chapter_9_props.gd`
- Create: `tests/run_chapter_9_props_tests.sh`

**Interfaces:**
- Produces: `Chapter9/Chapter9Props` as a plain `Node2D` staging group.
- Produces: four passive `Sprite2D` children named `PropFireColumn`, `PropStonePile`, `PropTreeStatue`, and `PropFireShrine` after visually matching each texture.
- No scripts, collision shapes, or gameplay state are added.

- [ ] **Step 1: Inspect the four textures and map descriptive names**

Open each PNG and record which file corresponds to the four names. Use the actual visual content rather than filename order. Do not modify the PNGs.

- [ ] **Step 2: Write the failing Chapter 9 scene test**

Create `tests/test_chapter_9_props.gd` that reads `chapter_9.tscn` and asserts:

```gdscript
const TEXTURES := [
	"res://assets/props/chapter9/image-removebg-preview.png",
	"res://assets/props/chapter9/image-removebg-preview (1).png",
	"res://assets/props/chapter9/image-removebg-preview (2).png",
	"res://assets/props/chapter9/image-removebg-preview (3).png",
]

for texture_path: String in TEXTURES:
	_expect(scene_source.contains(texture_path), "Chapter 9 references %s" % texture_path)
_expect(scene_source.contains("[node name=\"Chapter9Props\" type=\"Node2D\" parent=\".\"]"), "props have a staging group")
for node_name: String in ["PropFireColumn", "PropStonePile", "PropTreeStatue", "PropFireShrine"]:
	_expect(scene_source.contains("[node name=\"%s\" type=\"Sprite2D\" parent=\"Chapter9Props\"]" % node_name), "%s is editable" % node_name)
```

- [ ] **Step 3: Run the focused test and verify RED**

Run: `sh tests/run_chapter_9_props_tests.sh`

Expected: FAIL because Chapter 9 does not reference the four textures or staging nodes.

- [ ] **Step 4: Add the four Sprite2D nodes**

Add four texture `ext_resource` entries and this staging structure after the background and before collision walls:

```ini
[node name="Chapter9Props" type="Node2D" parent="."]

[node name="PropFireColumn" type="Sprite2D" parent="Chapter9Props"]
position = Vector2(500, 500)
texture = ExtResource("chapter9_prop_fire_column")

[node name="PropStonePile" type="Sprite2D" parent="Chapter9Props"]
position = Vector2(700, 500)
texture = ExtResource("chapter9_prop_stone_pile")

[node name="PropTreeStatue" type="Sprite2D" parent="Chapter9Props"]
position = Vector2(500, 700)
texture = ExtResource("chapter9_prop_tree_statue")

[node name="PropFireShrine" type="Sprite2D" parent="Chapter9Props"]
position = Vector2(700, 700)
texture = ExtResource("chapter9_prop_fire_shrine")
```

Use the mapping established in Step 1. Keep scale at `Vector2(1, 1)` unless a texture is larger than the Chapter 9 map viewport; in that case use one uniform staging scale shared by all four and document it in the commit.

- [ ] **Step 5: Run the focused test and verify GREEN**

Run: `sh tests/run_chapter_9_props_tests.sh`

Expected: `PASS: Chapter 9 props`.

- [ ] **Step 6: Commit Task 4**

```bash
git add assets/props/chapter9 scenes/chapter_9/chapter_9.tscn tests/test_chapter_9_props.gd tests/run_chapter_9_props_tests.sh
git commit -m "feat: stage Chapter 9 props"
```

---

### Task 5: Preserve the Chapter 6 Fix and Run Complete Verification

**Files:**
- Preserve and commit: `scenes/chapter_6/chapter_6_room_right.tscn`
- Preserve and commit: `tests/test_chapter_6_right_room_interactions.gd`
- Preserve and commit: `tests/test_chapter_6_right_room_interactions.gd.uid`
- Preserve and commit: `tests/run_chapter_6_right_room_interaction_tests.sh`
- Verify: all `tests/run_*_tests.sh`

**Interfaces:**
- Preserves: visible `JarInteractions` and `PedestalInteraction` parent nodes.
- Preserves: hidden prompts and hidden right-room puzzle modals until interaction.

- [ ] **Step 1: Re-run the Chapter 6 focused regression**

Run: `sh tests/run_chapter_6_right_room_interaction_tests.sh`

Expected: `PASS: Chapter 6 right-room interaction visibility`.

- [ ] **Step 2: Commit the already-verified Chapter 6 fix separately**

```bash
git add scenes/chapter_6/chapter_6_room_right.tscn tests/test_chapter_6_right_room_interactions.gd tests/test_chapter_6_right_room_interactions.gd.uid tests/run_chapter_6_right_room_interaction_tests.sh
git commit -m "fix: restore Chapter 6 right-room prompts"
```

- [ ] **Step 3: Run the complete Godot test suite**

Run:

```sh
for test_script in tests/run_*_tests.sh
do
  sh "$test_script" || exit 1
done
```

Expected: every runner prints `PASS` and the loop exits 0. Existing macOS CA-certificate and ObjectDB cleanup diagnostics may remain, but no test may fail or report a new parse/runtime error.

- [ ] **Step 4: Validate repository formatting and scope**

Run: `git diff --check HEAD~4..HEAD`

Expected: no whitespace errors.

Run: `git status --short`

Expected: no uncommitted files from this implementation. Any unrelated pre-existing user file must remain untouched and be reported explicitly.

- [ ] **Step 5: Review gameplay acceptance paths manually**

Verify these paths in Godot:

1. Enter a same-chapter cutscene: one-second fade out, one-second reveal.
2. Finish and skip a cutscene: one-second fade out, one-second reveal into gameplay.
3. Move from one chapter to another with no new cutscene: one fade pair.
4. Move to Chapter 3, 4, 6, 8, or 9 when its intro cutscene has not played: one fade pair directly into the cutscene.
5. Enter and leave Chapter 1, 6, and 8 room scenes: existing door behavior remains without the new chapter fade.
6. Open Chapter 9 in the editor: all four prop nodes are selectable under `Chapter9Props`.

No additional commit is required after a clean verification run.
