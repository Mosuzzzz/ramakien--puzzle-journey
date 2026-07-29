#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-left-chest-flow}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_left_chest_flow_runtime.gd
