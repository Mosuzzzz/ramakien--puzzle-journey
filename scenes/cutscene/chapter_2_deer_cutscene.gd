extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")
const CutsceneAdvanceInput := preload("res://scenes/ui/cutscene_advance_input.gd")

const DIALOGUES: Array[String] = [
	"คำบรรยาย: วันหนึ่ง มีกวางทองขนสีทองอร่ามวิ่งผ่านหน้าอาศรมไป งดงามจนทุกคนต่างพากันมอง",
	"นางสีดา: “พระสวามี กวางตัวนั้นงดงามนัก หากจับมาได้ ข้าจะเลี้ยงไว้เป็นเพื่อนนะเพคะ”",
]

signal finished

var _active := false
var _dialogue_index := 0
var _transitioning := false

@onready var _cutscene_image: TextureRect = $CutsceneImage
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
	var content: Array[CanvasItem] = [_cutscene_image, _background_dim, _title_banner, _dialogue_label, _prompt_label]
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
	var hovered_control := get_viewport().gui_get_hovered_control()
	if event is InputEventMouse and not CutsceneAdvanceInput.is_advance_event(event, hovered_control):
		return
	get_viewport().set_input_as_handled()
	if _transitioning:
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
	_prompt_label.text = "กด E เพื่อไล่ตามกวางทอง ▼" if index == DIALOGUES.size() - 1 else "กด E เพื่อดำเนินเรื่องต่อ ▼"
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
