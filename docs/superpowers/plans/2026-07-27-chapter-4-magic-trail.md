# Chapter 4 Magic Trail Quest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a four-question magic-trail quest after the Chapter 4 opening cutscene and unlock the Chapter 5 portal only when the player reaches `4/4`.

**Architecture:** A focused reusable `MagicTrail` `Area2D` handles proximity, prompt, idle motion, and waypoint movement. `chapter_4.gd` remains the quest coordinator: it owns ordered question data, route state, quest HUD updates, quiz results, and portal lock state.

**Tech Stack:** Godot 4.7, GDScript, existing `QuestionQuiz`, existing `Quest` autoload, headless Godot runtime tests.

## Global Constraints

- Use the supplied texture at `assets/ui/icon/split/ChatGPT_Image_26_ก.ค._2569_22_08_37-removebg-preview.png`.
- Questions are fixed in the approved order and retain the approved answer choices.
- Wrong answers retain the current question and do not advance `0/4` progress.
- Correct answers move toward the Chapter 5 portal; wrong answers move to a reachable detour farther away.
- The Chapter 5 portal unlocks only at `4/4`.
- Do not perform any Git operations.

---

### Task 1: Define the Magic Trail Interaction Contract

**Files:**
- Create: `tests/test_chapter_4_magic_trail_runtime.gd`
- Create: `tests/test_chapter_4_magic_trail_runtime.sh`
- Create: `scenes/props/magic_trail.gd`
- Create: `scenes/props/magic_trail.tscn`

**Interfaces:**
- Produces: `MagicTrail.interaction_requested(trail: Area2D)`
- Produces: `activate_at(new_position: Vector2) -> void`
- Produces: `move_to(new_position: Vector2) -> void`
- Produces: `set_interaction_enabled(enabled: bool) -> void`
- Produces: `is_interaction_enabled() -> bool`

- [ ] **Step 1: Write the failing runtime test**

The test instantiates the trail scene and asserts that `activate_at()` makes it visible and interactive, then asserts that `move_to()` disables interaction while moving and restores interaction at the destination.

- [ ] **Step 2: Run the runtime test to verify RED**

Run:

```bash
bash tests/test_chapter_4_magic_trail_runtime.sh
```

Expected: FAIL because `res://scenes/props/magic_trail.tscn` does not exist.

- [ ] **Step 3: Implement the minimal trail scene and script**

Create an `Area2D` with:

- one scaled `Sprite2D` using the approved texture;
- one `CollisionShape2D` with a generous circular interaction radius;
- one outlined Thai prompt label;
- body-enter/body-exit connections;
- a bob/pulse animation in `_process`;
- a pause-aware tween in `move_to()`.

- [ ] **Step 4: Run the runtime test to verify GREEN**

Run:

```bash
bash tests/test_chapter_4_magic_trail_runtime.sh
```

Expected: PASS.

### Task 2: Add the Chapter 4 Quest State Machine

**Files:**
- Modify: `tests/test_chapter_4_magic_trail_runtime.gd`
- Modify: `scenes/chapter_4/chapter_4.gd`

**Interfaces:**
- Consumes: `MagicTrail` contract from Task 1.
- Consumes: `QuestionQuiz.ask(question: String, choices: Array, correct_index: int)`.
- Produces: `start_magic_trail_quest() -> void`.
- Produces: `_on_magic_trail_interaction_requested(trail: Area2D) -> void`.
- Produces: `_on_magic_trail_answered(correct: bool) -> void`.
- Produces: `get_magic_trail_progress() -> int`.
- Produces: `get_current_magic_trail_question() -> Dictionary`.

- [ ] **Step 1: Extend the test with the fixed question contract**

Assert all four question strings, all three choices for each question, and correct indices `1, 1, 0, 1`.

- [ ] **Step 2: Run the runtime test to verify RED**

Expected: FAIL because Chapter 4 does not expose the quest state or question data.

- [ ] **Step 3: Add the minimal state machine**

Add:

- the approved literal question dictionaries;
- `_magic_trail_progress`;
- `_magic_trail_quest_started`;
- `_magic_trail_quiz_open`;
- ordered forward and detour position arrays read from scene markers;
- answer handling that advances only when correct.

- [ ] **Step 4: Run the runtime test to verify GREEN**

Expected: fixed question and progress tests pass.

### Task 3: Wire Quest HUD, Waypoints, Quiz, and Portal

**Files:**
- Modify: `tests/test_chapter_4_magic_trail_runtime.gd`
- Modify: `scenes/chapter_4/chapter_4.tscn`
- Modify: `scenes/chapter_4/chapter_4.gd`

**Interfaces:**
- Consumes: `Quest.set_quest`, `Quest.set_targets`, and `Quest.set_completed`.
- Consumes: `Portal.set_locked(value: bool)`.
- Produces: a `MagicTrail` node at `YSortRoot/MagicTrail`.
- Produces: a `QuestionQuiz` node at `MagicTrailQuiz`.
- Produces: `MagicTrailWaypoints/Forward1..Final` and `MagicTrailWaypoints/Detour1..Detour4`.

- [ ] **Step 1: Extend the test with player-visible behavior**

Assert:

- the trail is hidden before the opening cutscene finishes;
- the Chapter 5 portal begins locked;
- `start_magic_trail_quest()` shows the trail and sets quest progress to `0/4`;
- a wrong answer leaves progress at zero and moves to a farther detour;
- a correct answer increments progress and moves to the next forward point;
- four correct answers set the quest completed color and unlock the portal.

- [ ] **Step 2: Run the runtime test to verify RED**

Expected: FAIL because the scene does not contain the trail, quiz, waypoint markers, or portal lock configuration.

- [ ] **Step 3: Add scene nodes and integration**

Add the trail, quiz, waypoint markers, and initial portal lock to `chapter_4.tscn`. Connect the trail and quiz signals in `chapter_4.gd`, update the quest marker to follow the active trail, and move the trail with its pause-aware tween.

- [ ] **Step 4: Start the quest at the correct story moment**

Call `start_magic_trail_quest()` only after `switch_player_to_hanuman()` has replaced the player at the end of the opening cutscene.

- [ ] **Step 5: Run the runtime test to verify GREEN**

Expected: all Chapter 4 magic-trail tests pass.

### Task 4: Regression Verification

**Files:**
- Test: `tests/test_chapter_4_hanuman_after_cutscene.sh`
- Test: `tests/test_chapter_4_magic_trail_runtime.sh`

**Interfaces:**
- Verifies existing Hanuman replacement behavior and the new magic-trail flow together.

- [ ] **Step 1: Run Chapter 4 focused tests**

```bash
bash tests/test_chapter_4_hanuman_after_cutscene.sh
bash tests/test_chapter_4_magic_trail_runtime.sh
```

Expected: PASS.

- [ ] **Step 2: Run Godot project validation**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit code 0 with no parser or missing-resource errors.

- [ ] **Step 3: Run whitespace validation without changing Git state**

```bash
git diff --check
```

Expected: no output and exit code 0.

