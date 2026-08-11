#!/bin/sh
set -eu
godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
"$godot_bin" --headless --editor --quit \
  --log-file /tmp/ramakien-cutscene-dialogue-presenter-import.log --path .
exec "$godot_bin" \
  --headless --log-file /tmp/ramakien-cutscene-dialogue-presenter-test.log \
  --path . --script res://tests/test_cutscene_dialogue_presenter_runtime.gd
