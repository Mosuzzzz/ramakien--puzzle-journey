#!/bin/sh
set -eu

scene="scenes/chapter_9/chapter_9.tscn"
cutscene="scenes/cutscene/chapter_9_cutscene.gd"

test -f "$cutscene"
grep -Fq 'Chapter9CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_9_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 23 ก.ค. 2569 13_33_08.png' "$scene"
grep -Fq 'text = "ศึกสุดท้ายกับทศกัณฐ์"' "$scene"
grep -Fq 'parent="Chapter9CutsceneLayer/Chapter9Cutscene"' "$scene"
grep -Fq 'stretch_mode = 6' "$scene"

grep -Fq 'คำบรรยาย: หลังจากพระรามผ่านปริศนาภายในพระราชวังลงกาได้สำเร็จ' "$cutscene"
grep -Fq 'ทศกัณฐ์ประกาศว่าจะไม่มีวันยอมคืนสีดา' "$cutscene"
grep -Fq 'พระรามจึงเข้าประลองกับทศกัณฐ์ในการต่อสู้ครั้งสุดท้าย' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'event.keycode == KEY_E' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'กด E เพื่อเริ่มการต่อสู้ ▼' "$cutscene"
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Thotsakan" parent="YSortRoot"' "$scene"
grep -Fq 'max_health = 180' "$scene"
grep -Fq 'contact_damage = 20' "$scene"
grep -Fq '[node name="EndingPortal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter8Portal" parent="YSortRoot"' "$scene"

echo "Chapter 9 opening cutscene contract passed"
