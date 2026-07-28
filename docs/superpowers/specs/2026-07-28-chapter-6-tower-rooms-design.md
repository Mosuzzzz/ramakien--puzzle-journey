# Chapter 6 Tower Rooms Design

## Goal

Add two enterable tower rooms to the Chapter 6 map. The left tower opens the
room using `ChatGPT Image 27 ก.ค. 2569 20_32_50.png`, and the right tower opens
the room using `ChatGPT Image 27 ก.ค. 2569 20_33_55.png`.

Players can enter and leave each room using the project's existing interaction
controls: press E while nearby or click the interaction area.

## Architecture

Reuse `scenes/props/portal.tscn` for all room transitions. Add one portal to
each tower entrance in `scenes/chapter_6/chapter_6.tscn`, and create one
standalone scene for each room:

- `scenes/chapter_6/chapter_6_room_left.tscn`
- `scenes/chapter_6/chapter_6_room_right.tscn`

Each room scene contains:

- Its assigned room image as a `Sprite2D` background.
- A player instance and camera.
- Static collision boundaries that keep the player inside the walkable floor.
- An `ExitPortal` that returns to the Chapter 6 map.

This follows the existing room and portal patterns and does not introduce a new
interaction system.

## Scene Transitions

The Chapter 6 map contains:

- `LeftTowerRoomPortal`, targeting `chapter_6_room_left.tscn`.
- `RightTowerRoomPortal`, targeting `chapter_6_room_right.tscn`.

Each entrance portal has a Thai prompt explaining that E enters the tower.
Each room's exit portal has a Thai prompt explaining that E leaves the room.
Click interaction remains available through the existing portal behavior.

Portal `target_spawn` values preserve spatial continuity:

- Leaving the left room returns the player near the left tower entrance.
- Leaving the right room returns the player near the right tower entrance.

The room entrance and exit trigger sizes are restricted to their visible
doorway areas to avoid accidental transitions.

## Chapter 6 Intro State

Entering a room and returning must not replay the Chapter 6 opening cutscene.
Add a persistent runtime flag named `chapter_6_intro_played` to `GameState`.
The Chapter 6 cutscene checks and sets this flag, and starting a new game resets
it to `false`.

## Camera and Collision

Both room images are 1254 by 1254 pixels. Each room camera is constrained to
the image bounds and uses a zoom appropriate for the existing player viewport.
The player begins on the lower walkable floor near the entrance.

Collision shapes outline the room's visible walls and large central obstacles.
The collision geometry should prioritize clear movement and prevent leaving the
artwork bounds; it does not need pixel-perfect tracing of decorative objects.

## Error Handling

All target scene paths must point to existing `.tscn` files. Room scenes must
remain loadable independently in Godot. The existing portal script owns input
handling and scene changes, so the new scenes require no custom transition
script unless camera configuration cannot be expressed directly in the scene.

## Testing

Use test-driven development for the implementation:

1. Run `tests/test_chapter_6_tower_rooms.sh` before implementation and confirm
   it fails because the room scenes and portals do not exist.
2. Implement the minimum scene and state changes needed to satisfy that
   contract.
3. Add or extend a Godot runtime test to load the Chapter 6 map and both room
   scenes, verify portal targets and spawn positions, and confirm every scene
   instantiates without parser or missing-resource errors.
4. Run the Chapter 6-specific tests, then the project's complete available test
   suite.

## Acceptance Criteria

- The player can enter the left tower with E or a click and sees the left room
  image.
- The player can enter the right tower with E or a click and sees the right
  room image.
- The player can walk within both rooms without leaving the visible map.
- Each room can return the player to the corresponding tower entrance.
- Returning from either room does not replay the Chapter 6 opening cutscene.
- Existing Chapter 5 and Chapter 7 portals on the Chapter 6 map continue to
  work.
- Both room scenes load without missing-resource or parser errors.
