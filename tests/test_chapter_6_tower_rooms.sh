#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CHAPTER="$ROOT/scenes/chapter_6/chapter_6.tscn"
LEFT_ROOM="$ROOT/scenes/chapter_6/chapter_6_room_left.tscn"
RIGHT_ROOM="$ROOT/scenes/chapter_6/chapter_6_room_right.tscn"
GAME_STATE="$ROOT/scenes/core/game_state.gd"
CUTSCENE="$ROOT/scenes/cutscene/chapter_6_cutscene.gd"
HOME_PAGE="$ROOT/scenes/homepage/home_page.gd"

grep -Fq 'static var chapter_6_intro_played := false' "$GAME_STATE"
grep -Fq 'const GameState := preload("res://scenes/core/game_state.gd")' "$CUTSCENE"
grep -Fq 'if GameState.chapter_6_intro_played:' "$CUTSCENE"
grep -Fq 'GameState.chapter_6_intro_played = true' "$CUTSCENE"
grep -Fq 'GameState.chapter_6_intro_played = false' "$HOME_PAGE"

grep -Fq 'name="LeftTowerRoomPortal"' "$CHAPTER"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6_room_left.tscn"' "$CHAPTER"
grep -Fq 'name="RightTowerRoomPortal"' "$CHAPTER"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6_room_right.tscn"' "$CHAPTER"
test "$(grep -Fc 'interaction_size = Vector2(320, 220)' "$CHAPTER")" -eq 2

test -f "$LEFT_ROOM"
grep -Fq 'ChatGPT Image 27 ก.ค. 2569 20_32_50.png' "$LEFT_ROOM"
grep -Fq 'name="ExitPortal"' "$LEFT_ROOM"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6.tscn"' "$LEFT_ROOM"
grep -Fq 'target_spawn = Vector2(380, 525)' "$LEFT_ROOM"

test -f "$RIGHT_ROOM"
grep -Fq 'ChatGPT Image 27 ก.ค. 2569 20_33_55.png' "$RIGHT_ROOM"
grep -Fq 'name="ExitPortal"' "$RIGHT_ROOM"
grep -Fq 'target_scene = "res://scenes/chapter_6/chapter_6.tscn"' "$RIGHT_ROOM"
grep -Fq 'target_spawn = Vector2(1068, 525)' "$RIGHT_ROOM"

grep -Fq 'chapter_6_intro_played' "$GAME_STATE"
grep -Fq 'chapter_6_intro_played' "$CUTSCENE"
grep -Fq 'chapter_6_intro_played = false' "$HOME_PAGE"

echo "Chapter 6 tower room checks passed"
