extends CanvasLayer

const GameState := preload("res://scenes/core/game_state.gd")
const DEFAULT_TEXT_COLOR := Color.WHITE
const COMPLETED_TEXT_COLOR := Color("#67d56b")
const BUTTON_DIM_COLOR := Color(0.62, 0.62, 0.62, 1.0)
const BUTTON_PULSE_SCALE := Vector2(1.10, 1.10)
const BUTTON_PULSE_HALF_SECONDS := 0.65
const BUTTON_PULSE_REST_SECONDS := 0.50
const LEFT_TITLE_SIZE := 17
const LEFT_TITLE_MIN_SIZE := 15
const RIGHT_TITLE_SIZE := 24
const RIGHT_TITLE_MIN_SIZE := 20
const MIN_LINE_WIDTH_RATIO := 0.35
const PREFERRED_BREAK_MARKERS: Array[String] = [
	"เพื่อ", "ไปยัง", "ใต้", "จาก", "และ", "ช่วย", "ตาม"
]

var _hud_allowed := true
var _has_quest := false
var _completed := false
var _quest_name := ""
var _notification_unread := false
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_name_label.label_settings = _name_label.label_settings.duplicate() as LabelSettings
	_detail_name_label.label_settings = _detail_name_label.label_settings.duplicate() as LabelSettings
	_button.hide()
	_page.hide()
	_marker.hide()
	_button.pivot_offset = _button.size * 0.5

func set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void:
	var changed := (not _has_quest or _quest_name != quest_name
		or _detail_text_label.text != detail or _completed)
	clear_targets()
	_apply_completed(false)
	_quest_name = quest_name
	_name_label.text = quest_name
	_detail_name_label.text = quest_name
	_detail_text_label.text = detail
	_has_quest = true
	_button.visible = _hud_allowed
	target_position = target
	call_deferred("_layout_quest_titles")
	if changed:
		_set_notification_unread(true)

func clear() -> void:
	_has_quest = false
	_quest_name = ""
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
	if unread:
		if not was_unread:
			_start_button_attention()
	else:
		_stop_button_attention()

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
	return {"name": _quest_name, "detail": _detail_text_label.text, "target": target}

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
	_set_notification_unread(false)
	_page.visible = not _page.visible
	if _page.visible:
		call_deferred("_layout_quest_titles")


func _layout_quest_titles() -> void:
	if not _has_quest:
		return
	_fit_title(_name_label, _quest_name, LEFT_TITLE_SIZE, LEFT_TITLE_MIN_SIZE)
	_fit_title(_detail_name_label, _quest_name, RIGHT_TITLE_SIZE, RIGHT_TITLE_MIN_SIZE)


func _fit_title(label: Label, canonical_text: String, normal_size: int, minimum_size: int) -> void:
	label.text = canonical_text
	label.label_settings.font_size = normal_size
	label.custom_minimum_size.y = 0.0
	var available_width := label.size.x
	if available_width <= 1.0:
		return
	var font := label.label_settings.font
	for font_size in range(normal_size, minimum_size - 1, -1):
		if _text_width(font, canonical_text, font_size) <= available_width:
			label.label_settings.font_size = font_size
			return
	label.label_settings.font_size = minimum_size
	var wrapped := _balanced_title_break(canonical_text, font, minimum_size, available_width)
	label.text = wrapped
	if wrapped.contains("\n"):
		label.custom_minimum_size.y = font.get_height(minimum_size) * 2.0 + 4.0


func _balanced_title_break(
	canonical_text: String, font: Font, font_size: int, available_width: float
) -> String:
	var preferred: Array[int] = []
	for marker in PREFERRED_BREAK_MARKERS:
		var search_from := 1
		while search_from < canonical_text.length():
			var position := canonical_text.find(marker, search_from)
			if position < 0:
				break
			if _is_safe_break(canonical_text, position):
				preferred.append(position)
			search_from = position + marker.length()
	var result := _best_balanced_break(
		canonical_text, preferred, font, font_size, available_width
	)
	if not result.is_empty():
		return result

	var fallback: Array[int] = []
	var first_position := ceili(canonical_text.length() * MIN_LINE_WIDTH_RATIO)
	var last_position := floori(canonical_text.length() * (1.0 - MIN_LINE_WIDTH_RATIO))
	for position in range(first_position, last_position + 1):
		if _is_safe_break(canonical_text, position):
			fallback.append(position)
	result = _best_balanced_break(canonical_text, fallback, font, font_size, available_width)
	return canonical_text if result.is_empty() else result


func _best_balanced_break(
	canonical_text: String,
	candidates: Array[int],
	font: Font,
	font_size: int,
	available_width: float
) -> String:
	var best_text := ""
	var best_difference := INF
	for position in candidates:
		var first_line := canonical_text.substr(0, position).strip_edges()
		var second_line := canonical_text.substr(position).strip_edges()
		if first_line.is_empty() or second_line.is_empty():
			continue
		var first_width := _text_width(font, first_line, font_size)
		var second_width := _text_width(font, second_line, font_size)
		if first_width > available_width or second_width > available_width:
			continue
		var total_width := first_width + second_width
		if minf(first_width, second_width) / maxf(total_width, 1.0) < MIN_LINE_WIDTH_RATIO:
			continue
		var difference := absf(first_width - second_width)
		if difference < best_difference:
			best_difference = difference
			best_text = first_line + "\n" + second_line
	return best_text


func _is_safe_break(text: String, position: int) -> bool:
	if position <= 0 or position >= text.length():
		return false
	var next_codepoint := text.unicode_at(position)
	return not (
		next_codepoint == 0x0E31
		or (next_codepoint >= 0x0E34 and next_codepoint <= 0x0E3A)
		or (next_codepoint >= 0x0E47 and next_codepoint <= 0x0E4E)
	)


func _text_width(font: Font, text: String, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func _close_page() -> void:
	_page.hide()

func _process(_delta: float) -> void:
	_update_marker()

func _update_marker() -> void:
	if not _hud_allowed or not Settings.hints_enabled:
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
