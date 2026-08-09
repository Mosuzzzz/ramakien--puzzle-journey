#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-scene-transition-test.log \
  --path . --script res://tests/test_scene_transition_runtime.gd
