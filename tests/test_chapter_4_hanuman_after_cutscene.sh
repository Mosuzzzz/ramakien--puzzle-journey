#!/bin/sh
set -eu

scene="scenes/chapter_4/chapter_4.tscn"
controller="scenes/chapter_4/chapter_4.gd"
cutscene="scenes/cutscene/chapter_4_cutscene.gd"

test -f "$controller"
grep -Fq 'script = ExtResource("chapter_4_script")' "$scene"
grep -Fq 'HANUMAN_SCENE.instantiate()' "$controller"
grep -Fq 'hanuman.name = "Player"' "$controller"
grep -Fq 'player_position = old_player.position' "$controller"
grep -Fq 'chapter.call("switch_player_to_hanuman")' "$cutscene"

echo "Chapter 4 Hanuman switch contract passed"
