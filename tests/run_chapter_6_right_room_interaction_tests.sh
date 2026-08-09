#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-6-right-room-test.log \
  --path . --script res://tests/test_chapter_6_right_room_interactions.gd
