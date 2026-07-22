#!/bin/sh
set -eu

scene="scenes/chapter_5/chapter_5.tscn"
controller="scenes/chapter_5/chapter_5.gd"
cutscene="scenes/cutscene/chapter_5_post_boss_cutscene.gd"

test -f "$controller"
test -f "$cutscene"

grep -Fq 'script = ExtResource("chapter_5_script")' "$scene"
grep -Fq 'Chapter5PostBossCutscene' "$scene"
grep -Fq 'ChatGPT Image 21 ก.ค. 2569 18_34_46.png' "$scene"
grep -Fq 'ChatGPT Image 21 ก.ค. 2569 21_01_37.png' "$scene"

grep -Fq 'boss.tree_exited.connect(_on_miyarap_removed)' "$controller"
grep -Fq '_post_boss_cutscene.call("show_cutscene")' "$controller"
grep -Fq 'PHRA_RAM_SCENE.instantiate()' "$controller"
grep -Fq 'phra_ram.name = "Player"' "$controller"

if sed -n '/\[node name="Miyarap"/,/^$/p' "$scene" | grep -Fq 'max_health'; then
	echo "Chapter 5 still overrides Maiyarap health" >&2
	exit 1
fi
grep -Fq '@export var max_health: int = 220' scenes/props/miyarap.gd

grep -Fq 'คำบรรยาย: ไมยราพล้มลงกับพื้น' "$cutscene"
grep -Fq 'พระราม: “ถึงเวลาสิ้นสุดสงครามแล้ว”' "$cutscene"
grep -Fq 'FINAL_DIALOGUES' "$cutscene"
grep -Fq '_transition_to_final_cutscene()' "$cutscene"
grep -Fq 'ทุกคนมองไปยังกำแพงกรุงลงกา' "$cutscene"
grep -Fq 'พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา' "$cutscene"
grep -Fq 'get_tree().paused = true' "$cutscene"
grep -A2 -F 'func _ready() -> void:' "$cutscene" | grep -Fq 'hide()'
grep -Fq 'chapter.call("restore_phra_ram_after_cutscene")' "$cutscene"

echo "Chapter 5 post-boss cutscene contract passed"
