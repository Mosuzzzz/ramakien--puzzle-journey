# Chapter Quest Notifications and Music Loop Fade Design

## Goal

Restore meaningful quest-log content for Chapters 5, 7, 8, and 9, notify the
player whenever a quest is added or materially changed, and make every music
playback cycle rise smoothly from silence instead of starting at full volume.

Chapter 6 already owns a working key-fragment quest and remains functionally
unchanged. Its calls into the shared quest log will automatically gain the new
notification behavior.

## Player Experience

The existing scroll button remains the single quest-log entry point in every
chapter. When a quest first appears or its title, detail, or completion state
changes, `icon_flame.png` appears immediately above the scroll and floats up
and down. Pressing the scroll button opens or closes the quest page and marks
the current notification as read, hiding the floating icon. Repeatedly setting
an identical quest does not create a new notification.

Music begins each playback cycle silently and fades to its normal target
volume. This happens when a track first starts, after a track change, and each
time the same track reaches its end and begins another loop. The track does not
fade out at the end of a cycle. Menu/gameplay gain differences and the existing
normal-to-boss and boss-to-normal transition rules remain intact.

## Quest Notification Architecture

### Shared Quest Log

Extend the existing `QuestLog` autoload instead of adding chapter-local HUD
copies. Add a non-interactive `TextureRect` notification child near the
`QuestButton`, using:

`res://assets/ui/icon/split/icon_flame.png`

The icon is centered above the quest scroll and uses a small looping vertical
ping-pong tween. It does not receive mouse input and never blocks the scroll
button.

The quest log owns an unread-notification flag. A notification becomes unread
only when one of these conditions is true:

- There was no active quest and `set_quest()` creates one.
- The active quest title changes.
- The active quest detail text changes.
- The active quest completion state actually changes.

Changing only a target marker does not notify the player. Reapplying identical
content does not notify the player. `clear()` removes the quest and the unread
notification. Pressing `QuestButton` acknowledges the notification and hides
the icon, regardless of whether the page is being opened or closed.

When the HUD is temporarily disabled, the icon is hidden without discarding
its unread state. It becomes visible again with the scroll when the HUD is
enabled. Restoring a saved pending quest counts as a new visible quest for that
scene and may notify the player once.

### Chapter Ownership

Each chapter controller owns its story-specific quest transitions and calls
the shared quest API. Quest state changes are driven by gameplay signals and
saved story flags, not by per-frame polling.

## Chapter Quest Flow

### Chapter 5

On a fresh Chapter 5 scene with Miyarap alive, show:

- Quest: `ปราบไมยราพ`
- Detail: `กำจัดไมยราพเพื่อช่วยพระรามและเปิดเส้นทางไปต่อ`

After Miyarap is defeated, keep the boss music and post-boss cutscene behavior
unchanged. When the post-boss cutscene finishes or is skipped, replace the
quest with:

- Quest: `เดินทางไปยังกรุงลงกา`
- Detail: `ใช้เส้นทางที่เปิดแล้วเพื่อมุ่งหน้าไปยังกรุงลงกา`

Re-entering Chapter 5 after the post-boss flag is set reconstructs the travel
quest directly without respawning Miyarap.

### Chapter 7

Add a focused Chapter 7 controller. On entry before the city defenders are
cleared, show:

- Quest: `ปราบยักษ์ป้องกันเมือง`
- Detail: `กำจัดยักษ์ป้องกันเมืองให้ครบทั้ง 3 ตัว`

Connect to the three authored defender defeat signals. When all three have
been defeated, set a persistent Chapter 7 cleared flag and replace the quest
with:

- Quest: `ลักลอบเข้าไปในวังทศกัณฐ์`
- Detail: `เดินทางต่อและหาทางลักลอบเข้าไปในพระราชวังลงกา`

The cleared flag is included in save/load and new-game reset behavior so the
infiltration quest is reconstructed correctly after returning to or loading
Chapter 7. This feature does not add a visible numeric counter and does not
change the existing portal-lock rules.

### Chapter 8

Before the player discovers Sida's locked room, show:

- Quest: `สำรวจพระราชวังเพื่อหานางสีดา`
- Detail: `สำรวจห้องต่าง ๆ ภายในพระราชวังและตามหานางสีดา`

The shared portal emits a guarded locked-interaction signal when the player is
inside its interaction area and presses E while it is locked. Chapter 8 listens
only to the upper-left Sida-room entrance. The first locked interaction sets a
persistent discovery flag and replaces the quest with:

- Quest: `เดินทางไปปราบทศกัณฐ์`
- Detail: `หาทางไปยังท้องพระโรงและปราบทศกัณฐ์เพื่อปลดล็อกห้องนางสีดา`

Repeated E presses on the same locked door do not retrigger the notification.
The discovery flag is saved and reset with a new game.

If Thotsakan has already been defeated but Sida has not been rescued, Chapter
8 reconstructs the cross-chapter quest `กลับไปช่วยนางสีดา` instead. Once Sida
starts following the player, mark that quest completed without replacing its
wording.

### Chapter 9

On entry while Thotsakan is alive, show:

- Quest: `ปราบทศกัณฐ์`
- Detail: `เอาชนะทศกัณฐ์เพื่อปลดล็อกห้องที่คุมขังนางสีดา`

When Thotsakan is defeated, preserve the existing boss-music restoration and
replace the quest with:

- Quest: `กลับไปช่วยนางสีดา`
- Detail: `กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก`

The new quest therefore displays a fresh notification. Re-entering Chapter 9
after the defeat flag is set reconstructs this rescue quest until Sida has
been rescued. If Sida is already following, the rescue quest is shown as
completed while the existing ending flow remains unchanged.

## Locked Portal Signal

The shared portal adds a typed signal for a locked activation attempt. The
signal is emitted only after a valid nearby E press or valid nearby mouse
activation reaches `_use_portal()` while `locked` is true. It does not emit
from merely entering the area and never changes scene, health, spawn state, or
door audio. Existing portals that do not connect the signal remain unchanged.

## Music Loop Architecture

The `AudioManager` continues to own one Music player and all transition
requests. Music streams no longer rely on the MP3 resource's built-in loop,
because an internally looping stream provides no reliable hook for applying a
new fade at the cycle boundary.

Instead:

1. Background and boss music play as non-looping streams.
2. The Music player's `finished` signal restarts the currently requested track
   from position zero.
3. Every fresh start sets the player to `SILENT_MUSIC_DB` and tweens to the
   stored target gain over `MUSIC_FADE_SECONDS`.
4. A scene transition that keeps the same already-playing track preserves its
   playback position and does not restart the current cycle.
5. A normal-to-boss or boss-to-normal request retains the existing fade-out,
   stream swap, restart-from-beginning, and fade-in sequence.
6. Request serials guard delayed callbacks so an old track cannot restart after
   a newer music request has replaced it.

Only music uses this manual loop. The run sound keeps its existing built-in
loop and is unaffected.

## Persistence

Add these story flags to `GameState`, save/load, and new-story reset:

- `chapter_7_defenders_cleared`
- `chapter_8_sida_room_discovered`

Existing Chapter 5, Chapter 8, and Chapter 9 flags remain the source of truth
for their completed story events. The unread quest-notification flag is UI
state and is not serialized.

## Error and Duplicate Handling

- Identical quest refreshes do not create repeated notifications.
- A completed-state call not changing the value does not notify.
- Chapter 7 defeat callbacks ignore duplicate enemy defeat events and cannot
  advance past three defenders.
- The Sida-room discovery transition runs once even if E is pressed repeatedly.
- Locked interactions never play door audio or alter next-scene state.
- Music completion callbacks verify the active request before restarting.
- Missing or replaced music streams continue to use the existing warning path
  rather than attempting a restart.

## Verification

Automated and headless checks will verify:

1. QuestLog displays and bobs the supplied notification texture for a new or
   changed quest.
2. Opening the quest log acknowledges the notification.
3. Identical quest data, target-only changes, and repeated completion values do
   not retrigger it.
4. Hiding and restoring the HUD preserves an unread notification correctly.
5. Chapter 5 changes from the Miyarap quest to the Lanka travel quest at the
   post-boss cutscene boundary.
6. Chapter 7 starts with three tracked defenders and changes to the infiltration
   quest after all three defeat signals.
7. Chapter 8 changes only after a valid locked interaction with the authored
   Sida-room entrance and reconstructs the correct quest from story flags.
8. Chapter 9 changes to the Sida rescue quest when Thotsakan is defeated.
9. The two new story flags save, load, and reset correctly.
10. Initial background/boss playback and every completed music cycle restart at
    silent volume and tween to the correct menu or gameplay gain.
11. Same-track scene transitions preserve playback, boss transitions retain
    their current lifecycle, run audio remains looped, and the full existing
    test suite still passes.

## Out of Scope

- Redesigning the quest page or minimap.
- Adding quest progress counters to Chapters 5, 7, 8, or 9.
- Changing enemy count, combat balance, portal positions, or portal locks.
- Persisting whether a player has already read a quest notification.
- Fading music out at the natural end of every loop.
