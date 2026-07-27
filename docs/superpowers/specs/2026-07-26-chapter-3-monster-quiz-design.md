# Chapter 3 Monster Quiz Design

## Goal

Require a correct Thai-language quiz answer before either Chapter 3 patrol monster can receive arrow damage.

## Scope

- Applies only to `Mob1` and `Mob2` in Chapter 3.
- Reuses the existing `QuestionQuiz` parchment modal and its pause behavior.
- Does not change combat behavior in other chapters.
- Does not perform Git operations.

## Question Mapping

- `Mob1`
  - Question: `คำใดอยู่ในมาตราตัวสะกดแม่กง`
  - Choices: `ลิง`, `ดาว`, `เมฆ`
  - Correct choice: `ลิง`
- `Mob2`
  - Question: `คำว่า “วิ่ง” เป็นคำชนิดใด`
  - Choices: `คำนาม`, `คำกริยา`, `คำวิเศษณ์`
  - Correct choice: `คำกริยา`

## Interaction Flow

1. An arrow collides with a Chapter 3 patrol monster.
2. The arrow is consumed and the Chapter 3 controller opens that monster's fixed question.
3. The scene tree pauses while the modal is visible, matching the existing quiz behavior.
4. A correct answer applies the pending arrow damage to that monster.
5. A wrong answer applies no damage and closes the modal.
6. The player must shoot the monster again to retry its question.
7. Existing death, quest-count, quest-marker, and follow-up cutscene behavior continues unchanged after damage kills a monster.

## Architecture

The shared mob gains an optional damage-authorization hook. Before changing health, it asks its configured gate whether damage is allowed. Chapter 3 configures only its two patrol mobs with the chapter controller as that gate. The controller owns the question data, opens the existing quiz, remembers one pending hit, and resolves it after the answer signal.

This keeps the arrow and global combat behavior unchanged. Other mob instances have no gate and continue receiving damage immediately.

## Edge Cases

- Only one quiz can be open at a time.
- A pending target that is removed before answering is ignored safely.
- Quiz damage bypasses the gate exactly once after a correct answer, avoiding an infinite question loop.
- Wrong answers never flash the monster as hit and never reduce health.

## Verification

- A focused runtime test verifies both question mappings.
- A correct answer reduces the intended monster's health.
- A wrong answer leaves health unchanged.
- The second monster remains unaffected while answering the first monster's question.
- Existing Chapter 3 patrol quest tests continue to pass.
- Godot loads the modified scene and scripts without parser errors.
