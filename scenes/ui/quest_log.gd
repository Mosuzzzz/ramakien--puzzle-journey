extends CanvasLayer

const DEFAULT_TEXT_COLOR := Color.WHITE
const COMPLETED_TEXT_COLOR := Color("#67d56b")

var _hud_allowed := true
var _has_quest := false
var target_position := Vector2.INF
var _target_nodes: Array[Node2D] = []
var _target_markers: Array[Control] = []

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
	clear_targets()
	set_completed(false)
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
	clear_targets()
	set_completed(false)


func set_targets(nodes: Array[Node2D]) -> void:
	target_position = Vector2.INF
	clear_targets()
	for target: Node2D in nodes:
		if not is_instance_valid(target) or not target.is_inside_tree():
			continue
		var marker := _marker.duplicate() as Control
		add_child(marker)
		move_child(marker, _page.get_index())
		marker.show()
		_target_nodes.append(target)
		_target_markers.append(marker)


func clear_targets() -> void:
	for marker: Control in _target_markers:
		if is_instance_valid(marker):
			marker.hide()
			marker.queue_free()
	_target_nodes.clear()
	_target_markers.clear()


func set_completed(completed: bool) -> void:
	var color := COMPLETED_TEXT_COLOR if completed else DEFAULT_TEXT_COLOR
	_name_label.modulate = color
	_detail_name_label.modulate = color
	_detail_text_label.modulate = color


func get_target_count() -> int:
	return _target_nodes.size()

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
	if not _hud_allowed:
		_marker.hide()
		for marker: Control in _target_markers:
			if is_instance_valid(marker):
				marker.hide()
		return

	if target_position.is_finite():
		_position_marker(_marker, target_position)
	else:
		_marker.hide()

	for index: int in range(_target_nodes.size() - 1, -1, -1):
		var target := _target_nodes[index]
		var marker := _target_markers[index]
		if not is_instance_valid(target) or not target.is_inside_tree():
			if is_instance_valid(marker):
				marker.hide()
				marker.queue_free()
			_target_nodes.remove_at(index)
			_target_markers.remove_at(index)
			continue
		_position_marker(marker, target.global_position)


func _position_marker(marker: Control, world_position: Vector2) -> void:
	var vp := get_viewport()
	var cam := vp.get_camera_2d()
	if cam == null:
		marker.hide()
		return
	# ponytail: flat rectangular clamp to screen edge, no directional rotation
	var screen_pos: Vector2 = vp.canvas_transform * world_position
	var screen_size := vp.get_visible_rect().size
	var margin := 40.0
	screen_pos.x = clampf(screen_pos.x, margin, screen_size.x - margin)
	screen_pos.y = clampf(screen_pos.y, margin, screen_size.y - margin)
	marker.position = screen_pos - marker.size * 0.5
	marker.show()
