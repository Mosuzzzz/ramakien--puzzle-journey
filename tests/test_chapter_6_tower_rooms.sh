#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CHAPTER="$ROOT/scenes/chapter_6/chapter_6.tscn"
LEFT_ROOM="$ROOT/scenes/chapter_6/chapter_6_room_left.tscn"
RIGHT_ROOM="$ROOT/scenes/chapter_6/chapter_6_room_right.tscn"
GAME_STATE="$ROOT/scenes/core/game_state.gd"
CUTSCENE="$ROOT/scenes/cutscene/chapter_6_cutscene.gd"
HOME_PAGE="$ROOT/scenes/homepage/home_page.gd"

grep -Fq 'name="LeftTowerRoomPortal"' "$CHAPTER"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6_room_left.tscn"' "$CHAPTER"
grep -Fq 'name="RightTowerRoomPortal"' "$CHAPTER"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6_room_right.tscn"' "$CHAPTER"

test -f "$LEFT_ROOM"
grep -Fq 'ChatGPT Image 27 ก.ค. 2569 20_32_50.png' "$LEFT_ROOM"
grep -Fq 'name="ExitPortal"' "$LEFT_ROOM"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6.tscn"' "$LEFT_ROOM"

test -f "$RIGHT_ROOM"
grep -Fq 'ChatGPT Image 27 ก.ค. 2569 20_33_55.png' "$RIGHT_ROOM"
grep -Fq 'name="ExitPortal"' "$RIGHT_ROOM"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6.tscn"' "$RIGHT_ROOM"

grep -Fq 'chapter_6_intro_played' "$GAME_STATE"
grep -Fq 'chapter_6_intro_played' "$CUTSCENE"
grep -Fq 'chapter_6_intro_played = false' "$HOME_PAGE"

echo "Chapter 6 tower room checks passed"
