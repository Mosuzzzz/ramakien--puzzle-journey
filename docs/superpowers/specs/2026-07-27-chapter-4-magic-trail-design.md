# Chapter 4 Magic Trail Quest Design

## Goal

Replace the immediate Chapter 4 exit flow after the opening cutscene with a four-step magic-trail quest. The player follows a visible magic trace across reachable paths, answers one fixed Thai-language question at each step, and unlocks the Chapter 5 portal only after all four answers are correct.

## Player Flow

1. Chapter 4 opening cutscene plays as it does now.
2. When the cutscene ends, the player switches to Hanuman and the quest starts.
3. A floating magic-trail icon appears at the first reachable waypoint.
4. The quest log shows `ตามรอยมนตร์ 0/4`, and its world marker points to the trail icon.
5. When Hanuman approaches the icon, the prompt `กด E เพื่อตามรอยมนตร์` appears.
6. Pressing E opens the existing three-choice question UI.
7. A correct answer:
   - advances progress by one;
   - updates the quest counter;
   - smoothly moves the trail to the next waypoint, closer to the Chapter 5 exit.
8. A wrong answer:
   - does not advance progress;
   - keeps the same question active for the next attempt;
   - smoothly moves the trail to a reachable detour waypoint farther from the exit.
9. At `4/4`, the quest text becomes green, the trail stops beside the Chapter 5 portal, and the portal unlocks.
10. The player must still walk to the portal and press E to enter Chapter 5.

## Fixed Question Order

### Question 1

`คำใดสะกดถูกต้อง`

- `อนุญาติ`
- `อนุญาต` — correct
- `อนุยาต`

### Question 2

`ข้อใดใช้ภาษาได้สุภาพที่สุด`

- `เฮ้ย เอาของมาให้หน่อย`
- `ช่วยหยิบหนังสือให้ฉันหน่อยได้ไหม` — correct
- `เอาหนังสือมาเดี๋ยวนี้`

### Question 3

`ข้อใดเป็นคำอุทาน`

- `โอ๊ย! เจ็บจัง` — correct
- `ฉันเดินไปโรงเรียน`
- `น้องอ่านหนังสือ`

### Question 4

`คำว่า “เขา” ในประโยค “เขากำลังเล่นฟุตบอล” เป็นคำชนิดใด`

- `คำนาม`
- `คำสรรพนาม` — correct
- `คำกริยา`

## Scene and Script Design

- A reusable `MagicTrail` `Area2D` owns:
  - the supplied magic-trail texture;
  - a small idle bob/pulse;
  - player proximity detection;
  - the E prompt;
  - smooth movement between world positions.
- Chapter 4 owns:
  - the current question index and correct-answer count;
  - ordered forward waypoints;
  - reachable wrong-answer detour waypoints;
  - quest log updates;
  - Chapter 5 portal locking/unlocking.
- The existing `QuestionQuiz` scene is reused so the visual style and pause behavior match earlier chapters.
- The existing `Quest` autoload is reused for the quest page and world marker.

## Rules and Edge Cases

- The trail and quest must not appear before the opening cutscene finishes.
- The Chapter 5 portal is locked until four correct answers have been recorded.
- Only one quiz may be open at a time.
- Pressing E repeatedly while the icon is moving must not open duplicate quizzes.
- A wrong answer never increments progress and never changes the current question.
- A correct answer always advances to the next fixed question.
- World waypoints must be on walkable paths and the icon interaction radius must be generous enough for the player to reach it without pixel-perfect positioning.
- Leaving Chapter 4 clears this chapter’s active quest HUD.

## Scope

- Modify Chapter 4 only, plus a reusable magic-trail scene/script and Chapter 4 tests.
- Do not modify Git state: no branch creation, staging, commit, pull, push, merge, or pull request.

