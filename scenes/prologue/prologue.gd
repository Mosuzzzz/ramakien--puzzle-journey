extends Node2D

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

const NEXT_SCENE := "res://scenes/chapter_1/chapter_1.tscn"
const TITLE := "โชคชะตาแห่งอโยธยา"

const AERIAL_AYODHYA := preload("res://assets/cutscene/chapter_1/aerial_ayodhya.png")
const THRONE_ROOM_PREP := preload("res://assets/cutscene/chapter_1/throne_room_prep.png")
const KAIKESI_CONFRONT := preload("res://assets/cutscene/chapter_1/kaikesi_confront.png")

var _segments: Array[Dictionary] = [
	{
		"bg": AERIAL_AYODHYA,
		"lines": [
			"กาลครั้งหนึ่ง... ณ กรุงอโยธยา",
			"กรุงอโยธยาเป็นอาณาจักรที่รุ่งเรืองที่สุดในแผ่นดิน ภายใต้การปกครองของท้าวทศรถ กษัตริย์ผู้ทรงธรรม",
		],
	},
	{
		"bg": null,
		"lines": [
			"พระราม โอรสองค์ใหญ่ ผู้ทรงคุณธรรม ทรงเมตตา และเป็นที่รักของประชาชนทั้งแผ่นดิน",
			"\"องค์ชายพระรามเก่งที่สุด!\" เด็กน้อยตะโกนด้วยความชื่นชม",
			"\"พระองค์จะทรงเป็นกษัตริย์ที่ยิ่งใหญ่แน่นอน\" หญิงชราพึมพำอย่างมั่นใจ",
		],
	},
	{
		"bg": THRONE_ROOM_PREP,
		"lines": [
			"ภายในพระราชวัง เหล่าขุนนางกำลังตกแต่งท้องพระโรงอย่างขะมักเขม้น",
			"\"พรุ่งนี้จะเป็นวันราชาภิเษกของพระราม ประชาชนทั้งเมืองกำลังรอคอย\"",
			"ทุกคนต่างเชื่อว่า ยุคแห่งความสงบกำลังจะเริ่มต้น",
		],
	},
	{
		"bg": KAIKESI_CONFRONT,
		"lines": [
			"แต่แล้ว... ประตูท้องพระโรงก็เปิดออก นางไกยเกษีเดินเข้ามาด้วยสีหน้าเคร่งขรึม",
			"นางไกยเกษี: \"ใต้ฝ่าละอองธุลีพระบาท พระองค์ยังจำคำสัตย์ที่เคยประทานแก่หม่อมฉันได้หรือไม่\"",
			"ท้าวทศรถ: \"จำได้... เราจะไม่คืนคำ\"",
			"นางไกยเกษี: \"เช่นนั้น หม่อมฉันขอทวงพระสัญญาทั้งสองประการ\"",
		],
	},
	{
		"bg": null,
		"lines": [
			"เพียงคำสัญญาสองข้อ กำลังเปลี่ยนชะตาของพระราม และเปลี่ยนประวัติศาสตร์ของกรุงอโยธยาไปตลอดกาล",
			"\"บางครั้ง... การเสียสละ คือ หนทางแห่งวีรบุรุษ\"",
		],
	},
]
var _segment_index := 0

func _ready() -> void:
	CutsceneSkip.attach(self, _skip)
	_play_next_segment()

func _skip() -> void:
	if Dialogue.finished.is_connected(_play_next_segment):
		Dialogue.finished.disconnect(_play_next_segment)
	if Dialogue.finished.is_connected(_on_finished):
		Dialogue.finished.disconnect(_on_finished)
	Dialogue._close()
	_on_finished()

func _play_next_segment() -> void:
	if _segment_index >= _segments.size():
		_show_chapter_title()
		return
	var segment: Dictionary = _segments[_segment_index]
	_segment_index += 1
	var lines: Array[String] = []
	lines.assign(segment["lines"])
	Dialogue.finished.connect(_play_next_segment, CONNECT_ONE_SHOT)
	Dialogue.start_narration(lines, TITLE, segment["bg"])

func _show_chapter_title() -> void:
	Dialogue.finished.connect(_on_finished, CONNECT_ONE_SHOT)
	Dialogue.start_narration(["พระรามถูกเนรเทศ"], "CHAPTER 1")

func _on_finished() -> void:
	get_tree().change_scene_to_file.call_deferred(NEXT_SCENE)
