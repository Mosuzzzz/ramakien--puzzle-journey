# Replace Background Music Design

## Goal

Replace the game's existing normal background track with the user-provided
`sound.mp3` while preserving all current music behavior.

## Scope

- Replace `assets/audio/music/background.mp3` with the contents of
  `/Users/siwakornbundi/Downloads/sound.mp3`.
- Keep the destination filename and resource path unchanged so Chapters 1–9,
  menus, and existing music transitions continue using the same integration.
- Preserve current menu/gameplay volume levels, looping, audio buses, fade
  behavior, and boss-music behavior.
- Do not change sound effects or `boss_fight.mp3`.

## Import and Verification

- Run Godot's headless editor import so the new MP3 is reimported.
- Verify the destination file matches the supplied source by SHA-256.
- Run the AudioManager test and the full existing audio test suite.
- Confirm `git diff --check` succeeds and review the final Git status.

## Success Criteria

- The normal background resource resolves to the newly supplied audio data.
- Existing background looping and volume logic still pass automated tests.
- Boss music and all sound-effect tests remain unaffected.
