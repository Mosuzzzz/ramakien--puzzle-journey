#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-golden-deer-run-audio-test.log \
  --path . --script res://tests/test_golden_deer_run_audio_runtime.gd
