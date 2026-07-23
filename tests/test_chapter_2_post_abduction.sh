#!/bin/sh
set -eu

controller="scenes/chapter_2/chapter_2_second.gd"
chapter_scene="scenes/chapter_2/chapter_2.gd"

grep -Fq 'const ASHRAM_RETURN_SPAWN := Vector2(1120, 680)' "$controller"
count="$(grep -Fc 'GameState.next_spawn = ASHRAM_RETURN_SPAWN' "$controller")"
test "$count" -eq 2

if grep -Fq 'GameState.next_spawn = Vector2(1000, 600)' "$controller"; then
	echo "Chapter 2 still uses the collision-overlapping return spawn" >&2
	exit 1
fi

grep -Fq 'if GameState.chapter_2_deer_defeated:' "$chapter_scene"
grep -A4 -F 'if GameState.chapter_2_deer_defeated:' "$chapter_scene" | grep -Fq '_sida.queue_free()'

echo "Chapter 2 post-abduction return contract passed"
