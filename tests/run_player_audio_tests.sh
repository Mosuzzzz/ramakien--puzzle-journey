#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-player-audio-test.log \
  --path . --script res://tests/test_player_audio_hooks.gd
