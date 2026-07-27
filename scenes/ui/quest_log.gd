extends CanvasLayer

const GameState := preload("res://scenes/core/game_state.gd")

var _hud_allowed := true
var _has_quest := false
var target_position := Vector2.INF

@onready var _button: TextureButton = $QuestButton
@onready var _page: Control = $PageDim
@onready var _name_label: Label = $PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel
@onready var _detail_name_label: Label = $PageDim/Page/PageMargin/Columns/Detail/DetailNameLabel
@onready var _detail_text_label: Label = $PageDim/Page/PageMargin/Columns/Detail/PageTextLabel
@onready var _marker: Control = $QuestMarker

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.hide()
	_page.hide()
	_marker.hide()

func set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void:
	_name_label.text = quest_name
	_detail_name_label.text = quest_name
	_detail_text_label.text = detail
	_has_quest = true
	_button.visible = _hud_allowed
	target_position = target

func clear() -> void:
	_has_quest = false
	_button.hide()
	_page.hide()
	target_position = Vector2.INF

## capture the active quest for saving; {} when there is no quest
func snapshot() -> Dictionary:
	if not _has_quest:
		return {}
	var target = null
	if target_position.is_finite():
		target = [target_position.x, target_position.y]
	return {"name": _name_label.text, "detail": _detail_text_label.text, "target": target}

## re-apply the quest stored by a load; runs once, after the scene is ready
func restore_pending() -> void:
	if GameState.next_quest.is_empty():
		return
	var q: Dictionary = GameState.next_quest
	GameState.next_quest = {}
	var target := Vector2.INF
	if q.get("target") != null:
		target = Vector2(q["target"][0], q["target"][1])
	set_quest(q.get("name", ""), q.get("detail", ""), target)

func set_hud_visible(shown: bool) -> void:
	_hud_allowed = shown
	_button.visible = shown and _has_quest
	if not shown:
		_page.hide()

func _on_quest_button_pressed() -> void:
	_page.visible = not _page.visible

func _close_page() -> void:
	_page.hide()

func _process(_delta: float) -> void:
	_update_marker()

func _update_marker() -> void:
	if not _hud_allowed or not target_position.is_finite():
		_marker.hide()
		return
	var vp := get_viewport()
	var cam := vp.get_camera_2d()
	if cam == null:
		_marker.hide()
		return
	# ponytail: flat rectangular clamp to screen edge, no directional rotation
	var screen_pos: Vector2 = vp.canvas_transform * target_position
	var screen_size := vp.get_visible_rect().size
	var margin := 40.0
	screen_pos.x = clampf(screen_pos.x, margin, screen_size.x - margin)
	screen_pos.y = clampf(screen_pos.y, margin, screen_size.y - margin)
	_marker.position = screen_pos - _marker.size * 0.5
	_marker.show()
