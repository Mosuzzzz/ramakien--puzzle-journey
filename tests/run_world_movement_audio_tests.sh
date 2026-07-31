#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-world-movement-audio-test.log \
  --path . --script res://tests/test_world_movement_audio.gd
