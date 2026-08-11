#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-quest-title-layout-test.log \
  --path . --script res://tests/test_quest_title_layout_runtime.gd
