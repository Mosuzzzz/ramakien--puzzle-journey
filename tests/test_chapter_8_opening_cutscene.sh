#!/bin/sh
set -eu

scene="scenes/chapter_8/chapter_8.tscn"
cutscene="scenes/cutscene/chapter_8_cutscene.gd"
game_state="scenes/core/game_state.gd"
home_page="scenes/homepage/home_page.gd"

test -f "$cutscene"
grep -Fq 'Chapter8CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_8_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 23 ก.ค. 2569 11_31_24.png' "$scene"
grep -Fq 'text = "ปริศนาแห่งพระราชวังลงกา"' "$scene"
grep -Fq 'parent="Chapter8CutsceneLayer/Chapter8Cutscene"' "$scene"
grep -Fq 'stretch_mode = 6' "$scene"

grep -Fq 'คำบรรยาย: หลังจากพระรามฝ่าแนวป้องกันของเหล่าทหารยักษ์' "$cutscene"
grep -Fq 'ประตูทุกบานเชื่อมต่อกันราวกับเขาวงกต' "$cutscene"
grep -Fq 'พระรามต้องไขปริศนาเพื่อเปิดประตูบานสุดท้าย' "$cutscene"
grep -Fq 'การเผชิญหน้าครั้งสุดท้ายก็ใกล้จะเริ่มต้น' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'CutsceneAdvanceInput.is_advance_event(event, hovered_control)' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'กด E เพื่อเริ่ม Chapter 8 ▼' "$cutscene"
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq 'static var chapter_8_intro_played := false' "$game_state"
grep -Fq 'GameState.chapter_8_intro_played = false' "$home_page"
grep -Fq 'if GameState.chapter_8_intro_played:' "$cutscene"
grep -Fq 'GameState.chapter_8_intro_played = true' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter9Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter7Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Mob1" parent="YSortRoot"' "$scene"

echo "Chapter 8 opening cutscene contract passed"
