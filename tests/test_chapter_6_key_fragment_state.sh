#!/bin/sh
set -eu

inventory="scenes/ui/inventory.gd"
state="scenes/core/game_state.gd"
save_game="scenes/core/save_game.gd"
home="scenes/homepage/home_page.gd"
icons="assets/ui/icon/split"

test -f "$icons/image-removebg-preview-removebg-preview.png"
test -f "$icons/image-removebg-preview สำเนา.png"
test -f "$icons/image-removebg-preview.png"
grep -Fq '"lanka_key_fragment_shaft"' "$inventory"
grep -Fq '"lanka_key_fragment_bar"' "$inventory"
grep -Fq '"lanka_key_fragment_ring"' "$inventory"
grep -Fq 'static var chapter_6_yak_defeated := false' "$state"
grep -Fq 'static var chapter_6_yak_fragment_position := Vector2.INF' "$state"
grep -Fq '"chapter_6_intro_played"' "$save_game"
grep -Fq '"chapter_6_yak_defeated"' "$save_game"
grep -Fq 'GameState.chapter_6_yak_defeated = false' "$home"
grep -Fq 'GameState.chapter_6_yak_fragment_position = Vector2.INF' "$home"

echo "Chapter 6 key fragment state contract passed"
