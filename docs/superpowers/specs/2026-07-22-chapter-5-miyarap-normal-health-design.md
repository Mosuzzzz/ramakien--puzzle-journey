# Chapter 5 Maiyarap Normal Health Design

## Goal

Restore Maiyarap in Chapter 5 from the temporary one-hit test setting to the normal shared boss health.

## Design

- Remove the `max_health = 1` override from the `YSortRoot/Miyarap` instance in `scenes/chapter_5/chapter_5.tscn`.
- Keep the shared `@export var max_health: int = 220` value in `scenes/props/miyarap.gd` unchanged.
- Do not modify Maiyarap combat behavior, Chapter 5 cutscenes, portals, or player-switch logic.
- Let future shared boss-balance changes apply automatically to Chapter 5.

## Verification

- Confirm `chapter_5.tscn` no longer contains a `max_health` override for Maiyarap.
- Confirm `miyarap.gd` still defines the default as `220`.
- Run the Chapter 5 cutscene contract test and `git diff --check`.
