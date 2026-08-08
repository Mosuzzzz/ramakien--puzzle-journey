#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-camera-framing-test.log \
  --path . --script res://tests/test_camera_framing_runtime.gd
