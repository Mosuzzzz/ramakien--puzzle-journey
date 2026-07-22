extends CanvasLayer

signal solved

const BUTTON_FONT := preload("res://assets/fonts/Sarabun-Regular.ttf")

@onready var _title_label: Label = $Dim/Page/PageMargin/VBox/TitleLabel
@onready var _left_column: VBoxContainer = $Dim/Page/PageMargin/VBox/Columns/LeftColumn
@onready var _right_column: VBoxContainer = $Dim/Page/PageMargin/VBox/Columns/RightColumn

var _pair_count := 0
var _selected_left: Button = null
var _selected_left_index := -1
var _matched := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


## pairs: Array of [left_text, right_text] — matching left item to its right description.
func open(title: String, pairs: Array) -> void:
	_pair_count = pairs.size()
	_matched = 0
	_selected_left = null
	_selected_left_index = -1
	_title_label.text = title

	for c in _left_column.get_children():
		c.queue_free()
	for c in _right_column.get_children():
		c.queue_free()

	for i in pairs.size():
		var left_btn := _make_button(pairs[i][0])
		left_btn.pressed.connect(_on_left_pressed.bind(left_btn, i))
		_left_column.add_child(left_btn)

	var right_order: Array = range(pairs.size())
	right_order.shuffle()
	for idx in right_order:
		var right_btn := _make_button(pairs[idx][1])
		right_btn.pressed.connect(_on_right_pressed.bind(right_btn, idx))
		_right_column.add_child(right_btn)

	get_tree().paused = true
	show()


func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(240, 46)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_override("font", BUTTON_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	return btn


func _on_left_pressed(btn: Button, index: int) -> void:
	if btn.disabled:
		return
	if _selected_left:
		_selected_left.modulate = Color.WHITE
	_selected_left = btn
	_selected_left_index = index
	btn.modulate = Color(1.3, 1.2, 0.6)


func _on_right_pressed(btn: Button, index: int) -> void:
	if _selected_left == null or btn.disabled:
		return

	if index == _selected_left_index:
		_selected_left.modulate = Color(0.5, 1.0, 0.5)
		_selected_left.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5)
		btn.disabled = true
		_selected_left = null
		_selected_left_index = -1
		_matched += 1
		if _matched >= _pair_count:
			await get_tree().create_timer(0.4).timeout
			_close_and_solve()
	else:
		var wrong_left := _selected_left
		_selected_left = null
		_selected_left_index = -1
		wrong_left.modulate = Color(1.0, 0.4, 0.4)
		btn.modulate = Color(1.0, 0.4, 0.4)
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(wrong_left) and not wrong_left.disabled:
			wrong_left.modulate = Color.WHITE
		if is_instance_valid(btn) and not btn.disabled:
			btn.modulate = Color.WHITE


func _close_and_solve() -> void:
	get_tree().paused = false
	hide()
	solved.emit()
