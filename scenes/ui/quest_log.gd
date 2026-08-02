extends CanvasLayer

const GameState := preload("res://scenes/core/game_state.gd")
const DEFAULT_TEXT_COLOR := Color.WHITE
const COMPLETED_TEXT_COLOR := Color("#67d56b")
const NOTIFICATION_BOB_DISTANCE := 7.0
const NOTIFICATION_BOB_SECONDS := 0.45
const NOTIFICATION_BUTTON_GAP := 6.0
const BUTTON_DIM_COLOR := Color(0.62, 0.62, 0.62, 1.0)
const BUTTON_PULSE_SCALE := Vector2(1.10, 1.10)
const BUTTON_PULSE_HALF_SECONDS := 0.65
const BUTTON_PULSE_REST_SECONDS := 0.50

var _hud_allowed := true
var _has_quest := false
var _completed := false
var _notification_unread := false
var _notification_base_y := 0.0
var _notification_tween: Tween
var _button_attention_tween: Tween
var target_position := Vector2.INF
var _target_nodes: Array[Node2D] = []
var _target_markers: Array[Control] = []

@onready var _button: TextureButton = $QuestButton
@onready var _page: Control = $PageDim
@onready var _name_label: Label = $PageDim/Page/PageMargin/Columns/QuestList/QuestEntry/QuestNameLabel
@onready var _detail_name_label: Label = $PageDim/Page/PageMargin/Columns/Detail/DetailNameLabel
@onready var _detail_text_label: Label = $PageDim/Page/PageMargin/Columns/Detail/PageTextLabel
@onready var _marker: Control = $QuestMarker
@onready var _notification: TextureRect = $QuestNotification

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.hide()
	_page.hide()
	_marker.hide()
	_notification.hide()
	_button.pivot_offset = _button.size * 0.5
	_position_notification_below_button()
	_notification_base_y = _notification.position.y
	_notification_tween = create_tween().set_loops()
	_notification_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_notification_tween.tween_property(
		_notification, "position:y", _notification_base_y + NOTIFICATION_BOB_DISTANCE,
		NOTIFICATION_BOB_SECONDS
	)
	_notification_tween.tween_property(
		_notification, "position:y", _notification_base_y, NOTIFICATION_BOB_SECONDS
	)

func set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void:
	var changed := (not _has_quest or _name_label.text != quest_name
		or _detail_text_label.text != detail or _completed)
	clear_targets()
	_apply_completed(false)
	_name_label.text = quest_name
	_detail_name_label.text = quest_name
	_detail_text_label.text = detail
	_has_quest = true
	_button.visible = _hud_allowed
	target_position = target
	if changed:
		_set_notification_unread(true)

func clear() -> void:
	_has_quest = false
	_button.hide()
	_page.hide()
	target_position = Vector2.INF
	clear_targets()
	_apply_completed(false)
	_set_notification_unread(false)


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
	if _completed == completed:
		return
	_apply_completed(completed)
	if _has_quest:
		_set_notification_unread(true)


func _apply_completed(completed: bool) -> void:
	_completed = completed
	var color := COMPLETED_TEXT_COLOR if completed else DEFAULT_TEXT_COLOR
	_name_label.modulate = color
	_detail_name_label.modulate = color
	_detail_text_label.modulate = color


func get_target_count() -> int:
	return _target_nodes.size()


func is_completed() -> bool:
	return _completed


func has_unread_notification() -> bool:
	return _notification_unread


func _set_notification_unread(unread: bool) -> void:
	var was_unread := _notification_unread
	_notification_unread = unread
	_notification.visible = _hud_allowed and _has_quest and unread
	if unread:
		if not was_unread:
			_start_button_attention()
	else:
		_stop_button_attention()


func _position_notification_below_button() -> void:
	_notification.position = Vector2(
		_button.position.x + (_button.size.x - _notification.size.x) * 0.5,
		_button.position.y + _button.size.y + NOTIFICATION_BUTTON_GAP
	)


func _start_button_attention() -> void:
	_stop_button_attention()
	_button_attention_tween = create_tween().set_loops()
	_button_attention_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_button_attention_tween.tween_property(
		_button, "modulate", BUTTON_DIM_COLOR, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.parallel().tween_property(
		_button, "scale", BUTTON_PULSE_SCALE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.tween_property(
		_button, "modulate", Color.WHITE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.parallel().tween_property(
		_button, "scale", Vector2.ONE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.tween_interval(BUTTON_PULSE_REST_SECONDS)


func _stop_button_attention() -> void:
	if _button_attention_tween != null:
		_button_attention_tween.kill()
		_button_attention_tween = null
	_button.modulate = Color.WHITE
	_button.scale = Vector2.ONE

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
	_notification.visible = shown and _has_quest and _notification_unread
	if not shown:
		_page.hide()

func _on_quest_button_pressed() -> void:
	_set_notification_unread(false)
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
