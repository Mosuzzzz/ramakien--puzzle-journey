extends SceneTree

var _failures: Array[String] = []
var _chapter2_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_chapter2_script = load("res://scenes/chapter_2/chapter_2.gd") as Script
	_test_chapter_2_image_pair_data()
	_test_image_only_left_cards()
	_test_legacy_text_pairs()
	_test_selected_border()
	_test_correct_pairs_share_distinct_borders()
	_finish()


func _test_chapter_2_image_pair_data() -> void:
	var expected_paths := [
		"res://assets/puzzles/chapter_2/firewood.png",
		"res://assets/puzzles/chapter_2/stream_water.png",
		"res://assets/puzzles/chapter_2/herbs.png",
		"res://assets/puzzles/chapter_2/dry_leaves.png",
	]
	var expected_right := [
		"สำหรับก่อไฟหุงหาอาหาร",
		"สำหรับดื่มและประกอบอาหาร",
		"สำหรับรักษาบาดแผล",
		"สำหรับปูที่นอน",
	]
	var supply_pairs: Array = _chapter2_script.get_script_constant_map().SUPPLY_PAIRS
	_expect(supply_pairs.size() == 4, "Chapter 2 defines four supply pairs")
	for i in expected_paths.size():
		var pair: Variant = supply_pairs[i]
		_expect(pair is Dictionary, "supply pair %d uses structured image data" % i)
		if pair is Dictionary:
			_expect(
				pair.get("left_image", "") == expected_paths[i],
				"supply pair %d image path" % i
			)
			_expect(
				pair.get("right_text", "") == expected_right[i],
				"supply pair %d description" % i
			)
		_expect(ResourceLoader.exists(expected_paths[i]), "supply image %d exists" % i)


func _test_image_only_left_cards() -> void:
	var puzzle := _spawn_puzzle()
	var pair: Dictionary = _chapter2_script.get_script_constant_map().SUPPLY_PAIRS[0]
	puzzle.open("Match", [pair])
	var left_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn")
	_expect(left_column.get_child_count() == 1, "image pair creates one left card")
	if left_column.get_child_count() != 1:
		puzzle.free()
		return
	var left := left_column.get_child(0) as Button
	_expect(left.text.is_empty(), "image card has no caption")
	_expect(left.icon != null, "image card loads its illustration")
	_expect(left.expand_icon, "image card scales its illustration")
	puzzle.free()


func _test_legacy_text_pairs() -> void:
	var puzzle := _spawn_puzzle()
	puzzle.open("Match", [["L1", "R1"]])
	var left := (
		puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
	)
	var right := (
		puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn").get_child(0) as Button
	)
	_expect(left.text == "L1", "legacy left text remains supported")
	_expect(left.icon == null, "legacy left card has no image")
	_expect(right.text == "R1", "legacy right text remains supported")
	puzzle.free()


func _spawn_puzzle() -> CanvasLayer:
	var puzzle := (load("res://scenes/ui/matching_puzzle.tscn") as PackedScene).instantiate()
	root.add_child(puzzle)
	return puzzle


func _test_selected_border() -> void:
	var puzzle := _spawn_puzzle()
	puzzle.open("Match", [["L1", "R1"]])
	var left := (
		puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
	)
	puzzle._on_left_pressed(left, 0)
	_expect(
		_border_color(left).is_equal_approx(Color("e9b949")),
		"selected card uses gold border"
	)
	puzzle.free()


func _test_correct_pairs_share_distinct_borders() -> void:
	var puzzle := _spawn_puzzle()
	puzzle.open("Match", [["L1", "R1"], ["L2", "R2"]])
	var left_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn")
	var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
	var observed: Array[Color] = []
	for i in 2:
		var left := left_column.get_child(i) as Button
		var right := _find_button_with_text(right_column, "R%d" % (i + 1))
		puzzle._on_left_pressed(left, i)
		puzzle._on_right_pressed(right, i)
		_expect(
			_border_color(left).is_equal_approx(_border_color(right)),
			"correct pair %d shares one border color" % i
		)
		observed.append(_border_color(left))
	_expect(
		not observed[0].is_equal_approx(observed[1]),
		"different correct pairs use distinct colors"
	)
	puzzle.free()


func _border_color(button: Button) -> Color:
	var style := button.get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		return style.border_color
	return Color.TRANSPARENT


func _find_button_with_text(parent: Node, expected_text: String) -> Button:
	for child: Button in parent.get_children():
		if child.text == expected_text:
			return child
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: Chapter 2 image matching")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
