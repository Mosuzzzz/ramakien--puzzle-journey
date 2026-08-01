#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-boss-music-hook-test.log \
  --path . --script res://tests/test_boss_music_hooks.gd
