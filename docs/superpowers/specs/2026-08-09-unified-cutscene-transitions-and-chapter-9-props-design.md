# Unified Cutscene Transitions and Chapter 9 Props Design

## Goal

Make every cutscene and chapter change use a consistent one-second fade to black followed by a one-second reveal, while avoiding a duplicate fade when a chapter change immediately opens a cutscene. Add the four supplied Chapter 9 prop textures to the Chapter 9 scene so they can be positioned later in the Godot editor.

## Scope

- Opening a cutscene inside the current chapter.
- Closing or skipping a cutscene and returning to gameplay.
- Changing between chapter scenes through chapter portals or other story-driven scene changes.
- Combining a chapter change and its opening cutscene into one continuous transition.
- Adding all four textures under `res://assets/props/chapter9/` to `chapter_9.tscn`.
- Room entrance and exit transitions remain unchanged because they already have a separate door interaction and sound flow.
- Existing fades between panels inside multi-panel cutscenes remain unchanged.

## Recommended Architecture

Add one persistent screen-transition service at the root of the running game. The service owns a top-level `CanvasLayer` and black `ColorRect`, processes while the tree is paused, blocks duplicate requests, and exposes these operations:

- Fade from clear to black over 1.0 second.
- Fade from black to clear over 1.0 second.
- Change scene while the screen is black.
- Mark a scene handoff so an opening cutscene can reuse the existing black screen instead of starting a second fade.

Cutscene scripts use a small shared transition helper or the service API instead of maintaining separate opening and closing sequences. Their dialogue, image-panel transitions, quest updates, and completion state remain owned by each cutscene.

## Transition Flows

### Cutscene opened in the current chapter

1. Lock gameplay and cutscene advance input.
2. Fade the current gameplay view to black over 1.0 second.
3. Prepare and reveal the cutscene content behind the black overlay.
4. Fade from black to the cutscene over 1.0 second.
5. Enable cutscene input.

### Cutscene closed or skipped

1. Lock cutscene input.
2. Fade the cutscene to black over 1.0 second.
3. Apply cutscene completion state, remove the cutscene UI, and restore gameplay while black.
4. Fade from black to gameplay over 1.0 second.
5. Restore gameplay input.

### Chapter change without an opening cutscene

1. Accept the portal or story transition once and lock further input.
2. Save the destination spawn, health, and autosave data using the current behavior.
3. Fade to black over 1.0 second.
4. Change the chapter scene while black and wait until it is ready.
5. Fade into gameplay over 1.0 second.

### Chapter change followed by an opening cutscene

1. Fade the old chapter to black over 1.0 second.
2. Change the chapter scene while black.
3. The new chapter prepares its opening cutscene behind the persistent black overlay.
4. The opening cutscene consumes the handoff marker and skips its own fade-to-black step.
5. Fade from black directly into the cutscene over 1.0 second.

There is no visible gameplay frame and no duplicate black transition between the chapter change and the cutscene.

## Input and Pause Safety

- The transition overlay ignores game pause and remains active while a cutscene pauses the tree.
- An in-progress flag rejects repeated E presses, mouse clicks, automatic portal activation, and repeated skip requests.
- Player movement and running audio are stopped before fading.
- The overlay releases input only after the reveal completes.
- If the destination has no opening cutscene because it was already completed or restored from a save, the handoff falls back to revealing normal gameplay.

## Chapter 9 Props

Add these existing textures as four `Sprite2D` nodes:

- `res://assets/props/chapter9/image-removebg-preview.png`
- `res://assets/props/chapter9/image-removebg-preview (1).png`
- `res://assets/props/chapter9/image-removebg-preview (2).png`
- `res://assets/props/chapter9/image-removebg-preview (3).png`

Place them under a dedicated `Chapter9Props` `Node2D` in `scenes/chapter_9/chapter_9.tscn`. Give each node a distinct descriptive staging name, keep them free of scripts and collision shapes, and stage them with separated temporary positions so the user can select and arrange them in the editor. This work does not assign gameplay behavior or final placement.

## Testing

- Transition unit/runtime tests verify the 1.0-second durations, busy-state input guard, and scene-handoff state.
- Portal tests verify chapter transitions use the central service while room transitions retain their existing behavior.
- Cutscene hook tests verify opening, completion, and skip paths use the shared transition flow.
- A Chapter 9 scene test verifies all four prop textures are referenced and instantiated beneath `Chapter9Props` without collision or scripts.
- Run the complete existing Godot test suite after the focused tests pass.

## Acceptance Criteria

- Every cutscene fades to black for 1 second before appearing and reveals for 1 second.
- Every cutscene fades to black for 1 second before returning to gameplay and reveals gameplay for 1 second.
- Chapter changes fade out and in over 1 second each.
- A chapter change immediately followed by a cutscene performs only one fade-out and one fade-in.
- Repeated input cannot trigger overlapping transitions.
- Existing story state, save behavior, spawn positions, audio, and room transitions continue to work.
- All four Chapter 9 prop images are available as editable Sprite2D nodes in the Chapter 9 scene.
