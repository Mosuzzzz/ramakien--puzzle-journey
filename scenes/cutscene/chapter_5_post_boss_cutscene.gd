extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: ไมยราพล้มลงกับพื้น",
	"คำบรรยาย: อาคมสีดำที่พันธนาการพระรามแตกสลาย",
	"คำบรรยาย: พระรามลืมพระเนตรขึ้น",
	"พระราม: “หนุมาน...”",
	"คำบรรยาย: หนุมานรีบเข้าไปประคองพระราม",
	"หนุมาน: “พระองค์ปลอดภัยแล้ว”",
	"คำบรรยาย: พระรามยืนขึ้น",
	"คำบรรยาย: ทอดพระเนตรไปยังหนุมานด้วยความภาคภูมิใจ",
	"พระราม: “เจ้ากล้าหาญและซื่อสัตย์ยิ่ง”",
	"พระราม: “ข้าขอขอบใจเจ้า”",
	"คำบรรยาย: หนุมานคุกเข่าลง",
	"หนุมาน: “การปกป้องพระองค์ คือหน้าที่ของข้า”",
	"คำบรรยาย: พระลักษมณ์และกองทัพวานรเดินทางมาสมทบ",
	"พระลักษมณ์: “พี่พระราม!”",
	"คำบรรยาย: พระรามพยักหน้า",
	"พระราม: “ถึงเวลาสิ้นสุดสงครามแล้ว”",
]

const FINAL_DIALOGUES: Array[String] = [
	"คำบรรยาย: ทุกคนมองไปยังกำแพงกรุงลงกา ที่ตั้งตระหง่านอยู่เบื้องหน้า",
	"คำบรรยาย: เสียงกลองศึกของฝ่ายยักษ์ดังขึ้นจากภายในเมือง",
	"คำบรรยาย: พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา เพื่อเผชิญหน้ากับทศกัณฐ์และชิงนางสีดากลับคืนมา",
]

var _active := false
var _transitioning := false
var _finished := false
var _dialogue_index := 0
var _dialogue_phase := 0

@onready var _image: TextureRect = $CutsceneImage
@onready var _final_image: TextureRect = $LankaMarchImage
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	hide()
	CutsceneSkip.attach(self, _finish_cutscene)


func show_cutscene() -> void:
	if _active or _finished:
		return
	_active = true
	_transitioning = true
	_dialogue_index = 0
	_dialogue_phase = 0
	_image.show()
	_final_image.hide()
	_show_dialogue(0, false)
	var content: Array[CanvasItem] = [
		_image,
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
			_transition_to_final_cutscene()
		else:
			_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	var dialogues := _current_dialogues()
	var is_final_line := _dialogue_phase == 1 and _dialogue_index == dialogues.size() - 1
	_prompt_label.text = "กด E เพื่อกลับสู่ Chapter 5 ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
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
	return DIALOGUES if _dialogue_phase == 0 else FINAL_DIALOGUES


func _transition_to_final_cutscene() -> void:
	_transitioning = true
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	_dialogue_phase = 1
	_dialogue_index = 0
	_image.hide()
	_final_image.show()
	$TitleBanner/Title.text = "มุ่งหน้าสู่กรุงลงกา"
	_show_dialogue(0, false)
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	_active = false
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("restore_phra_ram_after_cutscene"):
		chapter.call("restore_phra_ram_after_cutscene")
	hide()
	get_tree().paused = false


func _exit_tree() -> void:
	if _active and get_tree() != null:
		get_tree().paused = false
