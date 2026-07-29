# Chapter 6 Key Fragment Quest Design

## Goal

Start a three-part key quest when the Chapter 6 opening cutscene ends. In
this phase, the Yak Captain drops one collectible key fragment; the two room
fragments are registered as separate inventory items but their puzzle
mechanics are intentionally deferred.

## Player Experience

After the Chapter 6 cutscene finishes or is skipped, the quest log shows:

- Quest: `ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง`
- Detail: `รวบรวมชิ้นส่วนกุญแจ 0/3`

Defeating the Yak Captain creates a golden toothed-shaft fragment at the
enemy's death position. The fragment floats up and down to remain visible.
When the player approaches it, the prompt
`กด E เพื่อเก็บชิ้นส่วนกุญแจ` appears. Pressing E removes the world pickup,
adds the fragment to the inventory, and updates the quest to `1/3`.

## Inventory Model

The three pieces are distinct inventory items and use the three supplied
textures:

| Item ID | Display name | Texture | Source |
| --- | --- | --- | --- |
| `lanka_key_fragment_shaft` | `ชิ้นส่วนกุญแจ: แกน` | `image-removebg-preview-removebg-preview.png` | Yak Captain |
| `lanka_key_fragment_bar` | `ชิ้นส่วนกุญแจ: แท่ง` | `image-removebg-preview สำเนา.png` | Deferred room puzzle |
| `lanka_key_fragment_ring` | `ชิ้นส่วนกุญแจ: ห่วง` | `image-removebg-preview.png` | Deferred room puzzle |

All paths are under `res://assets/ui/icon/split/`. Quest progress is the sum
of whether each item ID is present, clamped to one per piece. Duplicate
copies cannot increase progress beyond `3/3`.

## Architecture

### Chapter 6 Controller

Attach a Chapter 6-specific script to the main Chapter 6 scene. It owns the
quest lifecycle, connects to the Yak Captain's defeat signal, spawns or
restores the world fragment, listens for collection, and refreshes progress
from inventory.

The opening cutscene calls `start_key_fragment_quest()` on the current
Chapter 6 scene immediately before it removes itself. When Chapter 6 is
re-entered after the intro has already played, the controller restores the
quest directly during scene startup.

The quest does not add a world marker in this phase. Room puzzle targets and
door unlocking will be designed later.

### Reusable Fragment Pickup

Create a reusable `Area2D` pickup scene and script for all three future
fragments. It exposes the item ID, texture, and prompt, animates only its
visual child with a sinusoidal vertical bob, detects the Player, accepts E,
and emits one collection signal. The Chapter 6 controller remains
responsible for inventory and quest state so the pickup stays presentation-
focused.

### Mob Defeat Signal

Extend the shared mob with a typed `defeated` signal and an internal guard.
Lethal damage emits the signal exactly once before the mob is freed.
Nonlethal damage and scene teardown do not emit it, preventing accidental
drops during room transitions.

## Persistence and Restoration

Add these Chapter 6 fields:

- `GameState.chapter_6_yak_defeated: bool`
- `GameState.chapter_6_yak_fragment_position: Vector2`

When the Yak Captain dies, the controller sets the flag and records the
death position. While the current run remains active, leaving for either
tower room and returning restores the uncollected fragment at that recorded
position without respawning the Yak Captain.

Inventory is already included in saves. Add the Yak defeated flag and the
existing Chapter 6 intro flag to saved state. The arbitrary death position
is not serialized in this phase. Loading a save made after the Yak Captain
died but before collection restores the uncollected fragment at the Yak
Captain's authored scene position, `Vector2(724, 445)`.

If the shaft fragment is already in inventory, the controller hides/removes
the Yak Captain and does not create another pickup. Starting a new story
resets the Yak defeated flag and stored fragment position.

## Quest State Rules

- Before the opening cutscene finishes, the key-fragment quest is not shown.
- After it finishes, progress is derived from inventory and initially reads
  `0/3` for a fresh run.
- Killing the Yak Captain does not change progress by itself.
- Collecting the dropped shaft changes progress to `1/3`.
- Re-entering Chapter 6 reconstructs the correct quest and enemy/drop state.
- Progress reaches completion only when all three distinct fragment IDs are
  present. Completing the quest does not unlock the city gate in this phase.

## Error and Duplicate Handling

- A guarded defeat path prevents duplicate drops from repeated lethal hits.
- A pickup disables monitoring and input before emitting collection, so one
  key press cannot collect twice.
- The controller checks inventory before adding the shaft fragment.
- If the stored fragment position is not finite, restoration uses the Yak
  Captain's authored position.
- Missing optional room fragments do not block the Yak fragment flow.

## Verification

Automated coverage will verify:

1. The cutscene finish and skip paths start the quest at `0/3`.
2. Nonlethal damage does not create a drop.
3. Lethal damage emits one defeat event and creates one floating pickup at
   the Yak Captain's position.
4. Entering the pickup range shows the E prompt.
5. Pressing E adds only `lanka_key_fragment_shaft`, removes the pickup, and
   changes the quest to `1/3`.
6. Leaving and re-entering Chapter 6 before pickup keeps the Yak Captain
   defeated and restores one pickup.
7. Re-entering after collection creates neither the Yak Captain nor another
   pickup.
8. Inventory registration, saved Yak state, new-story reset, full-suite
   regression tests, and Godot headless parsing remain valid.

## Deferred Work

This phase does not implement:

- The left-room puzzle or its bar fragment.
- The right-room puzzle or its ring fragment.
- Combining the three fragments.
- Unlocking or opening the Lanka city gate.
