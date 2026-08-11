class_name CutsceneDialoguePresenter
extends Control

@onready var _narration: Label = $Narration
@onready var _box: NinePatchRect = $Box
@onready var _name_label: Label = $Box/NameTag/NameLabel
@onready var _text_label: Label = $Box/Margin/TextLabel


func show_line(line: Dictionary, prompt_label: Label = null) -> void:
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
	if prompt_label != null:
		_style_prompt(prompt_label, is_spoken)


func _style_prompt(prompt_label: Label, is_spoken: bool) -> void:
	if is_spoken:
		prompt_label.add_theme_color_override("font_color", Color(0.35, 0.24, 0.13, 0.75))
		prompt_label.add_theme_constant_override("outline_size", 0)
		return
	prompt_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.78, 0.95))
	prompt_label.add_theme_constant_override("outline_size", 3)
