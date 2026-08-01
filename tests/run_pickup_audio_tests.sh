#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-pickup-audio-test.log \
  --path . --script res://tests/test_pickup_audio_hooks.gd
