extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")
const GameState := preload("res://scenes/core/game_state.gd")

const DIALOGUES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "หลังจากพระรามผ่านปริศนาภายในพระราชวังลงกาได้สำเร็จ พระรามก็มาถึงท้องพระโรง ที่ซึ่งทศกัณฐ์กำลังรออยู่",
	},
	{
		"speaker": "",
		"text": "ทศกัณฐ์ประกาศว่าจะไม่มีวันยอมคืนสีดา และเลือกตัดสินทุกอย่างด้วยการต่อสู้",
	},
	{
		"speaker": "",
		"text": "พระรามจึงเข้าประลองกับทศกัณฐ์ในการต่อสู้ครั้งสุดท้าย เพื่อยุติสงครามและช่วยนางสีดากลับคืนมา",
	},
]

var _dialogue_index := 0
var _transitioning := false
var _finished := false

@onready var _cutscene_image: TextureRect = $CutsceneImage
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: CutsceneDialoguePresenter = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	if GameState.chapter_9_intro_played or GameState.chapter_9_thotsakan_defeated:
		var cutscene_layer := get_parent()
		if cutscene_layer is CanvasLayer:
			cutscene_layer.queue_free()
		else:
			queue_free()
		return
	GameState.chapter_9_intro_played = true
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
	await get_node("/root/SceneTransition").open_cutscene(func() -> void:
		for item: CanvasItem in content:
			item.show()
	)
	_transitioning = false


func _input(event: InputEvent) -> void:
	var hovered_control := get_viewport().gui_get_hovered_control()
	if event is InputEventMouse and not CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		return
	get_viewport().set_input_as_handled()
	if _transitioning or _finished:
		return
	if CutsceneAdvanceInput.consume_advance_event(event, hovered_control):
		_advance_dialogue()


func _advance_dialogue() -> void:
	if _dialogue_index + 1 >= DIALOGUES.size():
		_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	var is_final_line := _dialogue_index == DIALOGUES.size() - 1
	_prompt_label.text = "กด E เพื่อเริ่มการต่อสู้ ▼" if is_final_line else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.show_line(DIALOGUES[_dialogue_index], _prompt_label)
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.show_line(DIALOGUES[_dialogue_index], _prompt_label)
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _finish_cutscene() -> void:
	if _finished:
		return
	_finished = true
	_transitioning = true
	await get_node("/root/SceneTransition").close_cutscene(_complete_cutscene)


func _complete_cutscene() -> void:
	get_tree().paused = false
	var cutscene_layer := get_parent()
	if cutscene_layer is CanvasLayer:
		cutscene_layer.queue_free()
	else:
		queue_free()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
