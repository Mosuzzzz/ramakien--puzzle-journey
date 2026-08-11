extends Control

signal finished

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

const DIALOGUES: Array[Dictionary] = [
	{"speaker": "", "text": "ไมยราพล้มลงกับพื้น"},
	{"speaker": "", "text": "อาคมสีดำที่พันธนาการพระรามแตกสลาย"},
	{"speaker": "", "text": "พระรามลืมพระเนตรขึ้น"},
	{"speaker": "พระราม", "text": "หนุมาน..."},
	{"speaker": "", "text": "หนุมานรีบเข้าไปประคองพระราม"},
	{"speaker": "หนุมาน", "text": "พระองค์ปลอดภัยแล้ว"},
	{"speaker": "", "text": "พระรามยืนขึ้น"},
	{"speaker": "", "text": "ทอดพระเนตรไปยังหนุมานด้วยความภาคภูมิใจ"},
	{"speaker": "พระราม", "text": "เจ้ากล้าหาญและซื่อสัตย์ยิ่ง"},
	{"speaker": "พระราม", "text": "ข้าขอขอบใจเจ้า"},
	{"speaker": "", "text": "หนุมานคุกเข่าลง"},
	{"speaker": "หนุมาน", "text": "การปกป้องพระองค์ คือหน้าที่ของข้า"},
	{"speaker": "", "text": "พระลักษมณ์และกองทัพวานรเดินทางมาสมทบ"},
	{"speaker": "พระลักษมณ์", "text": "พี่พระราม!"},
	{"speaker": "", "text": "พระรามพยักหน้า"},
	{"speaker": "พระราม", "text": "ถึงเวลาสิ้นสุดสงครามแล้ว"},
]

const FINAL_DIALOGUES: Array[Dictionary] = [
	{"speaker": "", "text": "ทุกคนมองไปยังกำแพงกรุงลงกา ที่ตั้งตระหง่านอยู่เบื้องหน้า"},
	{"speaker": "", "text": "เสียงกลองศึกของฝ่ายยักษ์ดังขึ้นจากภายในเมือง"},
	{
		"speaker": "",
		"text": "พระรามและกองทัพวานรเตรียมเดินทัพเข้าสู่กรุงลงกา เพื่อเผชิญหน้ากับทศกัณฐ์และชิงนางสีดากลับคืนมา",
	},
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
@onready var _dialogue_label: CutsceneDialoguePresenter = $Dialogue
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
	await get_node("/root/SceneTransition").open_cutscene(func() -> void:
		for item: CanvasItem in content:
			item.show()
	)
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
	if CutsceneAdvanceInput.consume_advance_event(event, hovered_control):
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
		_dialogue_label.show_line(dialogues[_dialogue_index], _prompt_label)
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.show_line(dialogues[_dialogue_index], _prompt_label)
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _current_dialogues() -> Array[Dictionary]:
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
	_transitioning = true
	await get_node("/root/SceneTransition").close_cutscene(_complete_cutscene)


func _complete_cutscene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var chapter := tree.current_scene
	if chapter != null and chapter.has_method("restore_phra_ram_after_cutscene"):
		chapter.call("restore_phra_ram_after_cutscene")
	hide()
	tree.paused = false
	finished.emit()


func _exit_tree() -> void:
	if _active and get_tree() != null:
		get_tree().paused = false
