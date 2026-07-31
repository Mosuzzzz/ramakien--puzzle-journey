#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-portal-audio-test.log \
  --path . --script res://tests/test_portal_audio.gd
