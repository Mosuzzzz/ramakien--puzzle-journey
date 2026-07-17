extends Control

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

@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt


func _ready() -> void:
	get_tree().paused = true
	_show_dialogue(0, false)


func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if _transitioning or _finished:
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
	var cutscene_layer := get_parent()
	if cutscene_layer is CanvasLayer:
		cutscene_layer.queue_free()
	else:
		queue_free()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
