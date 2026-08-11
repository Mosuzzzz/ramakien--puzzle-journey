# Cutscene Dialogue Frames Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ลบคำนำหน้า `คำบรรยาย: ` จาก Cutscene ทุก Chapter และแสดงบทพูดของตัวละครในกรอบชื่อกับกล่องข้อความแบบ Chapter 1

**Architecture:** เพิ่ม `CutsceneDialoguePresenter` เป็น packed scene กลางที่มีสองโหมด: narration label แบบ Cutscene เดิม และ spoken dialogue box ที่ใช้ texture/font/layout เดียวกับ `DialogueManager` ของ Chapter 1 สคริปต์ Cutscene ยังคงเป็นเจ้าของ input, index, transition และ story flow แต่ส่งข้อมูล `{speaker, text}` ให้ presenter แทนการเขียนลง Label โดยตรง

**Tech Stack:** Godot 4.7, GDScript, `.tscn`, headless runtime tests

## Global Constraints

- ลบเฉพาะคำนำหน้า `คำบรรยาย: ` โดยประโยคหลังคำนำหน้าต้องไม่เปลี่ยน
- บทพูดต้องแยกชื่อผู้พูดออกจากประโยค และไม่แสดง `:` หรืออัญประกาศ `“ ”` ในกล่องข้อความ
- stage direction ในวงเล็บเหลี่ยมเป็น narration และไม่มีป้ายชื่อ
- รักษาปุ่ม `E`, คลิกซ้าย, skip, fade, animation, quest, scene transition และผลลัพธ์หลัง Cutscene เดิม
- ไม่แก้ระบบบทสนทนา Chapter 1; ใช้ภาพและรูปแบบของระบบนั้นเป็นต้นแบบ
- Chapter 7 ไม่มี Cutscene ข้อความในโครงสร้างปัจจุบัน จึงไม่มีไฟล์ให้แก้
- `scenes/chapter_9/chapter_9.tscn` มี user change ที่ตำแหน่ง/scale ของ `FireTowerA`; ต้องรักษาไว้ และห้ามรวม hunk นั้นใน commit ของงานนี้

---

### Task 1: สร้าง Presenter กลางด้วย TDD

**Files:**
- Create: `scenes/ui/cutscene_dialogue_presenter.gd`
- Create: `scenes/ui/cutscene_dialogue_presenter.tscn`
- Create: `tests/test_cutscene_dialogue_presenter_runtime.gd`
- Create: `tests/run_cutscene_dialogue_presenter_tests.sh`

**Interfaces:**
- Produces: `CutsceneDialoguePresenter.show_line(line: Dictionary) -> void`
- Expects each line: `{ "speaker": String, "text": String }`
- Exposes child nodes for testability: `Narration`, `Box`, `Box/NameTag/NameLabel`, `Box/Margin/TextLabel`

- [ ] **Step 1: เขียน runtime test ที่ยังไม่ผ่าน**

โหลด `res://scenes/ui/cutscene_dialogue_presenter.tscn` และตรวจ:

```gdscript
presenter.show_line({"speaker": "", "text": "พระรามเดินทางเข้าสู่ป่า"})
assert(presenter.get_node("Narration").visible)
assert(not presenter.get_node("Box").visible)
assert(presenter.get_node("Narration").text == "พระรามเดินทางเข้าสู่ป่า")

presenter.show_line({"speaker": "หนุมาน", "text": "ข้าจะตามพระองค์กลับมาให้ได้!"})
assert(not presenter.get_node("Narration").visible)
assert(presenter.get_node("Box").visible)
assert(presenter.get_node("Box/NameTag/NameLabel").text == "หนุมาน")
assert(presenter.get_node("Box/Margin/TextLabel").text == "ข้าจะตามพระองค์กลับมาให้ได้!")
```

- [ ] **Step 2: รันทดสอบและยืนยันว่า RED เพราะ presenter ยังไม่มี**

Run:

```bash
bash tests/run_cutscene_dialogue_presenter_tests.sh
```

Expected: exit code `1` จากการโหลด packed scene ที่ยังไม่มี

- [ ] **Step 3: สร้าง implementation ขั้นต่ำ**

สร้าง scene root เป็น `Control` แบบ full rect และ `mouse_filter = MOUSE_FILTER_IGNORE`:

- `Narration`: ใช้ anchor, font, outline, alignment และ autowrap แบบ Cutscene เดิม
- `Box`: `NinePatchRect` ยึดด้านล่างด้วย `dialog_box_plain.png`
- `Box/NameTag`: `NinePatchRect` ใช้ `dialog_title_tab.png`
- `NameLabel` และ `TextLabel`: ใช้ font/color/margin แบบ `dialogue_manager.tscn`

`show_line()` ต้อง toggle เฉพาะ presentation และไม่รับ input

- [ ] **Step 4: รันทดสอบและยืนยันว่า GREEN**

Run คำสั่งเดิมและคาดหวัง exit code `0`

---

### Task 2: กำหนดข้อมูล Cutscene เป็น narration/spoken อย่างชัดเจน

**Files:**
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
- Modify: `scenes/chapter_2/chapter_2_second.gd`
- Create: `tests/test_cutscene_dialogue_content_runtime.gd`
- Create: `tests/run_cutscene_dialogue_content_tests.sh`

**Interfaces:**
- Narration: `{ "speaker": "", "text": "ประโยคเดิม" }`
- Spoken: `{ "speaker": "ชื่อตัวละคร", "text": "ประโยคเดิมโดยไม่มีอัญประกาศครอบ" }`

- [ ] **Step 1: เขียน content test ที่ยังไม่ผ่าน**

ตรวจไฟล์ Cutscene `.gd` และ `.tscn` ทุก Chapter ว่า:

- ไม่มี literal `คำบรรยาย:`
- dialogue constants ที่ presenter ใช้เป็น dictionary ที่มี `speaker` และ `text`
- ตัวแทนบทพูด Chapter 2, 3, 4 และ 5 มีชื่อและประโยคแยกถูกต้อง
- stage direction ตัวแทนมี `speaker == ""`

- [ ] **Step 2: รันและยืนยันว่า RED จาก prefix และข้อมูล string แบบเดิม**

Run:

```bash
bash tests/run_cutscene_dialogue_content_tests.sh
```

Expected: exit code `1` พร้อมรายชื่อ prefix/data ที่ยังไม่ผ่าน

- [ ] **Step 3: แปลงข้อมูลแบบ mechanical และตรวจประโยค**

- ลบ `คำบรรยาย: ` ออกจาก narration ทุกบรรทัด
- ย้ายชื่อก่อน `:` ไปที่ `speaker`
- เอาเฉพาะอัญประกาศครอบนอกของบทพูดออก โดยไม่เปลี่ยนวรรคตอนภายในประโยค
- ทำ stage direction เป็น narration
- แปลง arrays ที่เกี่ยวข้องเป็น `Array[Dictionary]`
- ลบ prefix ใน `FAIL_LINES` ของ `chapter_2_second.gd` ด้วย แม้จะแสดงผ่าน global narration manager

- [ ] **Step 4: รันทดสอบ content และตรวจ diff แบบ word-level**

Expected: test ผ่านและทุกการเปลี่ยนข้อความจำกัดอยู่ที่ prefix, speaker separator และอัญประกาศครอบ

---

### Task 3: เชื่อม Presenter เข้ากับ Cutscene ทุกฉาก

**Files:**
- Modify: `scenes/chapter_2/chapter_2.tscn`
- Modify: `scenes/chapter_2/chapter_2_second.tscn`
- Modify: `scenes/chapter_3/chapter_3.tscn`
- Modify: `scenes/chapter_4/chapter_4.tscn`
- Modify: `scenes/chapter_5/chapter_5.tscn`
- Modify: `scenes/chapter_6/chapter_6.tscn`
- Modify: `scenes/chapter_8/chapter_8.tscn`
- Modify: `scenes/chapter_9/chapter_9.tscn`
- Modify: all Cutscene scripts listed in Task 2
- Create: `tests/test_cutscene_dialogue_integration_runtime.gd`
- Create: `tests/run_cutscene_dialogue_integration_tests.sh`

**Interfaces:**
- Existing node paths remain `$Dialogue` or `$PostBattleDialogue`
- The node type changes from `Label` to `CutsceneDialoguePresenter`
- Existing fade tweens continue to target presenter root `modulate:a`

- [ ] **Step 1: เขียน integration test ที่ยังไม่ผ่าน**

โหลด representative scenes แล้วตรวจ:

- Chapter 2 intro: narration visible, speech box hidden, text has no prefix
- Chapter 2 deer or abduction: advancing to spoken line shows box and speaker tag
- Chapter 3 opening: first line shows speaker `พระลักษมณ์` in tag and only sentence in body
- Chapter 3 post-battle: stage direction uses narration mode, later character line uses spoken mode
- Chapter 4 or 5: switching narration → spoken → narration toggles modes correctly

- [ ] **Step 2: รันทดสอบและยืนยันว่า RED เพราะ scenes ยังใช้ Label**

Run:

```bash
bash tests/run_cutscene_dialogue_integration_tests.sh
```

- [ ] **Step 3: แทน Label ด้วย presenter instance**

เพิ่ม external resource ของ presenter หนึ่งครั้งต่อ `.tscn` และแทน node `Dialogue`/`PostBattleDialogue` เดิมด้วย instance โดยรักษาชื่อและ parent path เดิม

ใน `chapter_9.tscn` แก้เฉพาะ resource/node Cutscene; ห้ามแตะ hunk `FireTowerA`

- [ ] **Step 4: ปรับ Cutscene scripts ให้เรียก `show_line()`**

- เปลี่ยน typed reference จาก `Label` เป็น `CutsceneDialoguePresenter`
- ส่ง dictionary ของบรรทัดปัจจุบันเข้า `show_line()`
- รักษา prompt แบบ dynamic และ fade durations เดิม
- ตอน fade ให้ tween presenter root เพื่อให้ name tag และ body fade พร้อมกัน

- [ ] **Step 5: รันทดสอบ presenter/content/integration ทั้งหมด**

Expected: ทั้งสาม runner exit code `0`

---

### Task 4: ตรวจ layout จริงและการรองรับ viewport

**Files:**
- Modify if needed: `scenes/ui/cutscene_dialogue_presenter.tscn`
- Test: representative Chapter scenes

- [ ] **Step 1: สร้าง screenshots ของโหมด narration และ spoken**

ใช้ test harness หรือเปิดฉากตัวแทนด้วย Godot ให้ได้ภาพ:

- Chapter 2/3 ที่ 1920×1080
- หนึ่ง viewport ที่แคบกว่าเพื่อทดสอบ autowrap

- [ ] **Step 2: ตรวจด้วยภาพ**

ยืนยันว่ากรอบอยู่ด้านล่างเหมือน Chapter 1, ป้ายชื่ออยู่กึ่งกลางเหนือกรอบ, ข้อความไม่ล้น, title/skip/prompt ไม่ถูกบัง และ narration เดิมยังอ่านง่าย

- [ ] **Step 3: ปรับ anchors/margins เฉพาะเมื่อหลักฐานภาพแสดงปัญหา**

รัน presenter และ integration tests ใหม่หลังทุกการปรับ

---

### Task 5: Regression และ final verification

**Files:**
- Test: existing Cutscene and Chapter test runners under `tests/`

- [ ] **Step 1: ตรวจไม่เหลือ narration prefix**

Run:

```bash
rg -n "คำบรรยาย:" scenes/cutscene scenes/chapter_* -g '*.gd' -g '*.tscn'
```

Expected: exit code `1` และไม่มี output

- [ ] **Step 2: รัน Cutscene regression tests**

Run:

```bash
bash tests/run_cutscene_transition_tests.sh
bash tests/test_chapter_2_post_abduction.sh
bash tests/test_chapter_4_hanuman_after_cutscene.sh
bash tests/test_chapter_5_post_boss_cutscene.sh
bash tests/test_chapter_6_opening_cutscene.sh
bash tests/test_chapter_8_opening_cutscene.sh
bash tests/test_chapter_9_opening_cutscene.sh
bash tests/test_chapter_9_ending_cutscene.sh
```

ใช้เฉพาะ runner ที่มีอยู่จริงใน checkout; ถ้าชื่อเปลี่ยนให้ค้น counterpart ด้วย `rg --files tests` และบันทึกคำสั่งที่ใช้จริง

- [ ] **Step 3: รัน full project suite**

รัน test runners ทั้งหมดใน `tests/` ที่เป็นชุดทดสอบของโปรเจกต์ และยืนยัน exit code `0`

- [ ] **Step 4: ตรวจ project parse/import**

Run:

```bash
HOME=/private/tmp/codex-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

Expected: exit code `0` โดยไม่มี GDScript parse error หรือ missing external resource

- [ ] **Step 5: ตรวจ Git diff และแยก user change**

- `git diff --check` ต้องผ่าน
- ตรวจว่าเนื้อเรื่องไม่เปลี่ยนนอก transformation ที่อนุมัติ
- ตรวจ `git diff -- scenes/chapter_9/chapter_9.tscn` และแยก hunk `FireTowerA` ออกจาก task commit ด้วย index-only patch หรือไม่ stage hunk นั้น
- stage เฉพาะไฟล์/hunks ของงานนี้และตรวจ `git diff --cached` ก่อน commit

