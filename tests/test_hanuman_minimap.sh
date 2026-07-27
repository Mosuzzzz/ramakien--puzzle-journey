#!/bin/sh
set -eu

scene="scenes/player/hanuman_player.tscn"

grep -Fq 'path="res://scenes/ui/minimap.gd"' "$scene"
grep -Fq '[node name="MiniMap" type="Control" parent="HUD"]' "$scene"
grep -Fq '[node name="MapTexture" type="TextureRect" parent="HUD/MiniMap/MapClip"]' "$scene"
grep -Fq '[node name="PlayerDot" type="Panel" parent="HUD/MiniMap/MapClip"]' "$scene"

echo "Hanuman minimap contract passed"
