extends CanvasLayer

signal solved

const BUTTON_FONT := preload("res://assets/fonts/Sarabun-Regular.ttf")
const NEUTRAL_FILL_COLOR := Color("6f6557")
const NEUTRAL_BORDER_COLOR := Color("514638")
const SELECTED_FILL_COLOR := Color("e9b949")
const SELECTED_BORDER_COLOR := Color("9b6a12")
const WRONG_FILL_COLOR := Color("ef3340")
const WRONG_BORDER_COLOR := Color("9e1520")
const DARK_TEXT_COLOR := Color("3b2108")
const LIGHT_TEXT_COLOR := Color("ffffff")
const PAIR_FILL_COLORS: Array[Color] = [
	Color("f28c28"),
	Color("f2c94c"),
	Color("2f80ed"),
	Color("27ae60"),
]
const PAIR_BORDER_COLORS: Array[Color] = [
	Color("a95000"),
	Color("9b7900"),
	Color("1555a5"),
	Color("16723c"),
]
const PAIR_TEXT_COLORS: Array[Color] = [
	DARK_TEXT_COLOR,
	DARK_TEXT_COLOR,
	LIGHT_TEXT_COLOR,
	LIGHT_TEXT_COLOR,
]
const WRONG_FLASH_COUNT := 3
const WRONG_FLASH_INTERVAL := 0.10

@onready var _title_label: Label = $Dim/Page/PageMargin/VBox/TitleLabel
@onready var _left_column: VBoxContainer = $Dim/Page/PageMargin/VBox/Columns/LeftColumn
@onready var _right_column: VBoxContainer = $Dim/Page/PageMargin/VBox/Columns/RightColumn

var _pair_count := 0
var _selected_left: Button = null
var _selected_left_index := -1
var _matched := 0
var _feedback_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


## Each pair is either [left_text, right_text] or
## {"left_image": resource_path, "right_text": description}.
func open(title: String, pairs: Array) -> void:
	_pair_count = pairs.size()
	_matched = 0
	_selected_left = null
	_selected_left_index = -1
	_feedback_active = false
	_title_label.text = title

	for c in _left_column.get_children():
		c.queue_free()
	for c in _right_column.get_children():
		c.queue_free()

	for i in pairs.size():
		var left_btn := _make_left_button(pairs[i])
		_left_column.add_child(left_btn)
		left_btn.pressed.connect(_on_left_pressed.bind(left_btn, i))

	var right_order: Array = range(pairs.size())
	right_order.shuffle()
	for idx in right_order:
		var right_btn := _make_text_button(_pair_right_text(pairs[idx]))
		_right_column.add_child(right_btn)
		right_btn.pressed.connect(_on_right_pressed.bind(right_btn, idx))

	get_tree().paused = true
	show()


func _make_left_button(pair: Variant) -> Button:
	if pair is Dictionary:
		var btn := _make_base_button()
		var image_path := str(pair.get("left_image", ""))
		if ResourceLoader.exists(image_path):
			btn.icon = load(image_path) as Texture2D
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.add_theme_constant_override("icon_max_width", 220)
		return btn
	return _make_text_button(str(pair[0]))


func _pair_right_text(pair: Variant) -> String:
	if pair is Dictionary:
		return str(pair.get("right_text", ""))
	return str(pair[1])


func _make_text_button(label: String) -> Button:
	var btn := _make_base_button()
	btn.text = label
	return btn


func _make_base_button() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 92)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_override("font", BUTTON_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	_set_card_style(
		btn, NEUTRAL_FILL_COLOR, NEUTRAL_BORDER_COLOR, LIGHT_TEXT_COLOR, 2
	)
	return btn


func _set_card_style(
	button: Button,
	fill_color: Color,
	border_color: Color,
	text_color: Color,
	width: int = 4
) -> void:
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill_color
		style.border_color = border_color
		style.set_border_width_all(width)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)
	for color_name in [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
		&"font_disabled_color",
	]:
		button.add_theme_color_override(color_name, text_color)
	for icon_color_name in [
		&"icon_normal_color",
		&"icon_hover_color",
		&"icon_pressed_color",
		&"icon_hover_pressed_color",
		&"icon_focus_color",
		&"icon_disabled_color",
	]:
		button.add_theme_color_override(icon_color_name, Color.WHITE)


func _on_left_pressed(btn: Button, index: int) -> void:
	if btn.disabled or _feedback_active:
		return
	if _selected_left:
		_set_card_style(
			_selected_left,
			NEUTRAL_FILL_COLOR,
			NEUTRAL_BORDER_COLOR,
			LIGHT_TEXT_COLOR,
			2
		)
	_selected_left = btn
	_selected_left_index = index
	_set_card_style(
		btn, SELECTED_FILL_COLOR, SELECTED_BORDER_COLOR, DARK_TEXT_COLOR
	)


func _on_right_pressed(btn: Button, index: int) -> void:
	if _selected_left == null or btn.disabled or _feedback_active:
		return

	if index == _selected_left_index:
		AudioManager.play_sfx(AudioManager.ANSWER_CORRECT)
		var palette_index := index % PAIR_FILL_COLORS.size()
		_set_card_style(
			_selected_left,
			PAIR_FILL_COLORS[palette_index],
			PAIR_BORDER_COLORS[palette_index],
			PAIR_TEXT_COLORS[palette_index]
		)
		_selected_left.disabled = true
		_set_card_style(
			btn,
			PAIR_FILL_COLORS[palette_index],
			PAIR_BORDER_COLORS[palette_index],
			PAIR_TEXT_COLORS[palette_index]
		)
		btn.disabled = true
		_selected_left = null
		_selected_left_index = -1
		_matched += 1
		if _matched >= _pair_count:
			await get_tree().create_timer(0.4).timeout
			_close_and_solve()
	else:
		AudioManager.play_sfx(AudioManager.ANSWER_WRONG)
		var wrong_left := _selected_left
		_selected_left = null
		_selected_left_index = -1
		await _flash_wrong_pair(wrong_left, btn)


func _flash_wrong_pair(left: Button, right: Button) -> void:
	_feedback_active = true
	left.disabled = true
	right.disabled = true
	for flash_index in WRONG_FLASH_COUNT:
		_set_card_style(left, WRONG_FILL_COLOR, WRONG_BORDER_COLOR, LIGHT_TEXT_COLOR)
		_set_card_style(right, WRONG_FILL_COLOR, WRONG_BORDER_COLOR, LIGHT_TEXT_COLOR)
		await get_tree().create_timer(WRONG_FLASH_INTERVAL).timeout
		_set_card_style(
			left, NEUTRAL_FILL_COLOR, NEUTRAL_BORDER_COLOR, LIGHT_TEXT_COLOR, 2
		)
		_set_card_style(
			right, NEUTRAL_FILL_COLOR, NEUTRAL_BORDER_COLOR, LIGHT_TEXT_COLOR, 2
		)
		if flash_index < WRONG_FLASH_COUNT - 1:
			await get_tree().create_timer(WRONG_FLASH_INTERVAL).timeout
	if is_instance_valid(left):
		left.disabled = false
	if is_instance_valid(right):
		right.disabled = false
	_feedback_active = false


func _close_and_solve() -> void:
	get_tree().paused = false
	hide()
	solved.emit()
