#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-audio-settings-test.log \
  --path . --script res://tests/test_audio_settings_runtime.gd
