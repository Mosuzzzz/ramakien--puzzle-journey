#!/bin/sh
set -eu

game_state="scenes/core/game_state.gd"
home_page="scenes/homepage/home_page.gd"
chapter_8_scene="scenes/chapter_8/chapter_8.tscn"
chapter_8_script="scenes/chapter_8/chapter_8.gd"
chapter_8_room_scene="scenes/chapter_8/chapter_8_room.tscn"
chapter_8_room_script="scenes/chapter_8/chapter_8_room.gd"
chapter_9_scene="scenes/chapter_9/chapter_9.tscn"
chapter_9_script="scenes/chapter_9/chapter_9.gd"
ending_gate="scenes/props/chapter_9_ending_gate.gd"
ending_cutscene="scenes/cutscene/chapter_9_ending_cutscene.gd"
thotsakan="scenes/props/thosakan.gd"
sida="scenes/props/sida.gd"

for file in \
	"$chapter_8_script" \
	"$chapter_8_room_script" \
	"$chapter_9_script" \
	"$ending_gate" \
	"$ending_cutscene"
do
	test -f "$file"
done

grep -Fq 'static var chapter_9_thotsakan_defeated := false' "$game_state"
grep -Fq 'static var chapter_9_sida_rescued := false' "$game_state"
grep -Fq 'GameState.chapter_9_thotsakan_defeated = false' "$home_page"
grep -Fq 'GameState.chapter_9_sida_rescued = false' "$home_page"

grep -Fq 'signal defeated' "$thotsakan"
grep -Fq 'defeated.emit()' "$thotsakan"
grep -Fq 'signal following_started' "$sida"
grep -Fq 'func start_following() -> void:' "$sida"
grep -Fq 'following_started.emit()' "$sida"

grep -Fq 'script = ExtResource("chapter_8_script")' "$chapter_8_scene"
grep -Fq 'path="res://scenes/props/sida.tscn" id="chapter_8_sida"' "$chapter_8_scene"
grep -Fq '[node name="Sida" parent="YSortRoot"' "$chapter_8_scene"
grep -Fq '$RoomEntranceLeftUpper.set_locked(not GameState.chapter_9_thotsakan_defeated)' "$chapter_8_script"
grep -Fq 'ห้องถูกล็อก ต้องกำจัดทศกัณฐ์ก่อน' "$chapter_8_script"
grep -Fq '$YSortRoot/Sida.start_following()' "$chapter_8_script"

grep -Fq 'script = ExtResource("chapter_8_room_script")' "$chapter_8_room_scene"
grep -Fq 'GameState.chapter_9_sida_rescued = true' "$chapter_8_room_script"
grep -Fq 'following_started.connect' "$chapter_8_room_script"

grep -Fq 'script = ExtResource("chapter_9_script")' "$chapter_9_scene"
grep -Fq 'path="res://scenes/props/sida.tscn" id="chapter_9_sida"' "$chapter_9_scene"
grep -Fq '[node name="Sida" parent="YSortRoot" instance=ExtResource("chapter_9_sida")]' "$chapter_9_scene"
grep -Fq 'script = ExtResource("chapter_9_ending_gate_script")' "$chapter_9_scene"
grep -Fq 'GameState.chapter_9_thotsakan_defeated = true' "$chapter_9_script"
grep -Fq 'GameState.chapter_9_thotsakan_defeated' "$chapter_9_script"
grep -Fq 'GameState.chapter_9_sida_rescued' "$chapter_9_script"
grep -Fq 'show_ending_cutscene' "$chapter_9_script"

grep -Fq 'ต้องกำจัดทศกัณฐ์ก่อน' "$ending_gate"
grep -Fq 'ต้องไปรับนางสีดาก่อน' "$ending_gate"
grep -Fq 'พานางสีดามาที่จุดนี้' "$ending_gate"
grep -Fq 'show_ending_cutscene' "$ending_gate"

grep -Fq 'ChatGPT Image 24 ก.ค. 2569 14_44_25.png' "$chapter_9_scene"
grep -Fq 'Chapter9EndingCutsceneLayer' "$chapter_9_scene"
grep -Fq 'text = "ชัยชนะเหนือทศกัณฐ์"' "$chapter_9_scene"
grep -Fq 'หลังการต่อสู้อันดุเดือด พระรามใช้พระแสงพรหมาสตร์เอาชนะทศกัณฐ์ได้สำเร็จ' "$ending_cutscene"
grep -Fq 'เมื่อราชายักษ์สิ้นชีวิต พระรามได้พาตัวนางสีดาที่ถูกคุมขัง ออกมาได้อย่างปลอดภัยและยุติสงครามลงอย่างสมบูรณ์' "$ending_cutscene"
grep -Fq 'CutsceneSkip.attach(self, _finish_cutscene)' "$ending_cutscene"
grep -Fq 'get_tree().change_scene_to_file.call_deferred(ENDING_SCENE)' "$ending_cutscene"

echo "Chapter 9 ending cutscene contract passed"
