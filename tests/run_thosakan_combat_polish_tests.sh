#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
"$godot_bin" \
  --headless --editor --quit \
  --log-file /tmp/ramakien-thosakan-combat-import.log --path .
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-thosakan-combat-test.log \
  --path . --script res://tests/test_thosakan_combat_polish_runtime.gd
