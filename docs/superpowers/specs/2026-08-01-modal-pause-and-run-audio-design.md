# Modal Pause and Run Audio Design

## Goal

Stop gameplay and movement audio whenever a cutscene, dialogue, narration, quiz, or puzzle modal is active. Restore gameplay after the foreground interaction closes, including immediate movement and run audio when the player is still holding a movement key.

## Root Cause

The player registers itself with `AudioManager` while moving. Cutscenes and quiz modals then pause the `SceneTree`, which stops the player's physics callback before it can unregister itself. `AudioManager` uses `PROCESS_MODE_ALWAYS`, so its looping run player continues while the rest of the game is paused.

Ordinary `Dialogue` currently checks input in the player scripts but does not pause the `SceneTree`. That stops direct player movement while the dialogue is open, but it does not consistently freeze enemies, combat, or other world simulation.

## Approved Behavior

- Opening any existing cutscene, question, or puzzle modal stops the run loop immediately.
- Opening ordinary dialogue or narration pauses the game world before displaying the first line.
- Player movement, enemies, combat, and world simulation remain stopped while dialogue is active.
- Foreground UI remains interactive while paused because its existing nodes process in `PROCESS_MODE_ALWAYS`.
- Closing dialogue restores the pause state that existed before it opened.
- If the game was already paused before dialogue opened, closing dialogue must not unpause it.
- Once gameplay resumes, a held movement key is read normally on the next physics frame. The player moves and the run loop starts again without requiring the key to be released.
- Music and non-run effects are not muted or restarted by this change.
- Existing question correctness, cutscene timing, scene transitions, and pause-menu behavior remain unchanged.

## Architecture

### Central Run-Audio Pause Guard

`AudioManager` remains the single owner of the shared run loop. During its always-processing update, it checks `SceneTree.paused` before pruning or refreshing movement owners. When paused, it calls the existing `stop_run_loop()` operation, which stops the audio player and clears all registered movement owners.

Clearing the owners is intentional. A stale owner must never restart the run loop after unpausing. Active characters register again only when their next movement update observes real movement.

### Dialogue Pause Ownership

`DialogueManager` records whether the tree was already paused immediately before starting a new dialogue or narration. It then pauses the tree and displays the foreground UI.

When the dialogue closes, it restores the recorded previous state instead of unconditionally setting `paused = false`. This prevents a dialogue opened while another pause source is active from incorrectly resuming gameplay.

The dialogue singleton already uses `PROCESS_MODE_ALWAYS`, so E presses, left clicks, line advancement, and final close continue to work during the pause.

### Existing Cutscenes and Modal Questions

Existing cutscenes, quiz screens, matching puzzles, and Chapter 6 puzzle modals already pause the tree. They do not need individual run-audio calls. The central AudioManager guard handles their run-loop cleanup on the first paused processing frame, reducing duplicated wiring and preventing Chapter-specific omissions.

## Data Flow

1. A moving character registers as a run-audio owner; the run loop plays.
2. A foreground interaction pauses the tree.
3. AudioManager continues processing, detects the paused tree, stops the run loop, and clears all owners.
4. World physics remains frozen while the foreground UI handles input.
5. The interaction closes and restores the appropriate pause state.
6. On the next unpaused physics frame, a held movement input moves the player and registers it again; run audio resumes normally.

## Edge Cases

- Repeated paused frames are idempotent: stopping an already stopped run loop and clearing an empty owner set has no side effects.
- Dialogue calls with an empty line list do not change pause state because no foreground interaction is opened.
- A dialogue opened while already active reuses the original pre-dialogue pause state rather than overwriting it mid-session.
- Dialogue teardown or forced close restores pause state through the same close path.
- Switching scenes still removes movement owners through existing `_exit_tree()` hooks; the central paused guard provides an additional safe boundary.

## Testing

- Extend AudioManager runtime coverage to register a run owner, pause the tree, process the manager, and assert that the run player stops.
- Assert that unpausing alone does not restart the stale run loop.
- Assert that re-registering movement after unpause starts the run loop again.
- Extend story/dialogue runtime coverage to verify dialogue start pauses an unpaused tree and final advance restores it.
- Verify dialogue started while already paused leaves the tree paused after close.
- Run every existing audio test, full Godot project parsing, and a headless main-scene smoke launch.

## Out of Scope

- Replacing all direct pause assignments with a new reference-counted pause service.
- Changing music volume, SFX bus settings, or any sound asset.
- Changing movement controls or requiring movement keys to be released after closing UI.
- Editing the user's uncommitted Chapter 1 scene or unrelated asset deletions.
