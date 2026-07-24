#!/bin/sh
set -eu

scene="scenes/chapter_4/chapter_4.tscn"
controller="scenes/chapter_4/chapter_4.gd"
cutscene="scenes/cutscene/chapter_4_cutscene.gd"
final_image="assets/cutscene/chapter_4/ChatGPT Image 19 ก.ค. 2569 13_43_25.png"

test -f "$controller"
grep -Fq 'script = ExtResource("chapter_4_script")' "$scene"
grep -Fq 'HANUMAN_SCENE.instantiate()' "$controller"
grep -Fq 'hanuman.name = "Player"' "$controller"
grep -Fq 'player_position = old_player.position' "$controller"
grep -Fq 'chapter.call("switch_player_to_hanuman")' "$cutscene"
test -f "$final_image"
grep -Fq 'path="res://assets/cutscene/chapter_4/ChatGPT Image 19 ก.ค. 2569 13_43_25.png" id="13_fifth_cutscene_image"' "$scene"
grep -Fq 'texture = ExtResource("13_fifth_cutscene_image")' "$scene"

echo "Chapter 4 Hanuman switch contract passed"
