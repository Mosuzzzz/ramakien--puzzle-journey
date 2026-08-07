#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-quest-notification-test.log \
  --path . --script res://tests/test_quest_notifications_runtime.gd
