# Global Audio System Design

## Goal

Add one reusable audio system for Chapters 1 through 9. The system must keep
background music continuous across gameplay scene changes, play sound effects
at the correct gameplay events, automatically cover UI buttons, and make the
existing Music and SFX volume controls work independently.

## Scope

- Chapters 1 through 9, their subrooms, puzzles, and cutscenes.
- Both playable characters: Phra Ram and Hanuman.
- Generic enemies, Miyarap, and Thosakan.
- Existing and future item pickups that use the shared pickup flow.
- Existing quiz, matching, chest, and jar/code puzzle flows.
- Existing UI buttons, including answer buttons.
- Persistent Music and SFX volume settings.

The home page is outside the background-music requirement. Music starts when
gameplay enters a Chapter 1–9 scene and continues without restarting while the
player moves between chapter scenes, subrooms, and cutscenes.

## Audio Assets

Copy the supplied source files into normalized project paths:

| Supplied file | Project path | Purpose |
| --- | --- | --- |
| `Background.mp3` | `assets/audio/music/background.mp3` | Continuous chapter music |
| `button_click.mp3` | `assets/audio/sfx/button_click.mp3` | Every UI button press |
| `answer_correct.mp3` | `assets/audio/sfx/answer_correct.mp3` | Correct puzzle/quiz answer |
| `answer_wrong.mp3` | `assets/audio/sfx/answer_wrong.mp3` | Incorrect puzzle/quiz answer |
| `pickup.mp3` | `assets/audio/sfx/pickup.mp3` | Every item pickup |
| `run.mp3` | `assets/audio/sfx/run.mp3` | Loop while a playable character moves |
| `sword_attack.mp3` | `assets/audio/sfx/sword_attack.mp3` | Phra Ram attack |
| `thrash.mp3` | `assets/audio/sfx/thrash.mp3` | Hanuman attack |
| `hurt.mp3` | `assets/audio/sfx/hurt.mp3` | Phra Ram or Hanuman takes damage |
| `Enemy_attacking.mp3` | `assets/audio/sfx/enemy_attacking.mp3` | Generic enemy begins an attack |
| `enemy_hit.mp3` | `assets/audio/sfx/enemy_hit.mp3` | Enemy or boss takes damage |
| `giant.mp3` | `assets/audio/sfx/giant.mp3` | Miyarap slam and Thosakan footsteps |
| `Wave.mp3` | `assets/audio/sfx/wave.mp3` | Miyarap purple-wave release |
| `Giant Attack.mp3` | `assets/audio/sfx/giant_attack.mp3` | Thosakan normal attack |
| `Jump throw.mp3` | `assets/audio/sfx/jump_throw.mp3` | Thosakan jump attack |
| `Heal and Pull.mp3` | `assets/audio/sfx/heal_and_pull.mp3` | Thosakan heal or pull attack |

Use the supplied files without transcoding. `wave.mp3` is an 8 kHz mono source
and may sound less detailed than the other effects; this is accepted as source
asset quality, not an import failure.

## Architecture

### AudioManager Autoload

Add a persistent `AudioManager` autoload. It owns:

- one non-positional `AudioStreamPlayer` on the `Music` bus;
- a pool of non-positional SFX players on the `SFX` bus so effects can overlap;
- one dedicated looping run player on the `SFX` bus;
- the sound-key-to-stream registry;
- background-music start/stop rules;
- automatic UI button registration; and
- public methods for one-shot effects and run-loop state.

The public interface should express intent rather than expose player nodes, for
example `play_sfx(sound_key)`, `start_run_loop()`, `stop_run_loop()`, and
`ensure_chapter_music()`.

The manager must not restart `background.mp3` when it is already playing. This
keeps playback position continuous when changing between chapters, rooms, and
cutscenes.

### Audio Buses and Settings

Create `Music` and `SFX` buses under `Master`.

- `Music Volume` changes only the `Music` bus.
- `SFX Volume` changes only the `SFX` bus.
- Both values are clamped to 0–1, applied as decibels, saved to
  `user://settings.cfg`, and restored at startup.
- A zero slider value must mute its bus without producing invalid decibel
  values.

Existing settings and pause-menu controls must display and edit the saved values
instead of sharing the old Master-only value.

### Automatic Button Clicks

`AudioManager` observes nodes added to the active scene tree. Every `BaseButton`
is connected once to the click sound. This covers menus, inventory, pause,
dialogue controls, puzzle controls, dynamically created answer buttons, and
future buttons without editing every scene.

Answer buttons intentionally play `button_click.mp3` first and then the correct
or wrong feedback sound. Duplicate signal connections must be prevented.

## Gameplay Event Mapping

### Playable Characters

- Phra Ram starts an attack: play `sword_attack.mp3` once.
- Hanuman starts an attack: play `thrash.mp3` once.
- Either character accepts actual damage: play `hurt.mp3` once. Invulnerable or
  ignored damage must not play it.
- Either character is moving normally: loop `run.mp3`.
- Stop the run loop immediately on idle, attack, knockback/stun, or death.
- Movement polling must update state only when moving/non-moving changes; it
  must not restart the run stream every physics frame.

Only one playable character is active at a time, so the shared run-loop channel
is sufficient.

### Generic Enemies

- A generic enemy begins an attack: play `enemy_attacking.mp3` once.
- An enemy accepts actual damage: play `enemy_hit.mp3` once.
- Repeated collision checks during one attack must not replay the attack cue.

Boss-specific action sounds below replace the generic attack cue for those
actions so two attack sounds do not stack. Bosses still use `enemy_hit.mp3` when
they take damage.

### Miyarap

- At `ATTACK_HIT_FRAME`, play `giant.mp3` once for the ground impact.
- When the left and right purple waves are emitted, play `wave.mp3` once for the
  pair, after the impact cue. Do not play it once per wave node.
- Summoning and stun animations receive no new dedicated cue in this scope.

### Thosakan

- While walking, play `giant.mp3` once on each selected foot-contact animation
  frame. Frame guards prevent replay while a frame is held.
- On a normal attack start, play `giant_attack.mp3` once.
- On a jump attack start, play `jump_throw.mp3` once.
- On a heal-skill start, play `heal_and_pull.mp3` once.
- On a pull-attack start, play `heal_and_pull.mp3` once.
- Held animation frames and state-machine loops must not replay these cues.

### Pickups

Play `pickup.mp3` only when collection succeeds. This includes potions, Jatayu
feathers, Chapter 6 key fragments, and future pickups that use the shared
collection contract. Merely entering a pickup area or seeing its prompt must
not play the sound.

### Questions and Puzzles

- Accepted correct answer: play `answer_correct.mp3` once.
- Accepted wrong answer: play `answer_wrong.mp3` once.
- Cover the shared quiz UI, matching puzzle, Chapter 4 magic trail, Chapter 6
  left chest, right jars, and code-entry success/failure flows.
- Feedback-locked states must not accept another answer or replay feedback.

## Error Handling

- Missing or invalid audio resources must produce a clear warning and skip that
  sound without stopping gameplay.
- Calling an unknown sound key must be harmless.
- Exhausting the SFX pool may reuse the oldest available one-shot channel, but
  must never interrupt background music or the run loop.
- Scene changes and paused UI must not create duplicate button connections.
- AudioManager methods must be safe during headless tests where audio output may
  be unavailable.

## Verification

Automated checks should cover:

- all normalized audio assets exist and load as audio streams;
- AudioManager initializes its Music, SFX pool, and run-loop players;
- chapter music starts once and retains playback across scene changes;
- Music and SFX bus values save and restore independently;
- dynamic and static buttons receive one click handler only;
- player attack, movement transition, and damage events request the correct
  sounds without per-frame duplication;
- generic enemy and boss state transitions request the correct sounds once;
- pickups request sound only after successful collection;
- correct/wrong paths in each distinct puzzle implementation request the correct
  feedback sound; and
- the existing project test suite still passes.

Run a Godot headless editor parse after implementation. Because automated tests
cannot judge perceived loudness or timing, also perform an in-game listening
pass through representative menu, combat, pickup, quiz, Miyarap, and Thosakan
flows. Final per-sound volume tuning may be adjusted without changing event
mapping.

## Acceptance Criteria

1. The same background track plays continuously through every Chapter 1–9
   gameplay scene, subroom, and cutscene without restarting on scene changes.
2. Music and SFX sliders work independently and retain their values after a
   restart.
3. Every confirmed player, enemy, boss, pickup, puzzle, and button event uses
   the mapped sound exactly once per event.
4. Looping movement audio starts and stops with character state and never
   restarts each frame.
5. Missing audio cannot crash or block the game.
6. Existing gameplay behavior, save data, collisions, and scene transitions are
   unchanged apart from audio output and volume settings.
