#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
git ls-files --error-unmatch assets/ui/icon/magic_trail_icon.png >/dev/null
"$godot_bin" \
  --headless --editor --quit \
  --log-file /tmp/ramakien-magic-trail-web-asset-import.log --path .
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-magic-trail-web-asset-test.log \
  --path . --script res://tests/test_magic_trail_web_asset_runtime.gd
