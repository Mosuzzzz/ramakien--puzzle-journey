#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-story-advance-audio-test.log \
  --path . --script res://tests/test_story_advance_audio.gd
