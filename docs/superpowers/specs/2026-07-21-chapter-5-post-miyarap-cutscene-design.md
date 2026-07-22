# Chapter 5 Post-Maiyarap Cutscene Design

## Goal

Play a story cutscene immediately after Maiyarap is defeated in Chapter 5, then replace Hanuman with Phra Ram and return control to the player in Chapter 5.

## Trigger and progression

- Attach a Chapter 5 controller to the scene root.
- Observe the existing `YSortRoot/Miyarap` node leaving the scene tree.
- Start the cutscene once, only while Chapter 5 remains the active scene.
- Keep the Chapter 6 portal available after the cutscene so the player enters it manually.

## Cutscene presentation

- Add a full-screen cutscene Control under a high-layer CanvasLayer in `chapter_5.tscn`.
- Use `assets/cutscene/chapter_5/ChatGPT Image 21 ก.ค. 2569 18_34_46.png` as the background.
- Reuse the established title banner, dark overlay, Thai fonts, dialogue label, continue prompt, and skip button pattern from Chapters 3 and 4.
- Fade gameplay to black for 1 second and reveal the cutscene over 1 second.
- Pause gameplay and consume keyboard input while the cutscene is active.
- Advance the supplied narration and dialogue one entry at a time with `E`.

## Dialogue sequence

1. `คำบรรยาย: ไมยราพล้มลงกับพื้น`
2. `คำบรรยาย: อาคมสีดำที่พันธนาการพระรามแตกสลาย`
3. `คำบรรยาย: พระรามลืมพระเนตรขึ้น`
4. `พระราม: “หนุมาน...”`
5. `คำบรรยาย: หนุมานรีบเข้าไปประคองพระราม`
6. `หนุมาน: “พระองค์ปลอดภัยแล้ว”`
7. `คำบรรยาย: พระรามยืนขึ้น`
8. `คำบรรยาย: ทอดพระเนตรไปยังหนุมานด้วยความภาคภูมิใจ`
9. `พระราม: “เจ้ากล้าหาญและซื่อสัตย์ยิ่ง”`
10. `พระราม: “ข้าขอขอบใจเจ้า”`
11. `คำบรรยาย: หนุมานคุกเข่าลง`
12. `หนุมาน: “การปกป้องพระองค์ คือหน้าที่ของข้า”`
13. `คำบรรยาย: พระลักษมณ์และกองทัพวานรเดินทางมาสมทบ`
14. `พระลักษมณ์: “พี่พระราม!”`
15. `คำบรรยาย: พระรามพยักหน้า`
16. `พระราม: “ถึงเวลาสิ้นสุดสงครามแล้ว”`

## Player restoration

- When the cutscene ends or is skipped, record Hanuman's current position.
- Remove the Hanuman player instance and instantiate `res://scenes/player/player.tscn` as `YSortRoot/Player` at the same position.
- Unpause the scene only after the replacement is complete.
- Make the finish path idempotent so it cannot create multiple Phra Ram instances.

## Safety and verification

- Do not modify or overwrite the user's existing changes in `scenes/chapter_4/chapter_4.tscn` or `assets/.DS_Store`.
- Verify the image UID matches its Godot `.import` file.
- Verify all new scene node paths match the scripts.
- Verify the boss removal triggers the cutscene only once.
- Verify both normal completion and skipping restore Phra Ram and unpause gameplay.
- Run Godot headless validation when a Godot executable is available; otherwise perform scene/resource and GDScript structural checks plus `git diff --check`.
