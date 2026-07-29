#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-chapter-6-playtest}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_chapter_6_tower_rooms_playtest_runtime.gd
