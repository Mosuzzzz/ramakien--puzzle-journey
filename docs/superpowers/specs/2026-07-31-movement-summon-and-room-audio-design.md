# Movement, Summon, and Room Audio Design

## Goal

Extend the global audio system with shared movement ambience, Miyarap's summon cue, room-transition door audio, and a quieter gameplay music mix.

## Assets

- Copy `/Users/siwakornbundi/Downloads/invite.mp3` to `res://assets/audio/sfx/invite.mp3`.
- Copy `/Users/siwakornbundi/Downloads/door.mp3` to `res://assets/audio/sfx/door.mp3`.
- Register both resources in `AudioManager` as `INVITE` and `DOOR`.
- Missing audio resources continue to warn and skip without crashing gameplay.

## Shared Movement Audio

`run.mp3` remains one shared looping SFX rather than one player per character. `AudioManager` tracks every active movement owner. The loop starts when the first valid owner begins moving and stops only when the last owner stops, dies, or leaves the scene. Invalid owners are pruned automatically.

The shared movement loop applies to:

- Rama and playable Hanuman through their existing movement hooks.
- Generic monsters in every chapter, including Miyarap's summoned minions and the Chapter 6 Yak Captain.
- Sida while she follows the player.
- The Chapter 3 Hanuman NPC while patrolling.
- Phalak whenever his `walk` animation is requested. Phalak is currently idle-only, so this prepares the correct sound boundary without adding movement behavior.

Thosakan is excluded from the shared loop because his `giant.mp3` frame-based footsteps remain the intended behavior. The golden deer is also outside this request.

Movement owners must deactivate their sound on idle, attack, stun, death, cancellation, and `_exit_tree()` as applicable. Multiple moving actors never layer multiple copies of `run.mp3`.

## Miyarap Summon Audio

`invite.mp3` plays exactly once at the start of `_start_summon()`, immediately before the summon animation begins. It does not replay for each spawned minion. Cancelled or unavailable summons never produce a second cue.

## Room Door Audio

`door.mp3` plays once immediately before a successful room scene transition. It applies in both directions: entering a room and leaving it for its parent map.

A transition is a room transition when either the current scene or target scene is one of the project's room paths:

- `res://scenes/chapter_1/throne_room.tscn`
- Chapter 6 paths containing `chapter_6_room_`
- Chapter 8 paths containing `chapter_8_room`

This covers the Chapter 1 throne room, both Chapter 6 tower rooms, and all Chapter 8 rooms including room 4/boss-room flow. Outdoor chapter-to-chapter portals and Chapter 1's south world gate do not play `door.mp3`.

The shared `portal.gd` owns this classification so individual scene files do not need repeated flags and the user's existing uncommitted `scenes/chapter_1/chapter_1.tscn` change remains untouched. Locked portals do not play door audio. Both manual and automatic successful room portals use the same behavior.

## Gameplay Music Balance

- Homepage and homepage settings remain at 100% of the saved Music setting.
- Prologue, Chapter 1–9, chapter subrooms, and chapter cutscenes change from a 40% fixed player gain to 30%.
- Master and SFX bus values remain unchanged.

## Verification

Automated runtime tests will verify:

- Two movement owners share one loop; stopping one does not silence the other.
- The loop stops after the final owner stops and after invalid owners are pruned.
- Generic monsters, Sida, Hanuman NPC, and Phalak expose the expected movement-audio lifecycle while Thosakan remains excluded.
- Miyarap's summon begins with exactly one `invite` event.
- Entering and leaving each classified room path produces one `door` event.
- Locked and outdoor portals produce no `door` event.
- Gameplay scenes use 30% music gain, menu scenes retain 100%, and SFX bus volume is unchanged.
- All existing audio suites, Godot project parsing, and a main-scene headless smoke test still pass.
