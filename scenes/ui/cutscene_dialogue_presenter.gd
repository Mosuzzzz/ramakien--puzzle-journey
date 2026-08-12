class_name CutsceneDialoguePresenter
extends Control

const MIN_BOX_WIDTH := 480.0
const MIN_BOX_HEIGHT := 150.0
const MAX_BOX_WIDTH_RATIO := 0.84
const BOTTOM_GAP := 24.0
const CONTENT_LEFT := 118.0
const CONTENT_TOP := 42.0
const PROMPT_RIGHT := 28.0
const PROMPT_BOTTOM := 22.0
const HORIZONTAL_CONTENT_PADDING := 236.0
const VERTICAL_CONTENT_PADDING := 76.0
const CONTENT_SEPARATION := 8.0
const DEFAULT_PROMPT := "กด E เพื่อดำเนินเรื่องต่อ ▼"

@onready var _narration: Label = $Narration
@onready var _box: NinePatchRect = $Box
@onready var _name_label: Label = $Box/NameTag/NameLabel
@onready var _text_label: Label = $Box/Content/TextLabel
@onready var _continue_label: Label = $Box/Content/ContinueLabel

var _spoken_text := ""


func _ready() -> void:
	resized.connect(_refresh_layout)


func show_line(line: Dictionary, prompt_label: Label = null) -> void:
	var speaker := str(line.get("speaker", ""))
	var text := str(line.get("text", ""))
	var is_spoken := not speaker.is_empty()
	_narration.visible = not is_spoken
	_box.visible = is_spoken
	if is_spoken:
		_name_label.text = speaker
		_text_label.text = text
		_spoken_text = text
		_continue_label.text = prompt_label.text if prompt_label != null else DEFAULT_PROMPT
		_continue_label.visible = true
		if prompt_label != null:
			prompt_label.visible = false
		_fit_spoken_box()
	else:
		_narration.text = text
		_continue_label.visible = false
		if prompt_label != null:
			prompt_label.visible = true
	if prompt_label != null:
		_style_prompt(prompt_label, false)


func _refresh_layout() -> void:
	if _box.visible:
		_fit_spoken_box()


func _fit_spoken_box() -> void:
	var text_settings: LabelSettings = _text_label.label_settings
	var prompt_settings: LabelSettings = _continue_label.label_settings
	if text_settings == null or text_settings.font == null:
		return

	var max_box_width: float = maxf(MIN_BOX_WIDTH, size.x * MAX_BOX_WIDTH_RATIO)
	var text_width: float = text_settings.font.get_string_size(
		_spoken_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_settings.font_size
	).x
	var prompt_width: float = 0.0
	if prompt_settings != null and prompt_settings.font != null:
		prompt_width = prompt_settings.font.get_string_size(
			_continue_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			prompt_settings.font_size
		).x
	var box_width: float = clampf(
		maxf(text_width, prompt_width) + HORIZONTAL_CONTENT_PADDING,
		MIN_BOX_WIDTH,
		max_box_width
	)
	var content_width: float = maxf(1.0, box_width - HORIZONTAL_CONTENT_PADDING)
	var wrapped_text_size: Vector2 = text_settings.font.get_multiline_string_size(
		_spoken_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		content_width,
		text_settings.font_size,
		-1,
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	)
	var prompt_height := 14.0
	if prompt_settings != null and prompt_settings.font != null:
		prompt_height = prompt_settings.font.get_height(prompt_settings.font_size)
	var box_height: float = maxf(
		MIN_BOX_HEIGHT,
		wrapped_text_size.y + prompt_height + CONTENT_SEPARATION + VERTICAL_CONTENT_PADDING
	)

	_box.offset_left = -box_width * 0.5
	_box.offset_right = box_width * 0.5
	_box.offset_bottom = -BOTTOM_GAP
	_box.offset_top = -BOTTOM_GAP - box_height
	_text_label.position = Vector2(CONTENT_LEFT, CONTENT_TOP)
	_text_label.size = Vector2(content_width, wrapped_text_size.y)
	_continue_label.position = Vector2(
		CONTENT_LEFT, box_height - PROMPT_BOTTOM - prompt_height
	)
	_continue_label.size = Vector2(box_width - CONTENT_LEFT - PROMPT_RIGHT, prompt_height)


func _style_prompt(prompt_label: Label, is_spoken: bool) -> void:
	if is_spoken:
		prompt_label.add_theme_color_override("font_color", Color(0.35, 0.24, 0.13, 0.75))
		prompt_label.add_theme_constant_override("outline_size", 0)
		return
	prompt_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.78, 0.95))
	prompt_label.add_theme_constant_override("outline_size", 3)
