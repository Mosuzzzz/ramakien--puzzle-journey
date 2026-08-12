# Responsive Cutscene Dialogue Box Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ทำให้กรอบบทพูด Cutscene ทุก Chapter อยู่กึ่งกลางด้านล่างและปรับทั้งความกว้างกับความสูงตามประโยค พร้อมวาง prompt กด E ภายในกรอบโดยไม่ซ้อนขอบ

**Architecture:** ขยาย `CutsceneDialoguePresenter` กลางให้เป็นเจ้าของ `ContinueLabel` ในโหมดบทพูด และคำนวณขนาด Box จาก font metrics กับ viewport จริง โดยคง Label prompt ภายนอกไว้สำหรับโหมดคำบรรยายและรักษา API `show_line(line, prompt_label)` เดิม ทุก Chapter จึงได้พฤติกรรมใหม่โดยไม่เปลี่ยน story flow หรือสคริปต์ Cutscene รายฉาก

**Tech Stack:** Godot 4.7, GDScript, Godot Control/NinePatchRect layout, headless runtime tests

## Global Constraints

- Box ต้องอยู่กึ่งกลางแนวนอนและยึดด้านล่างโดยเว้นขอบล่าง 24 px
- Box ต้องลดหรือขยายทั้งความกว้างและความสูงตามประโยค
- Box ต้องมีขนาดขั้นต่ำที่รักษา NinePatch/ป้ายชื่อ/prompt และต้องไม่กว้างเกิน 84% ของ viewport
- ประโยคที่กว้างเกินเพดานต้อง wrap แบบ word smart แล้วเพิ่มความสูงตามจำนวนบรรทัด
- prompt ในโหมดบทพูดต้องอยู่ภายใน Box ชิดขวา และไม่ชนขอบล่าง
- prompt ภายนอกต้องซ่อนเฉพาะโหมดบทพูดและกลับมาแสดงในโหมดคำบรรยาย
- ต้องรักษาข้อความ prompt แบบ dynamic ของทุก Chapter เช่น เริ่มสำรวจ เริ่มต่อสู้ และจบเรื่องราว
- ไม่เปลี่ยน input, fade, skip, animation, quest, scene transition หรือระบบ DialogueManager ของ Chapter 1

---

### Task 1: ล็อกพฤติกรรม responsive layout และ prompt ด้วย RED tests

**Files:**
- Modify: `tests/test_cutscene_dialogue_presenter_runtime.gd`

**Interfaces:**
- Consumes: `CutsceneDialoguePresenter.show_line(line: Dictionary, prompt_label: Label = null) -> void`
- Verifies nodes: `Box`, `Box/NameTag`, `Box/Margin/VBox/TextLabel`, `Box/Margin/VBox/ContinueLabel`

- [ ] **Step 1: เพิ่ม test สำหรับ prompt ภายในกรอบ**

หลังเรียก spoken line ให้ตรวจว่า external prompt ถูกซ่อน, internal prompt มีข้อความเดียวกัน และ global rect ของ internal prompt อยู่ภายใน global rect ของ Box พร้อมระยะปลอดภัยจากขอบล่าง

```gdscript
var internal_prompt := presenter.get_node("Box/Margin/VBox/ContinueLabel") as Label
_expect(not prompt.visible, "spoken mode hides the external prompt")
_expect(internal_prompt.visible, "spoken mode shows the prompt inside the box")
_expect(internal_prompt.text == prompt.text, "internal prompt mirrors dynamic prompt text")
_expect(
	box.get_global_rect().encloses(internal_prompt.get_global_rect()),
	"spoken prompt stays inside the dialogue box"
)
_expect(
	internal_prompt.get_global_rect().end.y <= box.get_global_rect().end.y - 20.0,
	"spoken prompt keeps safe space above the bottom border"
)
```

- [ ] **Step 2: เพิ่ม test เปรียบเทียบประโยคสั้นและยาว**

ตั้ง viewport เป็น 1280×720 แสดงประโยคสั้น บันทึก `box.size` จากนั้นแสดงประโยคยาวที่ wrap หลายบรรทัดและตรวจว่ากว้าง/สูงกว่า แต่ไม่เกิน 84% viewport

```gdscript
presenter.show_line({"speaker": "หนุมาน", "text": "พี่น้องวานรทั้งหลาย!"}, prompt)
await process_frame
var short_size := box.size
presenter.show_line({"speaker": "หนุมาน", "text": LONG_THAI_DIALOGUE}, prompt)
await process_frame
var long_size := box.size
_expect(short_size.x < long_size.x, "short dialogue uses a narrower box")
_expect(short_size.y < long_size.y, "wrapped dialogue uses a taller box")
_expect(long_size.x <= presenter.size.x * 0.84 + 1.0, "box respects maximum viewport width")
```

- [ ] **Step 3: เพิ่ม test สำหรับการวางกึ่งกลางและ narration fallback**

```gdscript
_expect(absf(box.position.x + box.size.x * 0.5 - presenter.size.x * 0.5) <= 1.0,
	"dialogue box stays horizontally centered")
presenter.show_line({"speaker": "", "text": "คำบรรยาย"}, prompt)
_expect(prompt.visible, "narration restores the external prompt")
_expect(not internal_prompt.visible, "narration hides the internal spoken prompt")
```

- [ ] **Step 4: รันทดสอบและยืนยัน RED จาก node/behavior ที่ยังไม่มี**

Run:

```bash
bash tests/run_cutscene_dialogue_presenter_tests.sh
```

Expected: exit code `1` เพราะยังไม่มี `VBox/ContinueLabel`, external prompt ยังไม่ถูกซ่อน และ Box ยังมีขนาดคงที่

- [ ] **Step 5: Commit RED test**

```bash
git add tests/test_cutscene_dialogue_presenter_runtime.gd
git commit -m "test: cover responsive cutscene dialogue layout"
```

---

### Task 2: สร้างโครงสร้าง Box แบบ Chapter 1 และจัดขนาดอัตโนมัติ

**Files:**
- Modify: `scenes/ui/cutscene_dialogue_presenter.tscn`
- Modify: `scenes/ui/cutscene_dialogue_presenter.gd`
- Test: `tests/test_cutscene_dialogue_presenter_runtime.gd`

**Interfaces:**
- Produces: internal Label path `Box/Margin/VBox/ContinueLabel`
- Produces: `_fit_spoken_box() -> void` and `_refresh_layout() -> void`
- Preserves: `show_line(line: Dictionary, prompt_label: Label = null) -> void`

- [ ] **Step 1: ปรับ scene tree ให้ prompt อยู่ใน Box**

เปลี่ยน `Box/Margin/TextLabel` เป็น:

```text
Box/Margin/VBox
├── TextLabel
└── ContinueLabel
```

ใช้ `VBoxContainer` separation 8, `ContinueLabel` font Sarabun 14 px สี `Color(0.35, 0.24, 0.13, 0.75)` และ `horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT` แบบ Chapter 1 ลด padding ภายในให้เพียงพอกับลาย NinePatch แต่ไม่บังคับความสูงของ TextLabel

- [ ] **Step 2: เปลี่ยน Box เป็น center-bottom anchors**

กำหนด anchor ทั้งซ้าย/ขวาเป็น `0.5`, anchor บน/ล่างเป็น `1.0` และให้ script เป็นผู้ตั้ง offsets จากขนาดที่คำนวณ โดยคง bottom gap 24 px และ NameTag centered เหนือ Box

- [ ] **Step 3: เพิ่ม reference และ lifecycle สำหรับ responsive layout**

ใน presenter script เพิ่ม constants และ node references:

```gdscript
const MIN_BOX_WIDTH := 480.0
const MAX_BOX_WIDTH_RATIO := 0.84
const BOTTOM_GAP := 24.0
const HORIZONTAL_CONTENT_PADDING := 236.0

@onready var _text_label: Label = $Box/Margin/VBox/TextLabel
@onready var _continue_label: Label = $Box/Margin/VBox/ContinueLabel

func _ready() -> void:
	resized.connect(_refresh_layout)
```

เก็บ spoken text ล่าสุดไว้และเรียก `_refresh_layout()` เมื่อ resized เฉพาะตอน Box แสดงอยู่

- [ ] **Step 4: คำนวณความกว้างจากฟอนต์จริงและจำกัดตาม viewport**

อ่าน font/font_size จาก `TextLabel.label_settings`, ใช้ `font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x`, บวก content padding แล้ว clamp ระหว่างค่าขั้นต่ำกับ `size.x * MAX_BOX_WIDTH_RATIO` จากนั้นกำหนดความกว้าง TextLabel ตาม content width เพื่อให้ Godot คำนวณ wrap จริง

- [ ] **Step 5: คำนวณความสูงหลัง wrap และตั้ง offsets แบบกึ่งกลางด้านล่าง**

หลัง layout update ใช้ `TextLabel.get_minimum_size().y`, ความสูง ContinueLabel, VBox separation และ margin/padding เพื่อหาความสูง Box แล้วกำหนด:

```gdscript
_box.offset_left = -box_width * 0.5
_box.offset_right = box_width * 0.5
_box.offset_bottom = -BOTTOM_GAP
_box.offset_top = -BOTTOM_GAP - box_height
```

ต้องรักษาความสูงขั้นต่ำของ NinePatch และเพิ่มความสูงเมื่อข้อความ wrap โดยไม่ใช้จำนวนตัวอักษรเป็นตัวประมาณ

- [ ] **Step 6: ย้าย prompt ระหว่าง spoken/narration โดยรักษาข้อความ dynamic**

ใน `show_line()`:

```gdscript
if is_spoken:
	_continue_label.text = prompt_label.text if prompt_label != null else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	_continue_label.visible = true
	if prompt_label != null:
		prompt_label.visible = false
	_fit_spoken_box()
else:
	_continue_label.visible = false
	if prompt_label != null:
		prompt_label.visible = true
		_style_prompt(prompt_label, false)
```

ไม่เรียก style dark กับ prompt ภายนอกใน spoken modeอีก เพราะ node นั้นถูกซ่อนแล้ว

- [ ] **Step 7: รันทดสอบจน GREEN และ refactor โดยไม่เปลี่ยน behavior**

Run:

```bash
bash tests/run_cutscene_dialogue_presenter_tests.sh
```

Expected: exit code `0`; short box แคบ/เตี้ยกว่า long box, prompt อยู่ภายใน, Box centered และ narration คืน external prompt

- [ ] **Step 8: Commit implementation**

```bash
git add scenes/ui/cutscene_dialogue_presenter.gd scenes/ui/cutscene_dialogue_presenter.tscn
git commit -m "feat: fit cutscene dialogue box to text"
```

---

### Task 3: ตรวจทุก Chapter และป้องกัน prompt regression

**Files:**
- Modify: `tests/test_cutscene_dialogue_integration_runtime.gd`
- Test: `tests/run_cutscene_dialogue_integration_tests.sh`

**Interfaces:**
- Consumes: all 12 presenter instances listed in `SCENE_DIALOGUE_PATHS`
- Verifies: internal prompt mirrors each Cutscene's existing external prompt text

- [ ] **Step 1: ขยาย `_expect_spoken()` ให้ตรวจ layout/prompt จริง**

หลังเรียก `_show_dialogue()` และรอหนึ่ง frame ให้หา prompt sibling ของ presenter (`ContinuePrompt` หรือ `PostBattlePrompt`) แล้วตรวจ:

```gdscript
var internal_prompt := presenter.get_node("Box/Margin/VBox/ContinueLabel") as Label
_expect(not external_prompt.visible, "%s hides external spoken prompt" % cutscene.name)
_expect(internal_prompt.text == external_prompt.text, "%s preserves dynamic prompt text" % cutscene.name)
_expect(box.get_global_rect().encloses(internal_prompt.get_global_rect()),
	"%s keeps prompt inside dialogue frame" % cutscene.name)
```

- [ ] **Step 2: เพิ่ม spoken representative ให้ครบทุก scene ที่มี spoken lines**

ใช้ dialogue index จริงของ Chapter 2–9 เพื่อยืนยัน shared presenter behavior โดยไม่แก้ข้อมูลบทพูด สลับ narration/spoken ในฉากที่มีทั้งสองชนิดเพื่อยืนยัน prompt ภายนอกกลับมาแสดง

- [ ] **Step 3: รัน presenter และ integration tests**

```bash
bash tests/run_cutscene_dialogue_presenter_tests.sh
bash tests/run_cutscene_dialogue_integration_tests.sh
```

Expected: ทั้งสอง runner exit code `0` และทุก path ใน `SCENE_DIALOGUE_PATHS` ยังใช้ presenter กลาง

- [ ] **Step 4: Commit integration coverage**

```bash
git add tests/test_cutscene_dialogue_integration_runtime.gd
git commit -m "test: verify responsive dialogue across cutscenes"
```

---

### Task 4: ตรวจภาพและ regression ทั้งโปรเจกต์

**Files:**
- Modify if evidence requires: `scenes/ui/cutscene_dialogue_presenter.gd`
- Modify if evidence requires: `scenes/ui/cutscene_dialogue_presenter.tscn`
- Test: Cutscene runners under `tests/`

**Interfaces:**
- Verifies final UI at 1920×1080 and one narrower viewport

- [ ] **Step 1: Render representative short and long spoken lines**

ใช้ runtime harness แสดง `พี่น้องวานรทั้งหลาย!` และประโยคยาวที่ wrap ที่ 1920×1080 และ 1280×720 บันทึก screenshot ลง `/tmp` เพื่อไม่เพิ่ม artifact ใน repository

- [ ] **Step 2: ตรวจภาพจริง**

ยืนยันว่า Box กึ่งกลางด้านล่าง, กรอบสั้นลดทั้งกว้าง/สูง, ประโยคยาวไม่ล้น, NameTag ไม่ทับข้อความ, prompt อยู่เหนือขอบล่างและไม่มีข้อความ external ซ้อน

- [ ] **Step 3: ถ้าพบปัญหา ให้เพิ่ม RED assertion ก่อนปรับค่าระยะ**

ทุกการปรับ padding/minimum size ต้องมี assertion ที่ล้มเหลวจากภาพ/geometry ที่พบ แล้วรัน presenter test ให้ RED ก่อนแก้ implementation

- [ ] **Step 4: รัน regression tests**

```bash
bash tests/run_cutscene_dialogue_presenter_tests.sh
bash tests/run_cutscene_dialogue_integration_tests.sh
bash tests/run_cutscene_dialogue_content_tests.sh
```

จากนั้นรัน test runners Cutscene อื่นที่ `rg --files tests -g 'run*cutscene*.sh'` พบ และโหลด project headless:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --quit --path .
```

Expected: exit code `0`, ไม่มี parse error หรือ test regression

- [ ] **Step 5: ตรวจ diff และสถานะ Git**

```bash
git diff --check
git status --short
git log --oneline -5
```

Expected: ไม่มี whitespace error และไม่มีไฟล์นอกขอบเขต

- [ ] **Step 6: Commit visual adjustment เฉพาะเมื่อมีการแก้หลังตรวจภาพ**

```bash
git add scenes/ui/cutscene_dialogue_presenter.gd scenes/ui/cutscene_dialogue_presenter.tscn tests/test_cutscene_dialogue_presenter_runtime.gd
git commit -m "fix: polish responsive cutscene dialogue spacing"
```
