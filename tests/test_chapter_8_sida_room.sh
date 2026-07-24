#!/bin/sh
set -eu

scene="scenes/chapter_8/chapter_8_room.tscn"

grep -Fq 'path="res://scenes/props/sida.tscn" id="4_sida"' "$scene"
grep -Fq '[node name="Sida" parent="YSortRoot"' "$scene"
grep -A3 -F '[node name="Sida" parent="YSortRoot"' "$scene" |
	grep -Fq 'position = Vector2(724, 365)'

echo "Chapter 8 Sida room contract passed"
