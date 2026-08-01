#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-quest-state-test.log \
  --path . --script res://tests/test_chapter_quest_state_runtime.gd
