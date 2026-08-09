#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-chapter-9-props-test.log \
  --path . --script res://tests/test_chapter_9_props_runtime.gd
