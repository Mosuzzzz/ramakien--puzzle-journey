#!/bin/sh
set -eu

chapter="scenes/chapter_3/chapter_3.gd"
scene="scenes/chapter_3/chapter_3.tscn"

grep -Fq 'คำใดอยู่ในมาตราตัวสะกดแม่กง' "$chapter"
grep -Fq '["ลิง", "ดาว", "เมฆ"]' "$chapter"
grep -Fq 'คำว่า “วิ่ง” เป็นคำชนิดใด' "$chapter"
grep -Fq '["คำนาม", "คำกริยา", "คำวิเศษณ์"]' "$chapter"
grep -Fq 'func _on_feather_collection_requested(feather: Area2D) -> void:' "$chapter"
grep -Fq 'func _on_quiz_answered(correct: bool) -> void:' "$chapter"
grep -Fq 'res://scenes/ui/question_quiz.tscn' "$scene"
if grep -Fq 'mob.set("damage_gate", self)' "$chapter"; then
	echo "Chapter 3 still gates monster damage through the quiz" >&2
	exit 1
fi

echo "Chapter 3 feather quiz and normal monster combat contract passed"
