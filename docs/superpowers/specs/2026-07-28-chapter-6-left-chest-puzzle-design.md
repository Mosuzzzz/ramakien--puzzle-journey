# Chapter 6 Left-Tower Chest Puzzle Design

## Goal

Add a three-question Thai-language chest puzzle to the left tower room in
Chapter 6. Solving all three questions unlocks the chest and reveals the
bar-shaped Lanka key fragment. The player must approach the fragment and
press E to collect it as a separate inventory item.

This design covers only the left tower room. The right-room puzzle and the
Lanka city-gate unlock remain deferred.

## Player Experience

### Starting the Puzzle

The existing chest visible on the left side of the room gains an interaction
area. While the player is close enough, the world prompt reads:

`กด E เพื่อปลดล็อกกล่อง`

Pressing E pauses the game and fades a translucent dark overlay over the room.
The room remains visible behind the overlay. A large version of
`ChatGPT Image 28 ก.ค. 2569 21_07_11.png` appears centered on screen at
approximately 65–75 percent of the viewport width; it does not fill the whole
screen.

Before the first question, the puzzle displays:

`ตอบคำถามให้ถูกต้องเพื่อปลดล็อกกล่องนี้`

It also displays:

`กด E เพื่อเริ่ม`

The player can press E or click to begin.

### Lock Indicators

Three status indicators align with the three empty square slots in the chest
image. Their positions and sizes use normalized anchors relative to the chest
image instead of fixed viewport pixels, keeping them aligned when the viewport
scale changes:

- Each color rectangle stays fully inside the dark center of its corresponding
  slot and leaves the surrounding gold frame visible on all four sides.
- The measured normalized inner bounds are:
  - slot 1: left `0.274`, top `0.527`, right `0.386`, bottom `0.616`;
  - slot 2: left `0.444`, top `0.527`, right `0.556`, bottom `0.616`; and
  - slot 3: left `0.630`, top `0.527`, right `0.742`, bottom `0.616`.
- An unanswered slot has a neutral dark appearance.
- A correct answer turns the current slot green permanently.
- A wrong answer flashes the current slot red for approximately one second.
- Input is disabled during the red flash.
- After the flash, all three slots return to neutral and the puzzle returns to
  question 1.
- Every wrong answer shuffles the displayed positions of the three choices for
  every question. Correctness follows the choice's original identity, not its
  displayed button index.

The first attempt uses the authored choice order. Shuffling occurs only after
a wrong answer.

### Cancelling

While answering, the modal shows an on-screen `ยกเลิก (Esc)` button in the
upper-left corner of the viewport. It uses a 24-pixel margin from the top and
left edges and remains separate from the lower question panel. The Esc key
performs the same action. Either action fades the UI out, unpauses the room,
clears all temporary answer progress, and returns the player to the same world
position. The chest remains locked, and approaching it again starts from
question 1 with neutral slots.

Cancel input is temporarily disabled during the one-second wrong-answer flash
so a running tween or paused state cannot leak into the room.

## Questions

Questions appear in this fixed order. A wrong answer returns to question 1 and
reshuffles the displayed choice positions.

### Question 1

`ใจความสำคัญของข้อความ “ต้นไม้ให้ร่มเงา ช่วยฟอกอากาศ และเป็นที่อยู่อาศัยของสัตว์” คือข้อใด`

1. `ต้นไม้มีสีเขียว`
2. `ต้นไม้มีประโยชน์หลายอย่าง` — correct
3. `สัตว์ชอบอาศัยบนต้นไม้`

### Question 2

`ข้อใดเป็นประโยคที่มีความหมายโดยนัย`

1. `พ่อเป็นเสาหลักของครอบครัว` — correct
2. `บ้านหลังนี้มีเสาสี่ต้น`
3. `ช่างกำลังซ่อมเสาไม้`

### Question 3

`ข้อใดใช้คำราชาศัพท์ได้ถูกต้อง`

1. `พระมหากษัตริย์กินอาหาร`
2. `พระมหากษัตริย์เสวยพระกระยาหาร` — correct
3. `พระมหากษัตริย์ทานข้าว`

## Completion and Reward Flow

After the third correct answer:

1. The chest is marked permanently unlocked for the current story.
2. The puzzle UI and dark overlay fade out.
3. Gameplay resumes with the player still standing in front of the chest.
4. A bar-shaped key fragment appears above the chest.
5. Only the fragment visual bobs vertically so its interaction position stays
   stable.
6. Approaching the fragment displays
   `กด E เพื่อเก็บชิ้นส่วนกุญแจ`.
7. Pressing E adds exactly one `lanka_key_fragment_bar` item, removes the world
   pickup, and refreshes the three-fragment quest progress.

The existing reusable key-fragment pickup scene provides the bobbing,
proximity prompt, and one-shot collection behavior.

## Quest Integration

Chapter 6 key-fragment progress is derived from the three distinct inventory
IDs:

- `lanka_key_fragment_shaft` — Yak Captain
- `lanka_key_fragment_bar` — left-tower chest
- `lanka_key_fragment_ring` — future right-room puzzle

Each ID contributes at most one point. Collecting the left-room fragment must
therefore update the quest correctly regardless of collection order:

- Bar collected first: `1/3`
- Bar collected after the Yak fragment: `2/3`
- Bar collected after both other fragments in future: `3/3`

Quest name and detail remain:

- `ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง`
- `รวบรวมชิ้นส่วนกุญแจ X/3`

A small shared Chapter 6 quest helper will own the fragment IDs, quest text,
progress calculation, and quest refresh. Both the main Chapter 6 controller
and the left-room controller call this helper, avoiding duplicated progress
rules.

## Architecture

### Left-Room Controller

Attach a Chapter 6 left-room-specific controller to
`chapter_6_room_left.tscn`. It:

- restores the chest state when the room opens;
- opens the puzzle when the player presses E near the locked chest;
- receives the puzzle-completed signal;
- records the chest as unlocked;
- spawns or restores the uncollected bar fragment above the chest;
- adds the fragment to inventory after a collection request; and
- refreshes the Chapter 6 quest immediately while still inside the room.

The controller adds only puzzle and interaction nodes. It must not rewrite,
resize, or reposition any existing `Walls` collision nodes.

### Chest Interaction

A dedicated `Area2D` covers the authored chest position. It shows its prompt
only for the `Player`, accepts a non-echo E key press once, and disables
interaction while the modal is opening or active. Once the chest is unlocked,
the locked-chest prompt never appears again.

### Chest Puzzle UI

A dedicated `CanvasLayer` owns:

- the translucent full-viewport dark overlay;
- the centered chest image;
- the instruction state;
- the explicit `กด E เพื่อเริ่ม` hint;
- three visual lock indicators;
- the question label;
- three answer buttons; and
- an upper-left on-screen cancel button; and
- fade and wrong-answer animations.

The UI exposes a single `open()` entry point, emits `solved` once on success,
and emits `cancelled` once when the player presses the button or Esc. It owns
temporary question progress and shuffled display mappings but does not modify
GameState, inventory, quest data, or room nodes directly.

The CanvasLayer uses `PROCESS_MODE_ALWAYS` so its buttons, fades, and one-second
wrong-answer timer continue while the scene tree is paused.

### Shared Quest Helper

A focused Chapter 6 helper centralizes:

- the three fragment IDs;
- quest name and detail strings;
- distinct-item progress calculation; and
- updating the Quest autoload.

The current main Chapter 6 controller will be changed to use this helper
without altering the already verified Yak-drop behavior.

## Persistence and Restoration

Add:

`GameState.chapter_6_left_chest_unlocked: bool`

The value is included in save-slot state and reset when starting a new story.
Temporary per-question progress is not saved. Cancelling explicitly clears it,
and scene saving is unavailable while the paused modal is active.

Room restoration follows these rules:

- Locked and bar absent: show the locked-chest interaction.
- Unlocked and bar absent: hide the chest interaction and spawn one bar
  fragment above the chest.
- Bar present in inventory: treat the chest as unlocked, hide the interaction,
  and do not spawn a fragment.

This means leaving the room after solving but before collecting preserves the
unlocked chest and restores the waiting fragment. Loading a save in the same
state behaves identically.

## Input and Duplicate Safety

- The world interaction ignores repeated E key events while opening.
- The puzzle disables answer buttons during the red flash.
- The puzzle disables cancel input during the red flash.
- A correct answer advances only once and completed slots cannot be answered
  again.
- The `solved` signal emits exactly once.
- The `cancelled` signal emits exactly once per open attempt and restores the
  world chest prompt if the player remains nearby.
- Shuffled buttons carry their source choice identity, so changing display
  order cannot change which answer is correct.
- Fragment spawning checks both the scene and inventory to avoid duplicates.
- Fragment collection checks inventory before adding the bar item.
- The world prompt and puzzle modal are mutually exclusive, preventing one E
  press from opening and collecting in the same frame.

## Verification

Automated tests will verify:

1. The chest prompt appears only when the Player is in range.
2. E opens the modal, pauses gameplay, darkens the room, and shows the large
   chest image and instruction.
3. The instruction visibly includes `กด E เพื่อเริ่ม`, and E or clicking
   advances to question 1.
4. All three fixed questions, choices, and correct indices match this design.
5. A wrong answer flashes only the current slot red and blocks answer/cancel
   input for about one second.
6. After the flash, all slots reset, question 1 returns, and all question
   choices receive a newly shuffled display order while retaining correctness.
7. The cancel button and Esc close the modal, unpause the room, clear progress,
   and allow the chest to be opened again.
8. Normalized lock indicators remain inside all three artwork frames at the
   supported viewport sizes.
9. Correct answers turn slots green and advance one question at a time.
10. Three correct answers emit one solved event and close the modal.
11. Completion marks the chest unlocked and creates one floating bar fragment
   above the chest.
12. Leaving and returning before collection restores the fragment without
   reopening the puzzle.
13. E collection adds only `lanka_key_fragment_bar`, removes the pickup, and
    updates quest progress from the inventory-derived count.
14. Re-entering after collection creates neither the chest prompt nor a
    duplicate fragment.
15. Save/load, new-story reset, existing Yak-fragment behavior, the full test
    suite, and Godot headless parsing remain valid.
16. A before-and-after hash of the left-room `Walls` section remains identical.

## Deferred Work

- Right-tower puzzle and ring-fragment reward
- Combining the three fragments
- Unlocking or opening the Lanka city gate
- New chest-opening artwork or a world-map chest sprite replacement
