# Menu, Chapter Music, and Thosakan Jump Audio Design

## Goal

Make the existing background track audible on the game's menu screens while keeping it quieter during gameplay so sound effects remain clear.
Synchronize Thosakan's jump-attack sound with the instant the attack damages the player.

## Behavior

- The existing `Background.mp3` track plays on the home page, settings page, and save/load screens at the normal Music bus level.
- After START is pressed, the same track continues through the prologue, Chapter 1–9, chapter subrooms, and chapter cutscenes without restarting unnecessarily.
- In the prologue, chapter gameplay, and chapter cutscenes, the music player applies a fixed 40% gain multiplier in addition to the player's Music setting.
- Returning to a menu screen restores the music player to 100% of the player's Music setting.
- Master and SFX levels are unchanged.
- An empty scene path during a scene transition preserves both playback and the current gain until the destination scene becomes available.
- Thosakan's `Jump throw.mp3` does not play when the jump begins. It plays exactly once when the boss reaches the player and calls the player's damage method.
- If a jump is cancelled before impact or the player becomes invalid, the jump sound does not play.

## Implementation Boundary

`AudioManager` remains the single owner of background playback. Scene-path classification will determine two independent properties:

1. Whether background music should play.
2. Whether the Music player uses menu gain (100%) or chapter gain (40%).

No scene receives its own background player, avoiding duplicated music and restarts during transitions. The user's saved Music slider value remains unchanged; the 40% chapter multiplier is applied only to the background player.

Thosakan's jump cue remains an SFX owned by `AudioManager`, but its trigger moves from `_begin_jump_attack()` to `_begin_jump_impact()`, immediately next to the successful player-damage call. The existing `_jump_damage_done` guard prevents duplicate damage and duplicate impact audio.

## Scene Classification

- Menu music at 100%: paths under `res://scenes/homepage/`. The save/load interface is an Autoload overlay, so it inherits the level of the scene underneath it.
- Gameplay music at 40%: `res://scenes/prologue/prologue.tscn`, paths under `res://scenes/chapter_`, and paths under `res://scenes/cutscene/chapter_`.
- Other non-empty scene paths stop the background track, preserving the existing behavior for unrelated scenes.

## Verification

Automated runtime tests will verify:

- Home page starts or keeps the background track and applies 100% player gain.
- Chapter 1 starts or keeps the same track and applies 40% player gain.
- Starting the prologue keeps the same track and applies 40% player gain.
- Chapter subrooms and chapter cutscenes retain the 40% gain.
- Returning to the home page restores 100% gain.
- Empty transition paths do not stop or alter currently playing music.
- SFX bus volume is not changed by scene synchronization.
- Beginning Thosakan's jump produces no `jump_throw` event.
- A successful Thosakan jump impact produces one `jump_throw` event at the damage boundary.

The full existing audio test suite and a headless project smoke test will run after the change.
