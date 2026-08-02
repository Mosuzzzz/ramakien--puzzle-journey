# Quest Notification Below Button Design

## Goal

Place the unread quest notification arrow below the quest button in every scene that uses the shared quest HUD. Keep the existing unread-state behavior and vertical bob animation unchanged in purpose.

## Root Cause

`QuestNotification` currently has fixed scene offsets above `QuestButton`. Its base position is therefore independent of the button and remains above it.

## Design

- Compute the notification's base position from the quest button bounds when `quest_log.gd` becomes ready.
- Center the notification horizontally under the quest button.
- Leave a 6-pixel gap between the bottom of the quest button and the top of the notification.
- Bob the notification vertically around its below-button base position without changing unread, visibility, or acknowledgement behavior.
- Keep the change inside the shared `quest_log` scene/script so Chapters 1–9 receive the same placement automatically.

## Verification

- Extend the quest notification runtime test to assert that the notification top edge is below the quest button bottom edge.
- Run the focused quest notification test and the complete test suite.
- Run Godot headlessly to check scene and script parsing.

