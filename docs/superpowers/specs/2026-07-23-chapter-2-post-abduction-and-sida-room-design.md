# Chapter 2 Post-Abduction and Sida Room Design

## Goal

After the Chapter 2 abduction cutscene finishes:

- Return Phra Ram to the Chapter 2 ashram map at a walkable position.
- Keep Sida absent from Chapter 2 because she has been abducted.
- Show Sida in `chapter_8_room.tscn` on the central carpet immediately before the bed platform.

## Root Cause

The chase scene currently stores `GameState.next_spawn = Vector2(1000, 600)` before returning to Chapter 2. That point overlaps the ashram fence/rock collision geometry, so the newly instantiated player can begin the scene embedded in a static collision and appear unable to walk.

The player movement script is not the source of this bug. The chase already clears `movement_locked` and `auto_run_velocity`, and Chapter 2 creates a fresh player instance after the scene change.

## Design

### Chapter 2 Return

Change the post-abduction return spawn to a nearby open point on the ashram path. Do not remove or disable the existing fence collisions.

The same safe return point must be used by both:

- The successful deer chase and abduction flow.
- The failed chase return flow.

Chapter 2 continues to use `GameState.chapter_2_deer_defeated` to remove the golden deer, Sida, and the completed puzzle interaction when the scene reloads. The Chapter 3 portal remains unlocked as it is today.

### Sida in Chapter 8

Instance the existing `res://scenes/props/sida.tscn` scene under the `YSortRoot` of `res://scenes/chapter_8/chapter_8_room.tscn`.

Place Sida on the central carpet immediately before the raised bed platform, outside the platform collision shapes so the player can approach her. Sida is present whenever this room is loaded because Chapter 8 occurs after the abduction in the story.

No new dialogue, quest, interaction prompt, movement behavior, or GameState flag is added in this change.

## Data Flow

1. The deer chase ends.
2. The abduction cutscene plays.
3. The cutscene emits `finished`.
4. Chapter 2 stores a safe `GameState.next_spawn`.
5. The game changes back to `chapter_2.tscn`.
6. Chapter 2 reads the completed-abduction state, removes Sida from the ashram, and unlocks the Chapter 3 route.
7. Much later, entering `chapter_8_room.tscn` displays the separately instanced Sida in front of the bed.

## Testing

Automated scene-contract tests will verify:

- The successful and failed chase returns use the same safe spawn point.
- The old collision-overlapping spawn point is no longer used.
- Chapter 2 still removes Sida after the deer is defeated.
- Chapter 8 room instances `sida.tscn` under `YSortRoot`.
- Sida's room position is in front of the bed and distinct from the player's entrance position.

Godot headless validation will load the affected scenes and check for parse or missing-resource errors attributable to this change.

## Out of Scope

- Chapter 7 opening cutscene work.
- Editing the Chapter 2 fence layout.
- Adding dialogue or rescue logic for Sida in Chapter 8.
- Changing Chapter 8 portals, enemies, or room progression.
