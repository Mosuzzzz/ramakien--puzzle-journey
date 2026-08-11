# Thosakan Combat Polish Design

## Goal

Improve Thosakan's boss presentation and basic combat reliability without adding the newly drafted `Stunned` or `dead` animation behavior.

## Scope

- Display the existing boss name, `ทศกัณฐ์`, at 24 px and center it inside the red health tube using the same layout and font treatment as Miyarap.
- Increase Thosakan's normal movement speed from the inherited 60 px/s to 75 px/s.
- Increase Thosakan's normal attack range from the inherited 55 px to 130 px so his offset body collision can enter attack range before collision resolution stops further movement.
- Keep Thosakan's current damage, healing phase, defeat signal, and disappearance behavior unchanged.
- Remove the uncommitted `Stunned` and `dead` animation definitions and their texture references from `scenes/props/thosakan.tscn`.
- Preserve the user's source image files on disk. They are not part of this feature and must not be staged or deleted.

## Root Cause

Thosakan inherits a 55 px attack range from `mob.gd`. His body collision center is offset 84 px below the character origin, while the player collision is centered near the player origin. The movement collision can therefore stop the characters while their origins remain farther apart than the 55 px attack condition. The attack animation mapping itself is present, so the range and collision geometry mismatch is the cause of the missing normal attacks.

## Scene Changes

`scenes/props/thosakan.tscn` remains the source of Thosakan-specific tuning:

- Set `speed = 75.0` and `attack_range = 130.0` on the `ThoSaKan` root node.
- Reparent `BossName` beneath `BossHUD/BossBar` and copy Miyarap's full-rect centered label layout.
- Use the same Sarabun Bold font resource and 24 px font size as Miyarap.
- Restore the sprite animation collection to its committed animations, excluding `Stunned` and `dead`.

No shared enemy logic will change, so other mobs retain their existing movement and attack ranges.

## Behavior and Data Flow

During normal physics processing, the inherited mob controller continues chasing the player. At an origin distance below 130 px, it starts the existing `Attack` animation and applies damage through the existing hit-frame and distance checks. Thosakan's special attacks, second-phase heal, health bar updates, defeat signal, and Chapter 9 progression remain unchanged.

## Testing

Add a focused headless runtime test that instantiates Thosakan and verifies:

- `BossName` is a child of `BossBar`, uses a font size of at least 24 px, and is centered within the health bar.
- The scene's speed is 75 px/s and normal attack range is 130 px.
- A nearby player placed beyond the old 55 px limit but within 130 px causes Thosakan to enter the existing normal attack state.
- The scene contains neither `Stunned` nor `dead` animation definitions.

Run the focused test, existing enemy audio and movement tests, the complete test suite, a visual HUD capture at desktop and compact viewport sizes, and a clean Web export. The Web export check ensures no removed animation texture remains as a packaged dependency.

## Non-Goals

- No stun counter or stun state.
- No death animation or delayed disappearance.
- No changes to Thosakan's special-attack selection, damage values, healing phase, or potion behavior.
- No deletion or staging of the user's newly added source image files.
