# Chapter 5 Lanka March Cutscene Design

## Goal

Continue the Chapter 5 post-Maiyarap cutscene with a second image and three narration lines before returning control to Phra Ram.

## Sequence

- Keep the existing post-boss image and dialogue as phase one.
- After the final phase-one line, fade to black over 1 second.
- Show `assets/cutscene/chapter_5/ChatGPT Image 21 ก.ค. 2569 21_01_37.png` as phase two.
- Change the title banner to `มุ่งหน้าสู่กรุงลงกา`.
- Reveal phase two from black over 1 second.
- Advance these narration entries one at a time with `E`:
  1. `คำบรรยาย: ทุกคนมองไปยังกำแพงกรุงลงกา ที่ตั้งตระหง่านอยู่เบื้องหน้า`
  2. `คำบรรยาย: เสียงกลองศึกของฝ่ายยักษ์ดังขึ้นจากภายในเมือง`
  3. `คำบรรยาย: พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา เพื่อเผชิญหน้ากับทศกัณฐ์และชิงนางสีดากลับคืนมา`

## Completion

- Finish only after the third phase-two narration entry.
- Keep normal completion and skipping on the same idempotent finish path.
- Restore Phra Ram before unpausing Chapter 5.
- Do not create another boss trigger or a separate overlapping cutscene Control.

## Verification

- Confirm the new image UID is `uid://cm4owh1l85bo4`.
- Confirm phase one transitions to phase two instead of finishing.
- Confirm the prompt indicates continuation at the end of phase one and return to Chapter 5 only at the final phase-two line.
- Confirm skip from either phase restores Phra Ram and unpauses.
- Run focused structural tests and `git diff --check`.
