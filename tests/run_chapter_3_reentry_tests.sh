#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-3-reentry-test.log \
  --path . --script res://tests/test_chapter_3_reentry_runtime.gd
