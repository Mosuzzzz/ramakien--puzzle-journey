#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-magic-trail-web-asset-test.log \
  --path . --script res://tests/test_magic_trail_web_asset_runtime.gd
