extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: หลังจากพระรามและพระลักษณ์จัดการพวกยักษ์ระหว่างทางได้ ทั้งสองเดินมาถึงใต้ต้นไม้ใหญ่กลางป่า",
	"คำบรรยาย: พระรามนั่งพักและเผลอหลับไป ส่วนพระลักษณ์ยืนเฝ้าอยู่ไม่ไกล",
	"คำบรรยาย: บนกิ่งไม้ด้านบน มีลิงสีขาวตัวหนึ่งแอบมองอยู่เงียบ ๆ",
	"พระลักษณ์: “...ใครอยู่ตรงนั้น?”",
	"[มีใบไม้ร่วงลงมาใกล้ ๆ]",
	"หนุมาน: “ฮี่ ๆ ๆ... ระวังตัวดีเหมือนกันนี่”",
	"พระลักษณ์: “ออกมาเดี๋ยวนี้! อย่ามาหลบ ๆ ซ่อน ๆ”",
	"[หนุมานโผล่ลงมาบนกิ่งไม้ มองทั้งสองด้วยท่าทางขี้เล่น]",
	"หนุมาน: “ข้าแค่มาดูเท่านั้นเอง ว่าใครกันที่กล้ามานอนใต้ต้นไม้ใหญ่ของข้า”",
]

const FINAL_DIALOGUES: Array[String] = [
	"คำบรรยาย: พระรามค่อย ๆ ลืมตาตื่นขึ้นใต้ต้นไม้ใหญ่ พระลักษณ์ยังยืนเฝ้าอยู่ใกล้ ๆ",
	"คำบรรยาย: บนกิ่งไม้ด้านบนมีลิงสีขาวตัวเล็กกำลังแอบมองอยู่",
	"คำบรรยาย: แต่ในสายตาของพระราม กลับมองเห็นเงาร่างนักรบวานรผู้สง่างามซ้อนอยู่เบื้องหลัง",
	"พระราม: “ลิงตัวนั้น... เหตุใดข้าจึงเห็นเงานักรบซ้อนอยู่ในตัวเจ้า”",
	"หนุมาน: “ท่านมองเห็นร่างจริงของข้าหรือ?”",
	"พระลักษณ์: “ข้าเห็นเพียงลิงสีขาวธรรมดาเท่านั้น”",
	"หนุมาน: “ท่านแม่เคยบอกว่า หากใครมองเห็นร่างจริงของข้า ให้ข้าติดตามรับใช้ผู้นั้น”",
	"พระราม: “ข้าชื่อพระราม และกำลังตามหาสีดาที่ถูกทศกัณฐ์จับตัวไป”",
	"หนุมาน: “ถ้าอย่างนั้น ข้าจะช่วยท่านเอง”",
	"พระราม: “ยินดีต้อนรับนะ หนุมาน”",
	"หนุมาน: “จากนี้ไป ข้าจะร่วมเดินทางกับพวกท่าน”",
]

var _active := false
var _transitioning := false
var _dialogue_index := 0
var _dialogue_phase := 0

@onready var _dialogue_label: Label = $PostBattleDialogue
@onready var _prompt_label: Label = $PostBattlePrompt
@onready var _cutscene_image: TextureRect = $PostBattleImage
@onready var _final_cutscene_image: TextureRect = $FinalCutsceneImage
@onready var _background_dim: ColorRect = $PostBattleDim
@onready var _title_banner: NinePatchRect = $PostBattleTitleBanner
@onready var _title_label: Label = $PostBattleTitleBanner/PostBattleTitle
@onready var _fade_overlay: ColorRect = $PostBattleFadeOverlay


func show_cutscene() -> void:
	_active = true
	_transitioning = true
	_dialogue_index = 0
	_dialogue_phase = 0
	_cutscene_image.show()
	_final_cutscene_image.hide()
	_title_label.text = "ใต้ต้นไม้ใหญ่"
	_show_dialogue(0, false)
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


func _ready() -> void:
	CutsceneSkip.attach(self, _finish_cutscene)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	var hovered_control := get_viewport().gui_get_hovered_control()
	if event is InputEventMouse and not CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		return
	get_viewport().set_input_as_handled()
	if _transitioning:
		return
	if CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		_advance_dialogue()


func _advance_dialogue() -> void:
	var dialogues := _current_dialogues()
	if _dialogue_index + 1 >= dialogues.size():
		if _dialogue_phase == 0:
			_transition_to_final_cutscene()
		else:
			_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _current_dialogues() -> Array[String]:
	return DIALOGUES if _dialogue_phase == 0 else FINAL_DIALOGUES


func _transition_to_final_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	_dialogue_phase = 1
	_dialogue_index = 0
	_cutscene_image.hide()
	_final_cutscene_image.show()
	_title_label.text = "ผู้ที่มองเห็นร่างจริงของหนุมาน"
	_show_dialogue(0, false)
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	var dialogues := _current_dialogues()
	var is_final_line := _dialogue_phase == 1 and _dialogue_index == dialogues.size() - 1
	_prompt_label.text = "กด E เพื่อกลับสู่การเดินทาง ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
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


func _finish_cutscene() -> void:
	_active = false
	hide()
	get_tree().paused = false
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("finish_chapter_3_story"):
		chapter.call("finish_chapter_3_story")


func _exit_tree() -> void:
	if _active and get_tree() != null:
		get_tree().paused = false
