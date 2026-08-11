class_name CutsceneDialoguePresenter
extends Control

@onready var _narration: Label = $Narration
@onready var _box: NinePatchRect = $Box
@onready var _name_label: Label = $Box/NameTag/NameLabel
@onready var _text_label: Label = $Box/Margin/TextLabel


func show_line(line: Dictionary) -> void:
	var speaker := str(line.get("speaker", ""))
	var text := str(line.get("text", ""))
	var is_spoken := not speaker.is_empty()
	_narration.visible = not is_spoken
	_box.visible = is_spoken
	if is_spoken:
		_name_label.text = speaker
		_text_label.text = text
	else:
		_narration.text = text
