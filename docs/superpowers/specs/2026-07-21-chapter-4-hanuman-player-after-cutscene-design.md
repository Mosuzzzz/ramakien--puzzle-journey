# Chapter 4 Hanuman Player After Cutscene Design

## Goal

Keep Phra Ram as the playable character while the Chapter 4 cutscene is active, then replace him with Hanuman when the cutscene finishes or is skipped.

## Design

- Attach a focused Chapter 4 controller to the Chapter 4 scene root.
- Preload `res://scenes/player/hanuman_player.tscn` in that controller.
- Expose an idempotent `switch_player_to_hanuman()` method.
- Preserve the existing player's position, remove the Phra Ram instance, and add Hanuman as `YSortRoot/Player` at the same position.
- Call the controller method from the shared Chapter 4 cutscene finish path before gameplay is unpaused.
- Use the same finish path for normal completion and the skip button.
- Leave portals, map content, and shared player scenes unchanged.

## Verification

- Confirm Chapter 4 starts with `res://scenes/player/player.tscn`.
- Confirm the cutscene finish path calls `switch_player_to_hanuman()` once.
- Confirm the replacement is named `Player` and keeps the previous position.
- Confirm normal completion and skipping both unpause after replacement.
- Run structural regression checks and `git diff --check`; run Godot headless validation if an executable is available.
