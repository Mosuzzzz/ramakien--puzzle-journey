#!/bin/sh
set -eu

test -f scenes/chapter_6/chapter_6_key_quest.gd
grep -Fq 'static var chapter_6_left_chest_unlocked := false' scenes/core/game_state.gd
grep -Fq '"chapter_6_left_chest_unlocked"' scenes/core/save_game.gd
grep -Fq 'GameState.chapter_6_left_chest_unlocked = false' scenes/homepage/home_page.gd
grep -Fq 'static func progress(tree: SceneTree) -> int:' scenes/chapter_6/chapter_6_key_quest.gd
grep -Fq 'static func refresh(tree: SceneTree) -> int:' scenes/chapter_6/chapter_6_key_quest.gd
grep -Fq 'Chapter6KeyQuest.refresh(get_tree())' scenes/chapter_6/chapter_6.gd

echo "Chapter 6 left chest state contract passed"
