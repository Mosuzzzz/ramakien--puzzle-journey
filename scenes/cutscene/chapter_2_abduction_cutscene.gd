extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: ทันทีที่ศรของพระรามพุ่งเข้าปะทะ กวางทองก็ร้องด้วยความเจ็บปวด ก่อนร่างจะแปรเปลี่ยนกลายเป็นยักษ์มารีศ",
	"มารีศ: “พระลักษมณ์... ช่วยพี่ด้วย!”",
	"คำบรรยาย: มารีศร้องเลียนเสียงพระรามเป็นครั้งสุดท้าย ก่อนจะสิ้นใจกลางป่า",
	"คำบรรยาย: ที่อาศรม นางสีดาได้ยินเสียงร้องนั้นก็ตกใจ เชื่อว่าพระรามกำลังตกอยู่ในอันตราย",
	"นางสีดา: “พระลักษมณ์! นั่นเสียงพระราม รีบไปช่วยท่านเถิด!”",
	"พระลักษมณ์: “พี่นางอย่าเพิ่งตกใจไป นี่อาจเป็นกลอุบายของเหล่ายักษ์ก็ได้ พี่รามท่านเก่งกาจ คงไม่เป็นไรดอก”",
	"นางสีดา: “ข้าขอร้อง พระลักษมณ์ หากท่านไม่ไป ข้าจะไปเอง!”",
	"คำบรรยาย: พระลักษมณ์จำใจต้องออกจากอาศรมไปตามหาพี่ชาย ทิ้งนางสีดาไว้เพียงลำพัง",
	"คำบรรยาย: ไม่นานนัก มีฤๅษีชรารูปหนึ่งเดินเข้ามาที่อาศรม ขอน้ำและอาหารประทังชีวิต",
	"นางสีดา: “เชิญท่านฤๅษีพักที่นี่ก่อนเถิด หม่อมฉันจะจัดหาอาหารมาถวาย”",
	"คำบรรยาย: ทันทีที่นางสีดาเข้าใกล้ ฤๅษีชราก็เผยร่างที่แท้จริง คือทศกัณฐ์ เจ้ากรุงลงกา",
	"ทศกัณฐ์: “นางสีดา... ในที่สุดข้าก็พบเจ้า เจ้าจะได้เป็นมเหสีของข้าที่กรุงลงกา!”",
	"คำบรรยาย: ทศกัณฐ์ใช้ฤทธิ์อุ้มนางสีดาขึ้นราชรถเหาะ มุ่งหน้าสู่กรุงลงกาทันที",
	"คำบรรยาย: ระหว่างทาง พญาชฎายุเห็นเหตุการณ์ จึงเข้าขัดขวาง แต่ไม่อาจต้านทานฤทธิ์ของทศกัณฐ์ได้ และได้รับบาดเจ็บสาหัส",
	"คำบรรยาย: เมื่อพระรามและพระลักษมณ์กลับมาถึงอาศรม กลับพบเพียงความว่างเปล่าและร่องรอยการต่อสู้",
	"พระราม: “สีดา... เครื่องประดับของเจ้าตกอยู่ตรงนี้... ข้าจะต้องช่วยเจ้ากลับคืนมาให้ได้”",
	"คำบรรยาย: พระรามและพระลักษมณ์จึงออกเดินทางตามรอยทศกัณฐ์ทันที มุ่งหน้าสู่การผจญภัยครั้งใหม่...",
]

signal finished

var _active := false
var _dialogue_index := 0
var _transitioning := false

@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	hide()
	CutsceneSkip.attach(self, _finish_cutscene)


func show_cutscene() -> void:
	_active = true
	_transitioning = true
	_dialogue_index = 0
	_show_dialogue(0, false)
	var content: Array[CanvasItem] = [_background_dim, _title_banner, _dialogue_label, _prompt_label]
	for item: CanvasItem in content:
		item.hide()
	_fade_overlay.color.a = 0.0
	show()
	get_tree().paused = true
	_play_intro_transition(content)


func _play_intro_transition(content: Array[CanvasItem]) -> void:
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	for item: CanvasItem in content:
		item.show()
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouse:
		return  # let the GUI (skip button) receive clicks; the tree is paused anyway
	get_viewport().set_input_as_handled()
	if _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_advance_dialogue()


func _advance_dialogue() -> void:
	if _dialogue_index + 1 >= DIALOGUES.size():
		_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	_prompt_label.text = "กด E เพื่อออกติดตามทศกัณฐ์ ▼" if index == DIALOGUES.size() - 1 else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.text = DIALOGUES[_dialogue_index]
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.text = DIALOGUES[_dialogue_index]
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _finish_cutscene() -> void:
	_active = false
	hide()
	get_tree().paused = false
	finished.emit()


func _exit_tree() -> void:
	if _active and get_tree() != null:
		get_tree().paused = false
