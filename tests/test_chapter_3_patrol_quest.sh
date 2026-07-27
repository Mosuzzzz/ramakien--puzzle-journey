#!/bin/sh
set -eu

chapter="scenes/chapter_3/chapter_3.gd"
opening="scenes/cutscene/chapter_3_cutscene.gd"
post_cutscene="scenes/cutscene/chapter_3_post_battle_cutscene.gd"
scene="scenes/chapter_3/chapter_3.tscn"

grep -Fq 'const FEATHER_TOTAL := 3' "$chapter"
grep -Fq 'func start_feather_quest() -> void:' "$chapter"
grep -Fq 'รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ %d/3' "$chapter"
grep -Fq 'Inv.add_item("jatayu_feather")' "$chapter"
grep -Fq 'Quest.set_targets(_active_feathers())' "$chapter"
grep -Fq 'Quest.set_completed(collected_count == FEATHER_TOTAL)' "$chapter"
grep -Fq 'fade_and_relocate' "$chapter"
grep -Fq 'res://scenes/props/jatayu_feather.tscn' "$scene"
grep -Fq '[node name="Feather1"' "$scene"
grep -Fq '[node name="Feather2"' "$scene"
grep -Fq '[node name="Feather3"' "$scene"
grep -Fq '[node name="Spawn6"' "$scene"
grep -Fq 'chapter.has_method("start_feather_quest")' "$opening"
grep -Fq 'chapter.call("start_feather_quest")' "$opening"
grep -Fq 'chapter.call("finish_chapter_3_story")' "$post_cutscene"

echo "Chapter 3 feather quest contract passed"
