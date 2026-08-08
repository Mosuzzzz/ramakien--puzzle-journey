#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-cutscene-transition-test.log \
  --path . --script res://tests/test_cutscene_transition_runtime.gd
