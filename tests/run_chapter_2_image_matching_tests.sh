#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
"$godot_bin" --headless --editor --quit \
  --log-file /tmp/ramakien-chapter-2-image-import.log --path .
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-chapter-2-image-matching-test.log \
  --path . --script res://tests/test_chapter_2_image_matching_runtime.gd
