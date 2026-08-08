# Remove Quest Arrow Design

## Goal

Remove the floating arrow/flame image below the quest UI without changing the unread-quest notification behavior of the quest button.

## Scope

- Remove the `QuestNotification` visual node and its texture resource from `quest_log.tscn`.
- Remove only the arrow positioning and vertical bob animation code from `quest_log.gd`.
- Keep the logical unread state, quest-button dim/bright pulse, periodic scale animation, and acknowledgement behavior unchanged.
- Update the quest notification runtime test so it verifies that the arrow node no longer exists while retaining coverage for the quest-button notification behavior.

## Verification

- The focused quest notification test must pass.
- The complete project test suite must pass.
- Opening or updating an unread quest still animates the quest button, and clicking it stops the animation.
- No arrow/flame appears under the quest UI.
