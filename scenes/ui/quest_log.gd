extends CanvasLayer

var _hud_allowed := true
var _has_quest := false

@onready var _button: TextureButton = $QuestButton
@onready var _page: Control = $PageDim
@onready var _name_label: Label = $PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel
@onready var _detail_name_label: Label = $PageDim/Page/PageMargin/Columns/Detail/DetailNameLabel
@onready var _detail_text_label: Label = $PageDim/Page/PageMargin/Columns/Detail/PageTextLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.hide()
	_page.hide()

func set_quest(quest_name: String, detail: String = "") -> void:
	_name_label.text = quest_name
	_detail_name_label.text = quest_name
	_detail_text_label.text = detail
	_has_quest = true
	_button.visible = _hud_allowed

func clear() -> void:
	_has_quest = false
	_button.hide()
	_page.hide()

func set_hud_visible(shown: bool) -> void:
	_hud_allowed = shown
	_button.visible = shown and _has_quest
	if not shown:
		_page.hide()

func _on_quest_button_pressed() -> void:
	_page.visible = not _page.visible

func _close_page() -> void:
	_page.hide()
