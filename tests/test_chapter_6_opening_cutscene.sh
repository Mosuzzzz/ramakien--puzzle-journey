#!/bin/sh
set -eu

scene="scenes/chapter_6/chapter_6.tscn"
cutscene="scenes/cutscene/chapter_6_cutscene.gd"

test -f "$cutscene"
grep -Fq 'Chapter6CutsceneLayer' "$scene"
grep -Fq 'script = ExtResource("chapter_6_cutscene_script")' "$scene"
grep -Fq 'ChatGPT Image 22 ก.ค. 2569 20_29_33.png' "$scene"
grep -Fq 'text = "ประตูกรุงลงกา"' "$scene"
grep -Fq 'parent="Chapter6CutsceneLayer/Chapter6Cutscene"' "$scene"

grep -Fq 'คำบรรยาย: หลังจากหนุมานช่วยพระรามกลับมาจากไมยราพได้สำเร็จ' "$cutscene"
grep -Fq 'คำบรรยาย: เมื่อเดินทางมาถึง พบว่ากรุงลงกาถูกปกป้องด้วยกำแพงขนาดมหึมา' "$cutscene"
grep -Fq 'ประตูเมืองปิดสนิทด้วยอาคมโบราณ' "$cutscene"
grep -Fq 'พระรามจึงต้องออกค้นหากลไกโบราณ' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -Fq 'event.keycode == KEY_E' "$cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$cutscene"
test "$(grep -Fc '"color:a", 1.0, 1.0' "$cutscene")" -ge 1
test "$(grep -Fc '"color:a", 0.0, 1.0' "$cutscene")" -ge 1
grep -Fq 'get_tree().paused = false' "$cutscene"

grep -Fq '[node name="Player" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter7Portal" parent="YSortRoot"' "$scene"
grep -Fq '[node name="Chapter5Portal" parent="YSortRoot"' "$scene"

echo "Chapter 6 opening cutscene contract passed"
