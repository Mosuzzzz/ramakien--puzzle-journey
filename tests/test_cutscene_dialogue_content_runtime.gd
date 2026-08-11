extends SceneTree

const CUTSCENE_SCRIPTS: Array[String] = [
	"res://scenes/cutscene/chapter_2_cutscene.gd",
	"res://scenes/cutscene/chapter_2_deer_cutscene.gd",
	"res://scenes/cutscene/chapter_2_abduction_cutscene.gd",
	"res://scenes/cutscene/chapter_3_cutscene.gd",
	"res://scenes/cutscene/chapter_3_post_battle_cutscene.gd",
	"res://scenes/cutscene/chapter_4_cutscene.gd",
	"res://scenes/cutscene/chapter_5_post_boss_cutscene.gd",
	"res://scenes/cutscene/chapter_6_cutscene.gd",
	"res://scenes/cutscene/chapter_8_cutscene.gd",
	"res://scenes/cutscene/chapter_9_cutscene.gd",
	"res://scenes/cutscene/chapter_9_ending_cutscene.gd",
]
const PREFIX_SCAN_FILES: Array[String] = CUTSCENE_SCRIPTS + [
	"res://scenes/chapter_2/chapter_2_second.gd",
	"res://scenes/chapter_2/chapter_2.tscn",
	"res://scenes/chapter_2/chapter_2_second.tscn",
	"res://scenes/chapter_3/chapter_3.tscn",
	"res://scenes/chapter_4/chapter_4.tscn",
	"res://scenes/chapter_5/chapter_5.tscn",
	"res://scenes/chapter_6/chapter_6.tscn",
	"res://scenes/chapter_8/chapter_8.tscn",
	"res://scenes/chapter_9/chapter_9.tscn",
]
const DIALOGUE_CONSTANTS := {
	"res://scenes/cutscene/chapter_2_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_2_deer_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_2_abduction_cutscene.gd": ["CATCH_OPENING", "SHARED_TAIL"],
	"res://scenes/cutscene/chapter_3_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_3_post_battle_cutscene.gd": ["DIALOGUES", "FINAL_DIALOGUES"],
	"res://scenes/cutscene/chapter_4_cutscene.gd": [
		"DIALOGUES", "SECOND_DIALOGUES", "THIRD_DIALOGUES", "FOURTH_DIALOGUES", "FIFTH_DIALOGUES"
	],
	"res://scenes/cutscene/chapter_5_post_boss_cutscene.gd": ["DIALOGUES", "FINAL_DIALOGUES"],
	"res://scenes/cutscene/chapter_6_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_8_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_9_cutscene.gd": ["DIALOGUES"],
	"res://scenes/cutscene/chapter_9_ending_cutscene.gd": ["DIALOGUES"],
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_no_narration_prefixes()
	_test_all_dialogue_lines_are_structured()
	_test_representative_structured_lines()
	_finish()


func _test_no_narration_prefixes() -> void:
	for path in PREFIX_SCAN_FILES:
		var file := FileAccess.open(path, FileAccess.READ)
		_expect(file != null, "%s is readable" % path)
		if file == null:
			continue
		_expect(not file.get_as_text().contains("คำบรรยาย:"), "%s has no narration prefix" % path)


func _test_all_dialogue_lines_are_structured() -> void:
	for path: String in DIALOGUE_CONSTANTS:
		for constant_name: String in DIALOGUE_CONSTANTS[path]:
			var lines := _constant(path, constant_name)
			_expect(not lines.is_empty(), "%s.%s has dialogue lines" % [path, constant_name])
			for index in lines.size():
				var line: Variant = lines[index]
				var label := "%s.%s[%d]" % [path, constant_name, index]
				_expect(line is Dictionary, "%s uses structured dialogue data" % label)
				if not line is Dictionary:
					continue
				_expect(line.size() == 2, "%s contains only speaker and text" % label)
				_expect(line.has("speaker") and line.speaker is String, "%s has a speaker string" % label)
				_expect(line.has("text") and line.text is String, "%s has a text string" % label)
				if not line.has("text") or not line.text is String:
					continue
				var text: String = line.text
				_expect(not text.is_empty(), "%s preserves a non-empty sentence" % label)
				_expect(not text.begins_with("คำบรรยาย:"), "%s omits the narration prefix" % label)
				_expect(
					not (text.begins_with("“") and text.ends_with("”")),
					"%s omits presentation-only outer quotation marks" % label
				)


func _test_representative_structured_lines() -> void:
	var deer := _constant("res://scenes/cutscene/chapter_2_deer_cutscene.gd", "DIALOGUES")
	_expect_line(deer, 0, "", "วันหนึ่ง มีกวางทองขนสีทองอร่ามวิ่งผ่านหน้าอาศรมไป งดงามจนทุกคนต่างพากันมอง")
	_expect_line(deer, 1, "นางสีดา", "พระสวามี กวางตัวนั้นงดงามนัก หากจับมาได้ ข้าจะเลี้ยงไว้เป็นเพื่อนนะเพคะ")

	var opening := _constant("res://scenes/cutscene/chapter_3_cutscene.gd", "DIALOGUES")
	_expect_line(opening, 0, "พระลักษมณ์", "พี่ราม ดูตรงนั้นสิ! มีนกตัวใหญ่บาดเจ็บอยู่")

	var post_battle := _constant("res://scenes/cutscene/chapter_3_post_battle_cutscene.gd", "DIALOGUES")
	_expect_line(post_battle, 3, "พระลักษณ์", "...ใครอยู่ตรงนั้น?")
	_expect_line(post_battle, 4, "", "[มีใบไม้ร่วงลงมาใกล้ ๆ]")

	var chapter4 := _constant("res://scenes/cutscene/chapter_4_cutscene.gd", "SECOND_DIALOGUES")
	_expect_line(chapter4, 0, "หนุมาน", "พี่น้องวานรทั้งหลาย!")

	var chapter5 := _constant("res://scenes/cutscene/chapter_5_post_boss_cutscene.gd", "DIALOGUES")
	_expect_line(chapter5, 0, "", "ไมยราพล้มลงกับพื้น")
	_expect_line(chapter5, 3, "พระราม", "หนุมาน...")


func _constant(path: String, constant_name: String) -> Array:
	var script := load(path) as Script
	if script == null:
		_failures.append("%s loads" % path)
		return []
	return script.get_script_constant_map().get(constant_name, [])


func _expect_line(lines: Array, index: int, speaker: String, text: String) -> void:
	_expect(index < lines.size(), "line %d exists" % index)
	if index >= lines.size():
		return
	var line: Variant = lines[index]
	_expect(line is Dictionary, "line %d uses structured dialogue data" % index)
	if not line is Dictionary:
		return
	_expect(line.get("speaker", null) == speaker, "line %d speaker is preserved" % index)
	_expect(line.get("text", null) == text, "line %d sentence is preserved" % index)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: cutscene dialogue content runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
