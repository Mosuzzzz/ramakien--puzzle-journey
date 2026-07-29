# Chapter 6 Room Return Spawns Design

## Goal

Return the player from either Chapter 6 tower room to a clear point on the
main map, outside the enlarged tower interaction area and outside static
collision geometry.

## Root Cause

Each room's `ExitPortal.target_spawn` controls the player's position after
the main Chapter 6 scene loads:

- The left room currently returns to `Vector2(190, 650)`.
- The right room currently returns to `Vector2(1258, 650)`.

The left value overlaps two static collision shapes. Both values also place
the player at or near their corresponding tower portal. Because the tower
interaction rectangles are now `Vector2(320, 220)`, returning near a portal
can immediately show the entrance prompt again.

## Approved Design

- Set the left room ExitPortal destination spawn to `Vector2(380, 525)`.
- Set the right room ExitPortal destination spawn to `Vector2(1068, 525)`.
- Keep the ExitPortal positions inside the rooms unchanged.
- Keep the main-map tower portal positions and `Vector2(320, 220)`
  interaction sizes unchanged.
- Do not change room collision walls, shared Portal behavior, destination
  scenes, prompt text, or player collision geometry.

The new points sit on the open side of each tower and are horizontally
outside the corresponding portal rectangle. Physics point queries at each
point and around the player's 9-pixel collision radius reported no static
body intersections. The Y coordinate uses an additional clearance margin
above nearby collision geometry that begins around Y 550.

## Data Flow

When the player activates a room ExitPortal, `portal.gd` copies the configured
`target_spawn` into `GameState.next_spawn`. After Chapter 6 loads,
`player.gd` consumes that value, moves the player to the approved clear point,
and resets `GameState.next_spawn` to `Vector2.INF`.

## Verification

Tests will first expect the approved return values and fail against the old
configuration. Runtime coverage will activate each ExitPortal and verify the
player reaches the expected destination. A physics query will check the
player-sized area at each return point for static-body overlap, and the test
will verify that the corresponding tower portal does not immediately detect
the returned player. Focused Chapter 6 tests, the complete test suite, and a
Godot headless editor parse will run after implementation.
