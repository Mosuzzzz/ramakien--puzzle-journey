# Chapter 3 Tree Cutscene and Synced Monster Footsteps Design

## Goal

Fix the Chapter 3 great-tree event so its post-battle cutscene remains available after re-entering the chapter, and make every ordinary monster footstep sound once per visible foot contact instead of using a continuous loop.

## Scope

- Chapter 3 intro and post-battle cutscene ownership.
- Ordinary monsters that use `scenes/props/mob.gd`.
- The existing `Giant King.mp3` ordinary-monster footstep asset.
- Regression coverage for both behaviors.

Miyarap and Thosakan keep their existing movement-audio behavior. Player characters and friendly story characters are unchanged.

## Chapter 3 Cutscene Design

On Chapter 3 re-entry, the intro cutscene must remove or disable only its own `Chapter3Cutscene` control. It must not free `Chapter3CutsceneLayer`, because that layer also owns `PostBattleCutscene`.

When the restored resting quest is completed at the great tree, Chapter 3 will validate that the post-battle cutscene instance still exists before invoking `show_cutscene`. The normal scene structure must keep that instance alive, while the validity check prevents a hard runtime error if a malformed scene is loaded.

The regression test will mirror the real scene hierarchy: intro and post-battle cutscenes are siblings under the same `Chapter3CutsceneLayer`. It will verify that skipping the already-played intro preserves the post-battle cutscene and that the tree event can invoke it.

## Ordinary-Monster Footstep Design

The continuous ordinary-monster `MonsterRunLoop` will no longer be used by `mob.gd`. Each ordinary monster will listen for its own `AnimatedSprite2D.frame_changed` event and emit a one-shot `monster_run` sound only when all of these conditions are true:

- The monster is alive and allowed to move.
- Its velocity is non-zero.
- The active animation is the resolved walking animation.
- The new frame is one of the configured foot-contact frames.
- That frame has not already emitted a sound during the current animation cycle.

The 12-frame `walk` animation will use two contact frames per cycle, one for each foot. The exact frame indices will be selected from the sprite poses and captured as named constants so they can be calibrated without changing movement logic.

Every contact uses `AudioManager.play_sfx(AudioManager.MONSTER_RUN)`. The existing pooled SFX players allow different monsters to overlap naturally. Stopping, attacking, dying, pausing, or leaving the scene produces no additional step sound because no contact-frame event is accepted in those states.

## Error Handling

- A missing or freed post-battle cutscene is handled without calling a stale instance; a diagnostic error is emitted instead of freezing in the debugger.
- A missing walk animation or missing audio stream remains silent and does not interrupt gameplay.
- Repeated `frame_changed` emissions for the same frame do not duplicate a step.

## Tests

1. A Chapter 3 shared-layer regression test fails if re-entry frees `PostBattleCutscene`.
2. The same test confirms the great-tree transition calls `show_cutscene` after re-entry.
3. An ordinary-monster audio test confirms only configured walking contact frames emit `monster_run`.
4. The audio test confirms one contact from two monsters produces two observable SFX events, proving overlap is not globally suppressed.
5. Idle, attack, zero velocity, and repeated same-frame cases remain silent.
6. Existing Chapter 3, audio-manager, world-movement, and full project runner suites remain green.

## Success Criteria

- Returning from Chapter 2 to Chapter 3 and reaching the great tree no longer raises `Cannot call method 'call' on a previously freed instance`.
- The post-battle cutscene still starts normally.
- Each ordinary monster produces exactly one sound per foot contact, with multiple monsters able to sound simultaneously.
- Miyarap and Thosakan audio behavior is unchanged.
