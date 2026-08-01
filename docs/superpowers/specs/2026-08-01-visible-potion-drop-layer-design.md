# Visible Potion Drop Layer Design

## Goal

Ensure potions dropped by enemies remain visible and collectible when they land on a foreground-decorated area, including the Chapter 5 bridge where `RockChapter5` currently renders over potion pickups.

## Root Cause

Enemy drops are instantiated from `scenes/props/potion_pickup.tscn` under `YSortRoot`. In Chapter 5, `RockChapter5` is a later root-level sibling, so it renders over normal-z descendants of `YSortRoot`. The potion still exists and can be collected, but its sprite is hidden by the bridge foreground.

## Considered Approaches

1. **Give every potion pickup a small positive `z_index` (selected).** This creates one consistent rule: collectible drops render above ordinary world foreground art. It fixes Chapter 5 and prevents the same visibility bug in other chapters without changing spawn positions or collision behavior.
2. Add a Chapter 5-only drop layer. This is more narrowly scoped but duplicates rendering policy in a chapter scene and can allow the same defect elsewhere.
3. Move `RockChapter5` behind `YSortRoot`. This would expose the potion but would also place actors above the intended bridge foreground, damaging the scene's depth effect.

## Design

- Set the root `PotionPickup` node to a positive `z_index` high enough to render above normal foreground sprites that use the default z layer.
- Keep the pickup's world position, bobbing animation, interaction distance, collision mask, inventory effect, and sound behavior unchanged.
- Do not reorder `RockChapter5`; it must continue to provide foreground occlusion for actors and other world objects.
- Apply the rule globally through the reusable potion scene so all enemy potion drops behave consistently.

## Testing

- Add a scene-level regression test that loads `potion_pickup.tscn` and asserts its root rendering layer is above the default world layer.
- Run the focused regression test first and verify it fails before the scene change.
- Apply the minimum scene change and verify the focused test passes.
- Run the full Godot test suite and project parse/smoke checks.
- Preserve unrelated user changes in the working tree.

## Success Criteria

- A potion dropped on the Chapter 5 bridge is visibly rendered above `RockChapter5`.
- The potion remains at the defeated enemy's position and can still be collected normally.
- Other foreground/actor ordering in Chapter 5 is unchanged.
- The same visibility protection applies to potion drops in every chapter.
