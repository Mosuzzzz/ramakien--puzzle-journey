# Chapter 6: Lanka Gate Opening Cutscene Design

## Goal

Add an opening cutscene directly to `scenes/chapter_6/chapter_6.tscn`. It must play immediately every time Chapter 6 is entered, introduce the sealed gate of Lanka, and return control to Phra Ram in the existing Chapter 6 gameplay scene when it ends or is skipped.

## Scope

- Use `assets/cutscene/chapter_6/ChatGPT Image 22 ก.ค. 2569 20_29_33.png` as the full-screen cutscene image.
- Display the title `ประตูกรุงลงกา` in the existing ornate title banner style used by the Chapter 4 and Chapter 5 cutscenes.
- Pause gameplay and consume movement/gameplay input while the cutscene is active.
- Advance narration with the `E` key and provide the existing skip control.
- Keep the existing Phra Ram player, portals, enemies, map, and Chapter 6 spawn positions unchanged.
- Do not add character portraits, dialogue animation, or additional scene transitions beyond the requested opening cutscene.

## Presentation and Flow

1. Chapter 6 loads with the existing gameplay scene behind the cutscene layer.
2. A full-screen fade darkens to black over one second.
3. The cutscene image, dim overlay, title banner, narration, and continue prompt become visible.
4. The black overlay fades away over one second, revealing the cutscene.
5. The player presses `E` to advance through four readable narration entries:
   1. `คำบรรยาย: หลังจากหนุมานช่วยพระรามกลับมาจากไมยราพได้สำเร็จ พระรามก็เดินทางต่อไปยังกรุงลงกาเพื่อช่วยนางสีดา`
   2. `คำบรรยาย: เมื่อเดินทางมาถึง พบว่ากรุงลงกาถูกปกป้องด้วยกำแพงขนาดมหึมา`
   3. `คำบรรยาย: ประตูเมืองปิดสนิทด้วยอาคมโบราณ ไม่มีผู้ใดสามารถทำลายหรือผลักประตูให้เปิดออกได้`
   4. `คำบรรยาย: พระรามจึงต้องออกค้นหากลไกโบราณ เพื่อปลดผนึกอาคมของประตูเมืองให้ได้`
6. On the final entry, the prompt changes to indicate that pressing `E` starts Chapter 6.
7. Pressing `E` on the final entry, or pressing the skip control at any point, closes the cutscene, unpauses the scene tree, and returns control to the existing Phra Ram instance.

## Architecture

### Scene Nodes

Add a high-layer `CanvasLayer` to `chapter_6.tscn`, containing one full-rect `Control` managed by a focused Chapter 6 cutscene script. Its children are:

- `CutsceneImage`: full-screen `TextureRect` using the new Chapter 6 image.
- `BackgroundDim`: translucent black overlay that improves text readability.
- `TitleBanner/Title`: ornate banner and the title `ประตูกรุงลงกา`.
- `Dialogue`: centered Thai narration with outline and shadow.
- `ContinuePrompt`: `E` navigation instruction.
- `FadeOverlay`: full-screen black overlay used for the one-second fade-in and one-second reveal.

The cutscene layer uses process-always behavior so its tween, keyboard input, and skip button continue functioning while gameplay is paused.

### Script Responsibilities

Create a dedicated Chapter 6 opening cutscene script that:

- Starts automatically in `_ready()`.
- Pauses the scene tree before gameplay can proceed.
- Runs the two one-second intro fades.
- Tracks the current narration index.
- Fades narration text briefly between entries.
- Integrates with the existing reusable `cutscene_skip.gd` helper.
- Uses a completion guard so skip and final-key input cannot finish twice.
- Always unpauses the scene tree when the cutscene exits, including cleanup during scene changes.

The script does not change scenes or replace the player. Chapter 6 gameplay resumes in place.

## Input and State Safety

- Mouse events remain available to the skip button.
- Non-mouse events are marked handled while the cutscene is active, preventing movement and attacks from reaching gameplay nodes.
- Input is ignored while a fade or dialogue transition is running.
- The cutscene is intentionally replayed whenever Chapter 6 is newly loaded; no persistent completion flag is stored.

## Verification

Static tests will verify that:

- `chapter_6.tscn` references the requested image, title banner, fonts, and Chapter 6 cutscene script.
- The cutscene node hierarchy and full-screen layer are present.
- The four narration entries and title are exact.
- The script pauses gameplay, supports `E`, attaches the skip helper, performs both one-second fades, and unpauses on completion.
- Existing Phra Ram, Chapter 5 portal, and Chapter 7 portal definitions remain present.

If a Godot executable is available, also load or run Chapter 6 to confirm there are no parser/resource errors. Otherwise, report the static verification result and the lack of a local Godot CLI separately.
