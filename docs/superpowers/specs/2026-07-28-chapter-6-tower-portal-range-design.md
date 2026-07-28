# Chapter 6 Tower Portal Interaction Range Design

## Goal

Make the Chapter 6 left and right tower entrance prompts appear while the
player is still a comfortable distance from each tower instead of requiring
the player to stand immediately beside it.

## Scope

- Change only `LeftTowerRoomPortal` and `RightTowerRoomPortal` in
  `scenes/chapter_6/chapter_6.tscn`.
- Increase each portal's `interaction_size` from `Vector2(150, 160)` to
  `Vector2(320, 220)`.
- Keep the portal positions, destination scenes, destination spawns, prompt
  text, room scenes, and all collision walls unchanged.
- Do not change the shared default size in `scenes/props/portal.gd`, because
  that would affect unrelated portals throughout the game.

## Behavior

Both tower portals use the same rectangular detection area. The wider area
allows the player to approach from the open side of either tower and see
`กด E เพื่อเข้าไปในหอคอย` before touching the tower artwork. Leaving the
detection area hides the prompt as before, and pressing `E` inside the area
continues to enter the configured room.

## Verification

Automated tests will first assert the new `Vector2(320, 220)` configuration
and fail against the old values. Runtime coverage will place the player at a
representative horizontal distance from both tower centers, verify that each
portal detects the player and shows its prompt, then retain the existing
scene-transition checks. The full project test suite and Godot headless parse
will run after implementation.
