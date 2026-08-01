#!/bin/sh
set -eu
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/ramakien-potion-pickup-rendering-test.log \
  --path . --script res://tests/test_potion_pickup_rendering.gd
