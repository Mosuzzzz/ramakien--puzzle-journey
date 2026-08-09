#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v godot >/dev/null 2>&1; then
  GODOT_BIN=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN=godot4
else
  echo "Godot 4.7 was not found. Install Godot and its export templates first." >&2
  exit 1
fi

rm -rf build dist
mkdir -p build/windows build/linux build/macos dist

"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . --export-release "Windows"
"$GODOT_BIN" --headless --path . --export-release "Linux"
"$GODOT_BIN" --headless --path . --export-release "macOS"

(cd build/windows && zip -9 -r ../../dist/ramakien-puzzle-journey-windows.zip .)
(cd build/linux && chmod +x ramakien-puzzle-journey.x86_64 && tar -czf ../../dist/ramakien-puzzle-journey-linux.tar.gz .)
cp "build/macos/Ramakien Puzzle Journey.zip" dist/ramakien-puzzle-journey-macos.zip

echo "Packages are ready in dist/."

