#!/bin/sh
set -eu

scene="scenes/props/jatayu_feather.tscn"
script="scenes/props/jatayu_feather.gd"

grep -Fq 'res://assets/ui/icon/split/icon_wing.png' "$scene"
grep -Fq 'signal collection_requested(feather: Area2D)' "$script"
grep -Fq 'func fade_and_relocate(new_position: Vector2) -> void:' "$script"
grep -Fq 'func mark_collected() -> void:' "$script"
grep -Fq 'event.keycode == KEY_E' "$script"

echo "Jatayu feather scene contract passed"
