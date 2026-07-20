extends CanvasLayer

signal finished

var is_active: bool = false

var _lines: Array[String] = []
var _index: int = 0
var _is_narration: bool = false

@onready var _box: NinePatchRect = $Box
@onready var _name_tag: Control = $Box/NameTag
@onready var _name_label: Label = $Box/NameTag/NameLabel
@onready var _text_label: Label = $Box/Margin/VBox/TextLabel

@onready var _narration: Control = $Narration
@onready var _narration_label: Label = $Narration/Text
@onready var _chapter_title: Control = $Narration/ChapterTitle
@onready var _chapter_title_label: Label = $Narration/ChapterTitle/Label
@onready var _backdrop: ColorRect = $Narration/Backdrop
@onready var _bg_image: TextureRect = $Narration/BgImage
@onready var _bg_tint: ColorRect = $Narration/BgTint

var _base_text_size := 0
var _base_narration_size := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box.hide()
	_narration.hide()
	_base_text_size = _text_label.label_settings.font_size
	_base_narration_size = _narration_label.label_settings.font_size
	_apply_font_scale()
	Settings.font_scale_changed.connect(_apply_font_scale)

func _apply_font_scale() -> void:
	_text_label.label_settings.font_size = roundi(_base_text_size * Settings.font_scale())
	_narration_label.label_settings.font_size = roundi(_base_narration_size * Settings.font_scale())

func start(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_is_narration = false
	is_active = true
	_name_label.text = speaker
	_name_tag.visible = speaker != ""
	_box.show()
	_show_line()

func start_narration(lines: Array[String], title: String = "", background: Texture2D = null) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_is_narration = true
	is_active = true
	_chapter_title.visible = title != ""
	_chapter_title_label.text = title
	_bg_image.texture = background
	_bg_image.visible = background != null
	_bg_tint.visible = background != null
	_backdrop.visible = background == null
	_narration.show()
	_show_line()

func _show_line() -> void:
	if _is_narration:
		_narration_label.text = _lines[_index]
	else:
		_text_label.text = _lines[_index]

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_advance()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_viewport().gui_get_hovered_control() is Button:
			return  # click belongs to a UI button (e.g. cutscene skip), don't advance
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()

func _close() -> void:
	is_active = false
	_box.hide()
	_narration.hide()
	finished.emit()
