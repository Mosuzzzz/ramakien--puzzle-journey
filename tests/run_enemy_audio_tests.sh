#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-enemy-audio-test.log \
  --path . --script res://tests/test_enemy_audio_hooks.gd
