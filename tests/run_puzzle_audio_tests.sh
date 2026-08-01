#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-puzzle-audio-test.log \
  --path . --script res://tests/test_puzzle_audio_hooks.gd
