# Story Advance, Repeated Summon, and Door Audio Design

## Goal

Make story interactions feel responsive without producing duplicate UI sounds, ensure Miyarap's summon cue follows every summon cycle, and make room-transition audio audible over gameplay music.

## Scope

This change covers three behaviors:

1. Play `button_click.mp3` when a valid story input advances or closes dialogue/cutscene content.
2. Play `invite.mp3` once at the beginning of every Miyarap summon cycle.
3. Raise only `door.mp3` to 1.5 linear gain (approximately +3.5 dB).

It does not change dialogue text, cutscene timing, summon rules, enemy limits, saved bus volumes, background-music gain, or unrelated UI interactions.

## Story Advance Audio

### Accepted inputs

Play one `button_click` cue when any of these actions is accepted:

- Press E to move to the next dialogue or cutscene line.
- Left-click a non-button area to move to the next dialogue or cutscene line.
- Press E or left-click on the final line, causing the dialogue or cutscene to close.
- Press a cutscene skip button.

### Duplicate prevention

The existing `AudioManager` already attaches `button_click` to every `BaseButton` on `button_down`. Therefore, the shared cutscene skip button must continue to use that path and must not manually play another click cue.

Dialogue and cutscene advance handlers play the cue only after input validation succeeds. Repeated key events, right clicks, mouse clicks over a button, inputs received during a cutscene transition, and unrelated gameplay E presses do not play an additional story cue.

### Integration boundary

- `DialogueManager` plays the cue immediately before its accepted `_advance()` operation.
- `CutsceneAdvanceInput` provides one shared accepted-event operation that validates the event and plays the cue once.
- Each cutscene input handler calls that shared operation only at the point where it will call `_advance_dialogue()`.
- `CutsceneSkip` remains unchanged unless testing reveals that dynamically created buttons do not receive the existing global button hook.

This approach keeps audio tied to successful story actions instead of globally intercepting all E and mouse input.

## Miyarap Repeated Summon Audio

Every accepted call that starts a new Miyarap summon animation plays one `invite` cue at its beginning. Five distinct summon cycles must produce five cues. The cue is per summon cycle, not per spawned minion.

No persistent one-shot flag may suppress later summon cues. Existing minion-cap and cooldown rules remain unchanged; if gameplay does not start a summon cycle, no cue plays.

## Door Gain

`AudioManager` owns a per-sound gain table. `door` uses 1.5 linear gain while all other SFX default to 1.0. Every pooled SFX player receives the selected sound's gain before playback so a player reused after a door cue does not leave the next sound amplified.

The Music and SFX bus settings remain user-controlled and unchanged. This gain is a relative mix adjustment inside the SFX bus.

## Testing

Runtime tests will verify observable audio events and playback state:

- Accepted E and accepted left-click each produce one `button_click` cue.
- A click over a button and an invalid input produce no story-advance cue.
- A final dialogue advance still produces one cue while closing the dialogue.
- The skip button produces one cue through the existing global button hook.
- Five Miyarap summon starts produce five `invite` events.
- A door cue uses 1.5 gain, while a subsequently reused player returns to the default 1.0 gain for a normal SFX.
- All existing audio tests, Godot script parsing, and a headless smoke launch remain green.

## Safety and Compatibility

- Reuse the existing `button_click.mp3`; the supplied file and project asset have identical SHA-256 hashes.
- Preserve the user's uncommitted `scenes/chapter_1/chapter_1.tscn` change.
- Do not alter story progression, cutscene scene changes, or interaction timing.
- Avoid global raw-input audio hooks because they would incorrectly sound on gameplay interactions.
