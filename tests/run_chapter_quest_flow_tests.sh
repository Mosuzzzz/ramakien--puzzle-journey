#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-quest-flow-test.log \
  --path . --script res://tests/test_chapter_quest_flows_runtime.gd
