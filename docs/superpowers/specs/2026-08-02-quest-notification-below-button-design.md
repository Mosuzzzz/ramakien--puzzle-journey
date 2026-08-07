# Quest Notification Below Button Design

## Goal

Place the unread quest notification arrow below the quest button in every scene that uses the shared quest HUD. Make an unread quest more noticeable by pulsing the quest button while keeping the arrow's motion independent and simple.

## Root Cause

`QuestNotification` currently has fixed scene offsets above `QuestButton`. Its base position is therefore independent of the button and remains above it.

## Design

- Compute the notification's base position from the quest button bounds when `quest_log.gd` becomes ready.
- Center the notification horizontally under the quest button.
- Leave a 6-pixel gap between the bottom of the quest button and the top of the notification.
- Bob the notification vertically around its below-button base position. The arrow does not flash, dim, or scale.
- While a quest is unread, animate only the quest button from its normal color to a moderately dim color and back.
- Synchronize a gentle quest-button scale pulse from `1.0` to approximately `1.10` and back with the color cycle.
- Use an approximately 1.8-second cycle so the notification is noticeable without flashing rapidly.
- Stop the quest-button pulse immediately when the player presses the quest button, and restore its normal color and scale.
- Start the pulse again whenever a genuinely new quest, changed quest detail, or completion state becomes unread.
- Keep the change inside the shared `quest_log` scene/script so Chapters 1–9 receive the same placement automatically.

## Verification

- Extend the quest notification runtime test to assert that the notification top edge is below the quest button bottom edge.
- Assert that unread state starts the button pulse without applying the pulse to the arrow.
- Assert that acknowledging the quest stops the pulse and restores the button's default color and scale.
- Run the focused quest notification test and the complete test suite.
- Run Godot headlessly to check scene and script parsing.
