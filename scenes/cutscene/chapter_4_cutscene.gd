extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากหนุมานถวายตัวรับใช้พระราม เขาออกเดินทางไปทั่วผืนป่าและขุนเขา",
	"คำบรรยาย: หนุมานรวบรวมเหล่าวานรจากทุกสารทิศ ให้มาร่วมเป็นกำลังแก่พระราม",
	"คำบรรยาย: กองทัพวานรเตรียมสร้างสะพานข้ามมหาสมุทร เพื่อมุ่งหน้าไปยังกรุงลงกา",
]

const SECOND_DIALOGUES: Array[String] = [
	"หนุมาน: “พี่น้องวานรทั้งหลาย!”",
	"หนุมาน: “ถึงเวลาช่วยพระราม และชิงพระนางสีดากลับคืนมาแล้ว!”",
	"[เหล่าวานรจากทุกสารทิศเดินทางมารวมตัวกันริมชายฝั่ง]",
	"หนุมาน: “เบื้องหน้าคือมหาสมุทร”",
	"หนุมาน: “พวกเราจะสร้างสะพานข้ามไปยังกรุงลงกา!”",
	"เหล่าวานร: “โอ้โฮ!!”",
	"พระราม: “ขอบใจทุกคน”",
	"พระราม: “ข้าจะไม่ลืมความเสียสละของพวกเจ้า”",
]

const THIRD_DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากกองทัพวานรเดินทางข้ามสะพานหินมาถึงฝั่งกรุงลงกา ทุกคนหยุดพักเพื่อเตรียมเปิดศึกในรุ่งเช้า",
	"คำบรรยาย: เหล่าวานรทยอยหลับพักผ่อนหลังจากเหน็ดเหนื่อยมาทั้งวัน",
	"คำบรรยาย: พระราม พระลักษมณ์ และหนุมานนั่งมองไปยังกรุงลงกาที่อยู่ไม่ไกล",
	"พระราม: “อีกเพียงก้าวเดียว... เราก็จะได้พบสีดา”",
	"หนุมาน: “พรุ่งนี้ พวกเราจะบุกกรุงลงกา”",
]

const FOURTH_DIALOGUES: Array[String] = [
	"คำบรรยาย: เมื่อเข้าสู่ยามดึก...",
	"คำบรรยาย: หมอกสีดำค่อย ๆ ปกคลุมทั่วค่าย",
	"คำบรรยาย: เงาร่างของไมยราพปรากฏขึ้นอย่างเงียบงัน",
	"ไมยราพ: “เมื่อเอาชนะด้วยกำลังไม่ได้... ก็ต้องใช้เล่ห์กล”",
	"คำบรรยาย: ไมยราพใช้มนตร์สะกด ทำให้เหล่าวานรทั้งหมดหลับใหล",
	"คำบรรยาย: ก่อนลอบเข้าไปยังที่ประทับของพระราม",
	"คำบรรยาย: ไมยราพร่ายเวท ห่อหุ้มพระรามด้วยพลังสีดำ แล้วอุ้มพระองค์ขึ้น",
	"ไมยราพ: “พระราม... เจ้าจะไม่ได้เข้าสู่สงครามครั้งนี้”",
	"คำบรรยาย: ประตูเวทมนตร์เปิดขึ้นกลางความมืด",
	"คำบรรยาย: ไมยราพอุ้มพระรามเดินผ่านประตู และหายลับไป",
]

const FIFTH_DIALOGUES: Array[String] = [
	"คำบรรยาย: รุ่งเช้า...",
	"คำบรรยาย: พระลักษมณ์รีบตื่นขึ้น ก่อนพบว่าพระรามหายตัวไป",
	"พระลักษมณ์: “พี่พระราม!”",
	"คำบรรยาย: หนุมานรีบวิ่งเข้ามา เห็นเพียงร่องรอยเวทมนตร์ที่ยังหลงเหลืออยู่บนพื้น",
	"คำบรรยาย: หนุมานกำหมัดแน่น",
	"หนุมาน: “ไมยราพ...”",
	"หนุมาน: “ข้าจะตามพระองค์กลับมาให้ได้!”",
]

var _dialogue_index := 0
var _dialogue_phase := 0
var _transitioning := false
var _finished := false

@onready var _cutscene_image: TextureRect = $CutsceneImage
@onready var _second_cutscene_image: TextureRect = $SecondCutsceneImage
@onready var _third_cutscene_image: TextureRect = $ThirdCutsceneImage
@onready var _fourth_cutscene_image: TextureRect = $FourthCutsceneImage
@onready var _fifth_cutscene_image: TextureRect = $FifthCutsceneImage
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _title_label: Label = $TitleBanner/Title
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	get_tree().paused = true
	_cutscene_image.show()
	_second_cutscene_image.hide()
	_third_cutscene_image.hide()
	_fourth_cutscene_image.hide()
	_fifth_cutscene_image.hide()
	_show_dialogue(0, false)
	CutsceneSkip.attach(self, _finish_cutscene)
	_play_intro_transition()


func _play_intro_transition() -> void:
	_transitioning = true
	var content: Array[CanvasItem] = [
		_cutscene_image,
		_background_dim,
		_title_banner,
		_dialogue_label,
		_prompt_label,
	]
	for item: CanvasItem in content:
		item.hide()
	_fade_overlay.color.a = 0.0
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
	var hovered_control := get_viewport().gui_get_hovered_control()
	if event is InputEventMouse and not CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		return
	get_viewport().set_input_as_handled()
	if _transitioning or _finished:
		return
	if CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		_advance_dialogue()


func _advance_dialogue() -> void:
	var dialogues := _current_dialogues()
	if _dialogue_index + 1 >= dialogues.size():
		if _dialogue_phase == 0:
			_transition_to_second_cutscene()
		elif _dialogue_phase == 1:
			_transition_to_third_cutscene()
		elif _dialogue_phase == 2:
			_transition_to_fourth_cutscene()
		elif _dialogue_phase == 3:
			_transition_to_fifth_cutscene()
		else:
			_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	var dialogues := _current_dialogues()
	_dialogue_index = index
	var is_final_dialogue := _dialogue_phase == 4 and _dialogue_index == dialogues.size() - 1
	_prompt_label.text = "กด E เพื่อเริ่ม Chapter 4 ▼" if is_final_dialogue else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.text = dialogues[_dialogue_index]
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.text = dialogues[_dialogue_index]
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _current_dialogues() -> Array[String]:
	if _dialogue_phase == 0:
		return DIALOGUES
	if _dialogue_phase == 1:
		return SECOND_DIALOGUES
	if _dialogue_phase == 2:
		return THIRD_DIALOGUES
	if _dialogue_phase == 3:
		return FOURTH_DIALOGUES
	return FIFTH_DIALOGUES


func _transition_to_second_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished

	_dialogue_phase = 1
	_cutscene_image.hide()
	_second_cutscene_image.show()
	_title_label.text = "รวมพลสร้างสะพานสู่กรุงลงกา"
	_show_dialogue(0, false)

	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _transition_to_third_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished

	_dialogue_phase = 2
	_second_cutscene_image.hide()
	_third_cutscene_image.show()
	_title_label.text = "คืนก่อนศึก ณ กรุงลงกา"
	_show_dialogue(0, false)

	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _transition_to_fourth_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished

	_dialogue_phase = 3
	_third_cutscene_image.hide()
	_fourth_cutscene_image.show()
	_title_label.text = "เล่ห์กลของไมยราพ"
	_show_dialogue(0, false)

	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _transition_to_fifth_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished

	_dialogue_phase = 4
	_fourth_cutscene_image.hide()
	_fifth_cutscene_image.show()
	_title_label.text = "คำมั่นของหนุมาน"
	_show_dialogue(0, false)

	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("switch_player_to_hanuman"):
		chapter.call("switch_player_to_hanuman")
	get_tree().paused = false
	var cutscene_layer := get_parent()
	if cutscene_layer is CanvasLayer:
		cutscene_layer.queue_free()
	else:
		queue_free()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
