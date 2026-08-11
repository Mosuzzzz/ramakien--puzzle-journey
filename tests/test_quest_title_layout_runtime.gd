extends SceneTree

const TITLES: Array[String] = [
	"เข้าเฝ้าท้าวทศรถ",
	"ออกเดินทางสู่ป่า",
	"สำรวจรอบอาศรม",
	"ตามกวางทองเข้าป่าลึก",
	"ตามหาขนนกพญาชฎายุ",
	"พักผ่อนใต้ต้นไม้ใหญ่",
	"ตามรอยมนตร์ 2/3",
	"ปราบไมยราพ",
	"เดินทางไปยังกรุงลงกา",
	"ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง",
	"ลักลอบเข้าไปในวังทศกัณฐ์",
	"สำรวจพระราชวังเพื่อหานางสีดา",
	"เดินทางไปปราบทศกัณฐ์",
	"กลับไปช่วยนางสีดา",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var quest := (load("res://scenes/ui/quest_log.tscn") as PackedScene).instantiate()
	root.add_child(quest)
	await process_frame
	quest.call("_on_quest_button_pressed")
	await process_frame

	var columns := quest.get_node("PageDim/Page/PageMargin/Columns") as HBoxContainer
	var quest_list := columns.get_node("QuestList") as VBoxContainer
	var detail := columns.get_node("Detail") as VBoxContainer
	_expect(columns.get_theme_constant("separation") == 24, "quest columns use the approved spacing")
	_expect(is_equal_approx(quest_list.size_flags_stretch_ratio, 0.36), "quest list uses 36 percent")
	_expect(is_equal_approx(detail.size_flags_stretch_ratio, 0.64), "quest detail uses 64 percent")

	for title in TITLES:
		quest.set_quest(title, "รายละเอียดภารกิจ")
		await process_frame
		await process_frame
		var snapshot: Dictionary = quest.snapshot()
		_expect(snapshot.get("name") == title, "canonical quest title stays unchanged: %s" % title)
		var left := quest.get_node(
			"PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel"
		) as Label
		var right := quest.get_node(
			"PageDim/Page/PageMargin/Columns/Detail/DetailNameLabel"
		) as Label
		_expect(left.label_settings.font_size >= 15, "left title stays readable: %s" % title)
		_expect(right.label_settings.font_size >= 20, "right title stays readable: %s" % title)
		_expect(_has_balanced_display(left), "left title has no orphan line: %s" % title)
		_expect(_has_balanced_display(right), "right title has no orphan line: %s" % title)

	quest.queue_free()
	await process_frame
	_finish()


func _has_balanced_display(label: Label) -> bool:
	var settings := label.label_settings
	var font := settings.font
	var font_size := settings.font_size
	var available_width := label.size.x
	var lines := label.text.split("\n", false)
	if lines.size() == 1:
		return font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available_width + 1.0
	if lines.size() != 2:
		return false
	var first_width := font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var second_width := font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if first_width > available_width + 1.0 or second_width > available_width + 1.0:
		return false
	return minf(first_width, second_width) / maxf(first_width + second_width, 1.0) >= 0.35


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: quest title layout runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
