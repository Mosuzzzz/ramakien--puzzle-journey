# Boss Name, Quest Title, and Web Magic-Trail Icon Design

## Goal

Polish three related gameplay UI issues without changing quest data or gameplay flow:

1. Make the Miyarap name larger and visually centered inside the boss health bar.
2. Keep the existing two-column quest page while preventing awkward one- or two-character orphan lines in quest titles across all chapters.
3. Ensure the Chapter 4 magic-trail icon is included and visible in Web exports deployed to itch.io.

## Current Findings

- `BossName` is a viewport-anchored sibling of `BossBar`, uses a 15 px font, and is positioned with independent offsets. Its placement is therefore only approximately aligned with the bar artwork.
- Both quest-title labels use automatic wrapping inside unequal columns. Thai titles without spaces can break at arbitrary character boundaries, producing orphan fragments such as `ดา`.
- `scenes/props/magic_trail.tscn` references `ChatGPT_Image_26_ก.ค._2569_22_08_37-removebg-preview.png`. Git contains its `.import` metadata but not the source PNG. The local editor can use the existing `.godot` import cache, whereas a clean Web export cannot recreate or package the texture.

## Design

### Miyarap Boss Name

- Make `BossName` a child of `BossBar` so its layout is relative to the health-bar control rather than the viewport.
- Size the label to the inner red-bar region and center it horizontally and vertically.
- Use Sarabun Bold at 24 px with the existing light text and dark shadow treatment.
- Keep the bar textures, health behavior, and HUD visibility flow unchanged.

### Responsive Quest Titles

- Preserve the existing two-column page: quest list on the left, selected quest title and detail on the right.
- Keep canonical quest names unchanged for state, snapshots, save/load, and comparisons. Formatting applies only to label display text.
- Change the column stretch ratios from 42/58 to 36/64 and reduce their separation from 30 px to 24 px, giving the detail title more room while retaining a readable quest-list column.
- Add one central title-layout routine in `quest_log.gd`:
  - attempt the normal font size first (17 px left and 24 px right);
  - reduce the font only as far as a readable minimum (15 px left and 20 px right) when that keeps the title on one line;
  - when wrapping is still required, choose the legal Thai line-break position nearest the visual midpoint;
  - reject breaks that leave either line shorter than 35 percent of the title's measured width;
  - vertically center two-line titles and give their containers enough height.
- Apply the routine to both the left entry title and right detail title whenever `set_quest()` or `restore_pending()` updates the active quest.
- Completed-state colors and notification behavior remain unchanged.

### Web-Safe Magic-Trail Icon

- Recover the currently intended icon from the local Godot import cache.
- Save it as the tracked source asset `assets/ui/icon/magic_trail_icon.png`.
- Update `magic_trail.tscn` to reference the new source path.
- Regenerate/import the asset through Godot and verify a clean Web export resolves and packages it.
- Do not replace the artwork or change the magic-trail interaction behavior.

## Testing

Follow test-driven development for each behavior:

- Boss HUD runtime test: assert the name is parented to the bar, uses the intended readable font size, and remains centered within the bar region.
- Quest layout runtime test: exercise representative short and longest quest names from every chapter; assert canonical snapshot text is unchanged, font size stays above the minimum, and wrapped titles do not produce short orphan lines.
- Magic-trail asset test: fail when the referenced source texture is missing or not tracked; then verify the new scene reference loads.
- Web export smoke test: export with the existing Web preset when templates are available and confirm the project exports without a missing magic-trail texture.
- Visual QA: capture the boss HUD and quest page at the project’s wide viewport and at 1024×768, checking alignment, readability, and balanced wrapping.
- Run the complete existing test suite after focused tests pass.

## Non-Goals

- No changes to quest wording, quest progression, save data, combat balance, health values, or the overall two-column quest-page design.
- No redesign of boss-bar artwork or the Chapter 4 magic-trail artwork.
- No deployment to itch.io as part of this change; the local Web export will be made deployment-safe and verified.
