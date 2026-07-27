#!/bin/sh
set -eu

GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/tmp/codex-godot-home}"
mkdir -p "$GODOT_TEST_HOME"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_4_magic_trail_runtime.gd
