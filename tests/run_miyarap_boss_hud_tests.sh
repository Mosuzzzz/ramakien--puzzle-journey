#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-miyarap-boss-hud-test.log \
  --path . --script res://tests/test_miyarap_boss_hud_runtime.gd
