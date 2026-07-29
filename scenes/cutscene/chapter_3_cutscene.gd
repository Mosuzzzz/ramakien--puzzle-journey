extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")
const GameState := preload("res://scenes/core/game_state.gd")

const DIALOGUES: Array[Dictionary] = [
	{"speaker": "พระลักษมณ์", "text": "พี่ราม ดูตรงนั้นสิ! มีนกตัวใหญ่บาดเจ็บอยู่"},
	{"speaker": "พระราม", "text": "ท่านได้ยินข้าไหม? ใครทำร้ายท่าน"},
	{"speaker": "พญาชฎายุ", "text": "พระราม... ในที่สุดเจ้าก็มาถึง..."},
	{"speaker": "พระราม", "text": "ท่านรู้จักข้าหรือ? ท่านเห็นสีดาบ้างไหม"},
	{"speaker": "พญาชฎายุ", "text": "ข้าชื่อชฎายุ เป็นเพื่อนเก่าของพ่อเจ้า"},
	{"speaker": "พระลักษมณ์", "text": "ท่านคือพญาชฎายุสินะ แล้วเกิดอะไรขึ้นที่นี่"},
	{"speaker": "พญาชฎายุ", "text": "ข้าเห็นทศกัณฐ์พาสีดาผ่านมาทางนี้ ข้าจึงเข้าไปขวาง"},
	{"speaker": "พระราม", "text": "ทศกัณฐ์เป็นคนจับตัวสีดาไปจริง ๆ หรือ"},
	{"speaker": "พญาชฎายุ", "text": "ใช่ ข้าพยายามช่วยนาง แต่ข้าสู้มันไม่ไหว"},
	{"speaker": "พระลักษมณ์", "text": "มันพาสีดาไปทางไหน"},
	{"speaker": "พญาชฎายุ", "text": "ทางทิศใต้... มันมุ่งหน้าไปยังดินแดนของพวกยักษ์"},
	{"speaker": "พระราม", "text": "ขอบคุณมาก ท่านพักก่อน พวกเราจะช่วยสีดากลับมาให้ได้"},
	{"speaker": "พญาชฎายุ", "text": "รีบไปเถอะ... อย่าให้มันหนีไปไกลกว่านี้"},
	{"speaker": "พระราม", "text": "ข้าจะไม่ลืมสิ่งที่ท่านทำเพื่อสีดา"},
	{"speaker": "พระลักษมณ์", "text": "ไปกันเถอะพี่ราม เราต้องตามรอยไปทางใต้"},
	{"speaker": "พระราม", "text": "อืม เราจะพาสีดากลับมาให้ได้"},
]

var _dialogue_index := 0
var _transitioning := false
var _finished := false

@onready var _cutscene_image: TextureRect = $CutsceneImage
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	if GameState.chapter_3_intro_played:
		var cutscene_layer := get_parent()
		if cutscene_layer is CanvasLayer:
			cutscene_layer.queue_free()
		else:
			queue_free()
		return

	GameState.chapter_3_intro_played = true
	get_tree().paused = true
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
	if _dialogue_index + 1 >= DIALOGUES.size():
		_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	var line: Dictionary = DIALOGUES[_dialogue_index]
	_prompt_label.text = "กด E เพื่อเริ่มการเดินทางต่อ ▼" if _dialogue_index == DIALOGUES.size() - 1 else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.text = "%s: “%s”" % [str(line["speaker"]), str(line["text"])]
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.text = "%s: “%s”" % [str(line["speaker"]), str(line["text"])]
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	get_tree().paused = false
	var chapter := get_tree().current_scene
	if chapter != null and chapter.has_method("start_feather_quest"):
		chapter.call("start_feather_quest")
	queue_free()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
