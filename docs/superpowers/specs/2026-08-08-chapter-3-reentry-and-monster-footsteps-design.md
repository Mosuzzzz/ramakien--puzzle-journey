# Chapter 3 Re-entry and Monster Footsteps Design

## Goal

Preserve the unfinished Chapter 3 feather quest when the player returns to
Chapter 2 and later re-enters Chapter 3. Give ordinary monsters their own
walking sound without changing Rama, allied characters, Miyarap, Thosakan, or
any attack and impact sounds.

## Confirmed behavior

- The Chapter 3 introduction still plays only once.
- Leaving Chapter 3 may clear the scene-local quest presentation.
- Re-entering Chapter 3 after the introduction reconstructs the correct quest
  presentation from persistent story and inventory state.
- Collected feathers remain collected. The scene never grants a duplicate
  feather merely because it was reloaded.
- Uncollected feather pickups are visible and interactive again after re-entry.
- Remaining feathers may be assigned new valid spawn points after re-entry;
  preserving their exact previous positions is not required.
- `Giant King.mp3` is used only for the walking loop of ordinary monsters based
  on `mob.gd`.
- Rama, Hanuman, Phalak, Sida, Miyarap, and Thosakan keep their current sounds.
- Miyarap slam, wave, summon, and attack sounds remain unchanged.
- Thosakan footsteps, attacks, jump, heal, and pull sounds remain unchanged.

## Root cause

`chapter_3.gd` currently clears the quest and calls `mark_collected()` on every
feather whenever the scene becomes ready. On the first visit the intro
cutscene subsequently calls `start_feather_quest()`, which restores the
pickups. On later visits `chapter_3_cutscene.gd` detects that the intro already
played and removes itself without calling `start_feather_quest()`. The scene's
local `_feather_quest_started` flag therefore remains false, the quest stays
cleared, and all feather nodes stay hidden even though the persistent inventory
still contains the correct collected count.

Ordinary monsters currently register themselves with the same shared run loop
used by Rama and allied characters, so their movement is indistinguishable by
sound.

## Chapter 3 state restoration

Persistent values remain the source of truth:

- `GameState.chapter_3_intro_played` tells whether the intro is complete.
- `GameState.chapter_3_post_battle_played` tells whether the Chapter 3 story
  sequence is complete.
- `Inv.count("jatayu_feather")`, clamped to `0...3`, is the feather progress.

After Chapter 3 has connected its feather and quiz signals, it restores one of
these states:

| Persistent state | Restored scene state |
| --- | --- |
| Intro has not played | Keep feathers hidden and let the intro finish normally |
| Intro played, fewer than 3 feathers | Start the feather quest, show only the remaining pickups, and display the saved count |
| Intro played, 3 feathers, post-battle not played | Restore the completed feather state and the rest-under-the-tree quest |
| Post-battle played | Keep collected feathers hidden, unlock the Chapter 4 portal, and restore the exit quest |

Restoration reuses the existing `start_feather_quest()`,
`_spawn_remaining_feathers()`, and quest transition methods instead of adding a
second progress calculation. The scene-local idempotency guards continue to
prevent duplicate setup within one scene instance.

## Ordinary-monster walking audio

The audio manager gains a separate ordinary-monster movement sound key mapped
to a project copy of `Giant King.mp3`. It also owns a separate loop player and
owner registry for ordinary monsters. This keeps simultaneous player and enemy
movement independent:

- allied movement owners continue using the existing `run.mp3` loop;
- `mob.gd` instances register and unregister with the new monster loop;
- stopping one monster does not stop the loop while another monster is still
  walking;
- removing or defeating a monster unregisters it so audio cannot remain stuck;
- pausing gameplay or entering modal/cutscene flow continues to silence active
  locomotion through the existing global stop behavior, extended to both loops.

The new MP3 is copied into `assets/audio/sfx/` with a stable lowercase project
filename. Existing `GIANT` and boss-specific keys are not changed.

## Error handling and compatibility

- Missing audio resources follow the audio manager's existing warning behavior
  rather than crashing the scene.
- The change does not add a new save-game field or migrate existing saves.
- Progress reconstruction works with current saves because the required story
  flags and inventory count already exist.
- Existing chapter transitions and intro/post-battle cutscene one-shot behavior
  remain unchanged.

## Verification

Automated regression coverage will verify:

1. Re-entering Chapter 3 after the intro restores the feather quest.
2. Inventory counts `0`, `1`, and `2` restore exactly `3`, `2`, and `1`
   uncollected feather pickups.
3. Inventory count `3` restores the rest quest when the post-battle sequence is
   unfinished.
4. Completed Chapter 3 restores the unlocked portal and exit quest.
5. Restoration never increments the feather inventory.
6. Ordinary monsters use the dedicated monster movement API and do not register
   with the allied run loop.
7. Miyarap and Thosakan audio contracts remain unchanged.
8. Both locomotion loops correctly handle multiple owners and stop after their
   final owner becomes inactive or invalid.

Manual verification will reproduce the reported path: finish the Chapter 3
intro, return to Chapter 2 with E, re-enter Chapter 3 with E, and confirm the
quest UI, saved count, remaining feather pickups, and ordinary-monster walking
sound.
