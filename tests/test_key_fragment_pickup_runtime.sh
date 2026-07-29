#!/bin/sh
set -eu
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_TEST_HOME="${GODOT_TEST_HOME:-/private/tmp/codex-godot-key-fragment-pickup}"
HOME="$GODOT_TEST_HOME" "$GODOT_BIN" --headless --path . --script tests/test_key_fragment_pickup_runtime.gd
