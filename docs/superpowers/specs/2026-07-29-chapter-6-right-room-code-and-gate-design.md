# Chapter 6 Right-Room Code and Lanka Gate Design

## Goal

Add the right-tower puzzle that awards the third Lanka key fragment, then use
all three fragments to unlock the Chapter 6 city gate and enter Chapter 7.

The right-room puzzle asks the player to search four jars. Three jars reveal
the digits `2`, `7`, and `3`; one jar is empty. Each unsearched jar requires a
fixed Thai-language question before its contents are revealed. The player must
remember the discovered digits and enter `273` at the room's central pedestal.

## Player Flow

1. Entering the right tower replaces the general fragment quest with:
   `ค้นหาโค้ดลับเพื่อปลดล็อกชิ้นส่วนกุญแจ`.
2. This room-specific quest has no progress counter or explanatory detail.
3. The player searches the four jars in any order.
4. An unsearched jar asks its fixed question. A correct answer reveals that
   jar's contents and permanently marks it searched.
5. A searched jar remains interactive and can be viewed again without another
   question.
6. The central pedestal is interactive at all times, including before any jar
   has been searched.
7. The pedestal shows discovered digits and `?` for undiscovered digits.
8. Entering the correct code `273` unlocks the pedestal and creates the
   ring-shaped Lanka key fragment above it.
9. The player approaches the floating fragment and presses E to collect it.
10. The general Chapter 6 key-fragment quest returns. If all three fragments
    are present, it displays `3/3` in the completed green state and directs the
    player to the city gate.
11. The player approaches the city gate and presses E. The three fragments are
    consumed, the gate is permanently marked unlocked, and the game enters
    Chapter 7.

## Jar Placement and Contents

The four interactions are distributed around the right room and are not
ordered as `2`, `7`, `3` along the walking path:

| Position | Contents | Question |
| --- | --- | --- |
| Upper-left | `7` | Question 1 |
| Upper-right | Empty | Question 2 |
| Lower-left | `3` | Question 3 |
| Lower-right | `2` | Question 4 |

Interaction areas align with existing jar artwork in the room background.
They do not add, delete, resize, or reposition any existing `Walls` collision
node.

An unsearched jar shows `กด E เพื่อค้นหา`. A searched jar shows
`กด E เพื่อดูในโหล`.

## Jar Questions

Each jar keeps the same question permanently. Choices use the authored order
on the first attempt.

### Question 1 — Upper-left Jar

`ข้อใดเป็นคำพ้องเสียง`

1. `การ – กาล` — correct
2. `บ้าน – เรือน`
3. `สูง – ต่ำ`

### Question 2 — Upper-right Empty Jar

`คำว่า “เสียสละ” มีความหมายตรงกับข้อใด`

1. `ยอมสละประโยชน์ของตนเพื่อผู้อื่น` — correct
2. `ทำงานโดยหวังรางวัล`
3. `หลีกเลี่ยงการช่วยเหลือ`

### Question 3 — Lower-left Jar

`สำนวน “น้ำขึ้นให้รีบตัก” หมายถึงอะไร`

1. `ให้รีบตักน้ำเก็บไว้`
2. `ให้ใช้โอกาสที่ดีให้เกิดประโยชน์` — correct
3. `ให้ทำงานอย่างช้า ๆ`

### Question 4 — Lower-right Jar

`ข้อใดใช้คำเชื่อมได้ถูกต้อง`

1. `เพราะฝนตก แต่ฉันจึงกางร่ม`
2. `เพราะฝนตก ฉันจึงกางร่ม` — correct
3. `แม้ฝนตก เพราะฉันกางร่ม`

## Jar Modal

Pressing E at a jar pauses the room, darkens the world, and displays a large
jar-interior image. The question panel covers the central opening until the
answer is correct.

The four result images are:

- Empty: `ChatGPT Image 28 ก.ค. 2569 21_09_37.png`
- `2`: `ChatGPT Image 28 ก.ค. 2569 21_52_39.png`
- `7`: `ChatGPT Image 28 ก.ค. 2569 21_53_12.png`
- `3`: `ChatGPT Image 28 ก.ค. 2569 21_53_33.png`

Answer behavior:

- A wrong choice flashes red for approximately one second.
- Answer and cancel input are disabled during the red feedback.
- After the flash, the same question returns with its three choice positions
  shuffled.
- The shuffled button retains its original answer identity, so display order
  cannot change correctness.
- A correct choice permanently marks only that jar searched, removes the
  question panel, and reveals the result image.

The result remains visible until the player presses E, Esc, or the upper-left
`ยกเลิก (Esc)` button. Closing returns the player to the same room position.
Reopening a searched jar skips directly to this result state. Viewing it again
does not duplicate a digit or change persistence.

Cancelling before a correct answer leaves the jar unsearched. Every modal open
attempt resets temporary shuffle and feedback state.

## Central Code Pedestal

The central interaction uses:

`ChatGPT Image 28 ก.ค. 2569 21_08_34.png`

Its world prompt is `กด E เพื่อใส่รหัส` and remains available before, during,
and after jar searching until the code is solved.

The modal contains:

- the large pedestal image;
- three code-entry slots;
- three source buttons corresponding to the three numbered jars;
- an upper-left `ยกเลิก (Esc)` button; and
- a `ล้างรหัส` button.

For every numbered jar not yet searched, its source button displays `?` and is
disabled. A discovered digit displays its actual value and becomes selectable.
The empty jar never creates a digit button and is not required to use the
pedestal. Therefore, the player can solve the pedestal after finding `2`, `7`,
and `3` even if the empty jar remains unsearched.

Selecting a digit appends it to the next code slot. Digits may be selected more
than once, and the clear button resets all three slots. Evaluation occurs
automatically when the third slot is filled:

- Wrong code: all three slots flash red for approximately one second, input is
  locked, and all slots then reset.
- Correct code `273`: all three slots turn green for one second, the modal
  closes, gameplay resumes, the solved state is persisted, and one ring
  fragment appears above the central pedestal.

Cancel closes the modal and discards the current partial code without changing
jar or pedestal persistence. Cancel is disabled during red or green feedback.

## Ring Fragment Reward

The right-room reward uses:

- inventory ID: `lanka_key_fragment_ring`
- texture: `res://assets/ui/icon/split/image-removebg-preview.png`

It uses the existing reusable key-fragment pickup:

- only the visual bobs vertically;
- proximity shows `กด E เพื่อเก็บชิ้นส่วนกุญแจ`;
- E adds exactly one ring fragment to inventory and removes the world pickup;
- leaving or loading after solving but before collection restores one waiting
  pickup; and
- an inventory check prevents duplicate pickups.

While the solved reward is waiting, the room quest becomes
`เก็บชิ้นส่วนกุญแจ`. After collection, the shared Chapter 6 fragment quest is
restored.

## Quest and Gate Flow

The shared fragment quest continues to derive progress from the three distinct
inventory IDs:

- `lanka_key_fragment_shaft`
- `lanka_key_fragment_bar`
- `lanka_key_fragment_ring`

Before all three are collected it remains:

- name: `ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง`
- detail: `รวบรวมชิ้นส่วนกุญแจ X/3`

At `3/3`, all quest text turns green and the detail additionally directs the
player to the city gate.

The existing `Chapter7Portal` at the top of the Chapter 6 main map is the Lanka
city gate:

- It starts locked.
- While locked, E does not change scene and the prompt explains that all three
  fragments are required.
- At `3/3`, its prompt changes to `กด E เพื่อใช้กุญแจเปิดประตูเมือง`.
- The first valid use records the gate as unlocked before inventory mutation,
  removes exactly one of each fragment, and enters
  `res://scenes/chapter_7/chapter_7.tscn`.
- If the player later returns from Chapter 7, the persisted gate state keeps
  the portal open even though the consumed fragments are no longer present.
- Once the gate is unlocked, the completed gate objective remains resolved and
  must not fall back to `0/3` merely because the three fragments were consumed.

The reusable portal emits an activation signal only after its locked check.
The Chapter 6 controller listens only to the Chapter 7 portal's signal to
persist the gate state and consume the fragments before the existing scene
transition.

## Persistence

Add three saved story values:

- `chapter_6_right_jars_mask: int` — four searched bits, one per jar;
- `chapter_6_right_pedestal_solved: bool`; and
- `chapter_6_gate_unlocked: bool`.

The values are included in save slots and reset for a new story.

Restoration rules:

- A set jar bit skips its question and opens the result directly.
- A solved pedestal disables code entry.
- A solved pedestal with no ring in inventory restores one ring pickup.
- A ring already in inventory implies the pedestal is solved and prevents a
  duplicate pickup.
- An unlocked gate remains usable regardless of current fragment inventory.
- An unlocked gate overrides inventory-derived fragment progress when restoring
  the completed Chapter 6 gate objective.
- Temporary answer order, red feedback, and partial code are never saved.

## Architecture

### Right-Room Controller

`chapter_6_room_right.gd` owns world interactions, jar mask restoration,
room-specific quest text, pedestal completion, reward spawning, and ring
collection. It does not contain modal drawing code.

### Jar Modal

A dedicated paused-mode CanvasLayer receives one jar definition at a time,
owns question/result states, shuffling, feedback, E/Esc close behavior, and
emits `searched(jar_index)` only after a correct answer.

### Code Modal

A separate paused-mode CanvasLayer receives the currently discovered digit
set, owns temporary code entry and feedback, and emits `solved` once for
`273`. It does not modify GameState or inventory.

### Shared Quest Helper and Main Chapter Controller

The shared key helper continues to calculate distinct-fragment progress and
formats the completed gate instruction. The main Chapter 6 controller locks or
unlocks `Chapter7Portal`, consumes fragments on valid gate activation, and
persists the gate state.

## Duplicate and Input Safety

- Only one nearby world interaction can open a modal per E press.
- World prompts hide while a modal is active.
- Modal CanvasLayers use `PROCESS_MODE_ALWAYS`.
- Feedback locks answer, clear, digit, cancel, and E input.
- Jar search completion emits once per modal open attempt.
- Pedestal completion emits once.
- Jar mask updates use bitwise OR and cannot erase another jar's progress.
- Ring spawning and collection both check inventory and scene state.
- Gate unlock state is set before fragment removal so inventory change signals
  cannot relock the gate mid-transition.
- Gate activation validates all three fragments before removing any item.

## Verification

Automated tests will verify:

1. All four jar interactions and prompts exist at distinct room positions.
2. The exact questions, choices, correct answers, result images, and
   jar-to-result mapping match this design.
3. Wrong answers flash red, block cancel, retry the same jar, and shuffle
   choices without changing correctness.
4. Cancel before success leaves the jar unsearched.
5. Correct answers persist the jar bit and reveal the correct result.
6. E, Esc, and the cancel button close a revealed result.
7. Searched jars reopen directly without asking or duplicating progress.
8. The right-room quest has exactly the requested name and no progress detail.
9. The pedestal opens at any time and shows `?` for undiscovered digits.
10. The empty jar is not required once `2`, `7`, and `3` are discovered.
11. Wrong three-digit input flashes all slots red and clears.
12. `273` turns all slots green for one second, persists completion, and
    creates one waiting ring pickup.
13. Ring collection adds exactly one item and restores the shared quest.
14. Save/load and new-story reset preserve or clear all three new story values
    correctly.
15. `3/3` is green and directs the player to the city gate.
16. The locked gate does not transition early.
17. Valid gate use consumes exactly the three fragment items, persists the
    unlock, and targets Chapter 7.
18. Returning to Chapter 6 keeps the gate open after consumption.
19. Returning after consumption does not regress the completed objective to
    `0/3`.
20. Existing Yak and left-room fragment flows remain valid.
21. The full test suite and Godot headless parsing pass.
22. A before-and-after hash of the right-room `Walls` section remains
    `85e05ccc80cbe5bda47eb105bdb43b99e921d8b8733e160f4917ad7cca03820e`.

## Deferred Work

- A dedicated gate-opening cutscene or new gate artwork
- Combining the three fragments into a separate assembled-key inventory item
- Additional randomized jar questions
