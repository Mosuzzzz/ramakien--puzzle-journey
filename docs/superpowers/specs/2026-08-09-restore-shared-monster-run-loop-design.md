# Restore Shared Ordinary-Monster Run Loop

## Goal

Restore the ordinary monster movement sound to the behavior used before footsteps were synchronized to individual animation frames. This removes overlapping one-shot sounds that can continue after a monster has been defeated.

## Scope

- Applies only to ordinary monsters implemented by `scenes/props/mob.gd`.
- Miyarap and Thosakan retain their existing bespoke movement audio.
- The player, Hanuman, Phalak, and Sida movement audio is unchanged.

## Behavior

- Ordinary monsters share one looping `monster_run` player managed by `AudioManager`.
- The loop starts when at least one living ordinary monster is actively walking.
- The loop continues while any registered ordinary monster is walking.
- A monster unregisters when it stops, attacks, becomes unable to move, is defeated, or exits the scene tree.
- The shared loop stops immediately when no registered walking monster remains.
- Animation-frame footstep callbacks no longer play `monster_run` through the pooled one-shot SFX players.

## Implementation

- Restore `mob.gd` to report movement through `_update_run_audio()` and `_uses_shared_run_audio()`.
- Remove the ordinary-monster frame-contact constants, state, signal connection, and callback introduced for per-step playback.
- Keep the existing weak-reference owner registry and `MonsterRunLoop` player in `AudioManager`.
- Restore looping only for the dedicated `RUN` and `MONSTER_RUN` streams. `MONSTER_RUN` is then used exclusively by `MonsterRunLoop`, not the one-shot SFX pool.
- Retain explicit unregister calls on defeat and `_exit_tree()` as lifecycle safeguards.

## Testing

- Replace frame-contact assertions with lifecycle assertions showing that an ordinary monster uses shared run audio.
- Assert `monster_run` is a looping MP3 for the dedicated shared loop.
- Assert one walking owner starts the loop, stopping/removing the last owner stops it, and removing one of multiple owners does not stop it prematurely.
- Run the focused audio tests and the complete Godot test-runner suite.

## Success Criteria

- Ordinary monster movement sounds like the pre-frame-sync implementation.
- Defeating the last moving ordinary monster leaves no monster movement sound playing.
- No behavior changes occur for Miyarap or Thosakan.
