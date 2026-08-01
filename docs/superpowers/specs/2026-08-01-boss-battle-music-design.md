# Boss Battle Music Design

## Goal

Use `Boss fight.mp3` as the looping background track while the Chapter 5 Miyarap fight and Chapter 9 Thotsakan fight are active. Transitions must be gradual, must not overlap tracks, and must respect each chapter's saved boss state.

## Approved Experience

### Entering a boss chapter

- When Chapter 5 loads and Miyarap has not been defeated, the normal gameplay track fades completely to silence over 1.5 seconds.
- After the normal track is silent, the music player switches to the boss track at zero volume and fades it up over 1.5 seconds.
- Chapter 9 follows the same sequence when Thotsakan has not been defeated.
- The boss track uses the same final gain as the normal gameplay track.
- If the boss was already defeated in the loaded save, the chapter keeps the normal gameplay track and does not start boss music.

### Defeating Miyarap

- Miyarap's defeat does not restore normal music immediately.
- Boss music continues uninterrupted throughout the complete Chapter 5 post-boss cutscene.
- Finishing or skipping that cutscene emits one completion event.
- Only after that completion event does the boss track fade fully out over 1.5 seconds.
- The normal background track then starts from the beginning at zero volume and fades to normal gameplay gain over 1.5 seconds.

### Defeating Thotsakan

- Thotsakan's defeat begins the return transition immediately because Chapter 9's ending cutscene occurs later, after the player rescues Sida and reaches the ending trigger.
- The boss track fades fully out over 1.5 seconds.
- The normal background track then starts from the beginning and fades to normal gameplay gain over 1.5 seconds.

## Audio Architecture

The existing global `AudioManager` remains the single owner of background music. The feature will use its existing `Music` player rather than creating chapter-local players.

The manager will:

- register a `boss_fight` music key pointing to `res://assets/audio/music/boss_fight.mp3`;
- configure both normal and boss MP3 streams to loop;
- expose idempotent APIs to request boss music or restore scene music;
- use a single active tween for sequential fade-out, stream swap, and fade-in;
- cancel an older transition before starting a newer request;
- prevent scene synchronization from replacing an active boss override;
- clear the override when normal music is deliberately restored or when leaving supported gameplay flow;
- start the normal track from position zero when returning after a boss.

Using one music player intentionally creates a moment of silence between tracks. This matches the approved sequence: the current track must become silent before the next track starts.

## Scene Integration

### Chapter 5

- On scene readiness, request boss music only when `GameState.chapter_5_post_boss_played` is false and the Miyarap node exists.
- Keep the existing Miyarap removal behavior that unlocks the portal and starts the post-boss cutscene.
- Add a `finished` signal to the Chapter 5 post-boss cutscene and emit it from its single finish path. Both normal completion and skip already use that path.
- Connect the chapter controller to that signal and restore normal music only when it is received.

### Chapter 9

- On scene readiness, request boss music only when `GameState.chapter_9_thotsakan_defeated` is false and Thotsakan is present.
- In the existing defeated-signal handler, save the defeated state and request restoration of normal gameplay music.

## Race and Re-entry Handling

- Repeating a request for the currently selected target track must not restart the track.
- A newer music request supersedes an unfinished fade transition.
- Scene-path synchronization must continue to set menu and gameplay gains without restarting an unchanged normal track.
- Loading a completed Chapter 5 or Chapter 9 state must leave boss music disabled.
- The completion callback for the Chapter 5 cutscene must be safe if it is emitted only once or the scene is exiting.

## Asset Handling

Copy `/Users/siwakornbundi/Downloads/Boss fight.mp3` into the project as:

`res://assets/audio/music/boss_fight.mp3`

Godot will import it as a looping MP3 resource. The original file in Downloads remains unchanged.

## Verification

Automated checks will cover:

- the boss music asset and sound key load successfully;
- both music streams loop;
- requesting boss music changes to the boss stream without changing the gameplay target gain;
- restoring normal music selects the normal stream from the beginning;
- repeat requests do not restart the active track;
- Chapter 5 starts boss music only for an undefeated Miyarap;
- Chapter 5 restores music from the post-boss cutscene completion path, including skip;
- Chapter 9 starts boss music only for an undefeated Thotsakan and restores it on the defeated signal;
- existing global audio tests continue to pass;
- Godot can parse the changed scripts and load the changed scenes without errors.

Manual verification should confirm that transitions are audible and smooth in both chapters, and that Chapter 5 boss music remains audible until the post-boss cutscene actually closes.
