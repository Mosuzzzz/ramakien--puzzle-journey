# Chapter 3 Monster Quiz Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gate arrow damage to the two Chapter 3 patrol monsters behind their assigned Thai quiz questions.

**Architecture:** Add an optional damage gate to the shared mob script and configure it only from the Chapter 3 controller. The controller uses the existing `QuestionQuiz`, tracks one pending monster hit, and applies damage directly only after a correct answer.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scene resources, headless Godot runtime tests, POSIX shell contract tests.

## Global Constraints

- Apply the quiz only to `Mob1` and `Mob2` in Chapter 3.
- Reuse `scenes/ui/question_quiz.tscn`.
- Wrong answers apply zero damage; retry requires another arrow hit.
- Do not alter other chapters' combat behavior.
- Do not run Git commands.

---

### Task 1: Define and test the Chapter 3 quiz contract

**Files:**
- Create: `tests/test_chapter_3_monster_quiz.sh`
- Create: `tests/test_chapter_3_monster_quiz_runtime.gd`

**Interfaces:**
- Consumes: `QuestionQuiz.ask(question: String, choices: Array, correct_index: int)`
- Produces: an executable contract test and a runtime behavior test for the damage gate

- [ ] **Step 1: Write the failing shell contract test**

Assert that Chapter 3 declares both exact questions, configures both mobs, and instances `question_quiz.tscn`.

- [ ] **Step 2: Write the failing runtime test**

Instantiate Chapter 3, start a gated hit on `Mob1`, verify its fixed question, answer incorrectly, and assert unchanged health. Repeat with a correct answer and assert damage. Verify `Mob2` uses the word-class question.

- [ ] **Step 3: Run tests to verify they fail**

Run:

```sh
sh tests/test_chapter_3_monster_quiz.sh
godot --headless --path . --script tests/test_chapter_3_monster_quiz_runtime.gd
```

Expected: failures because the scene has no Chapter 3 quiz instance or damage gate.

### Task 2: Add the optional monster damage gate

**Files:**
- Modify: `scenes/props/mob.gd`

**Interfaces:**
- Produces: `damage_gate: Node`, `take_damage(amount: int)`, and `apply_authorized_damage(amount: int)`
- Calls: `damage_gate.request_mob_damage(self, amount)`

- [ ] **Step 1: Route configured hits to the gate**

When `damage_gate` is valid and implements `request_mob_damage`, call it instead of changing `_health`.

- [ ] **Step 2: Add authorized damage entry point**

Move flash, health subtraction, and death behavior into `apply_authorized_damage`; keep `take_damage` immediate for mobs without a gate.

- [ ] **Step 3: Run existing combat-loading tests**

Run the focused runtime test and existing Chapter 3 patrol tests. Expected: the new test still fails only because Chapter 3 has not configured the gate; old tests pass.

### Task 3: Connect Chapter 3 questions and modal

**Files:**
- Modify: `scenes/chapter_3/chapter_3.gd`
- Modify: `scenes/chapter_3/chapter_3.tscn`

**Interfaces:**
- Consumes: `QuestionQuiz.answered(correct: bool)`
- Produces: `request_mob_damage(mob: Node, amount: int) -> void`
- Calls: `mob.apply_authorized_damage(amount)` only for a correct answer

- [ ] **Step 1: Instance the existing quiz scene**

Add a `QuestionQuiz` child to Chapter 3 using `res://scenes/ui/question_quiz.tscn`.

- [ ] **Step 2: Configure fixed question data**

Map `Mob1` to `["คำใดอยู่ในมาตราตัวสะกดแม่กง", ["ลิง", "ดาว", "เมฆ"], 0]` and `Mob2` to `["คำว่า “วิ่ง” เป็นคำชนิดใด", ["คำนาม", "คำกริยา", "คำวิเศษณ์"], 1]`.

- [ ] **Step 3: Configure damage gates**

During `_ready`, assign the Chapter 3 controller as `damage_gate` for both patrol mobs and connect the quiz answer signal once.

- [ ] **Step 4: Resolve answers safely**

Store one pending mob and damage amount. On correct answer, call `apply_authorized_damage`; on wrong answer, clear pending state without damage.

- [ ] **Step 5: Run focused tests**

Run:

```sh
sh tests/test_chapter_3_monster_quiz.sh
godot --headless --path . --script tests/test_chapter_3_monster_quiz_runtime.gd
godot --headless --path . --script tests/test_chapter_3_patrol_flow_runtime.gd
sh tests/test_chapter_3_patrol_quest.sh
```

Expected: all pass.

### Task 4: Final parser and regression verification

**Files:**
- Verify only; no additional production files expected

**Interfaces:**
- Consumes the completed Chapter 3 scene and scripts.
- Produces verification evidence.

- [ ] **Step 1: Run Godot scene import/parser check**

Run Chapter 3 headlessly and confirm there are no parser or invalid-node errors.

- [ ] **Step 2: Run relevant Chapter 2 quiz regression**

Load the Chapter 2 chase scene or its focused tests to confirm the reused quiz still behaves normally.

- [ ] **Step 3: Run whitespace validation without Git**

Scan modified text files for merge markers and trailing whitespace using `rg`.
