extends SceneTree

var _failures: Array[String] = []
var _chapter2_script: Script
var _events: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_chapter2_script = load("res://scenes/chapter_2/chapter_2.gd") as Script
	root.get_node("AudioManager").sfx_played.connect(func(key: StringName): _events.append(key))
	_test_chapter_2_image_pair_data()
	_test_image_only_left_cards()
	_test_legacy_text_pairs()
	_test_selected_border()
	_test_correct_pairs_share_distinct_borders()
	await _test_wrong_pair_flashes_and_retries()
	await _test_completion_preserves_signal_audio_and_pause()
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
	_expect(
		left.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"image card centers its illustration"
	)
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
	puzzle.open(
		"Match", [["L1", "R1"], ["L2", "R2"], ["L3", "R3"], ["L4", "R4"], ["L5", "R5"]]
	)
	var left_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn")
	var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
	var expected_colors: Array[Color] = [
		Color("f28c28"), Color("f2c94c"), Color("2f80ed"), Color("27ae60")
	]
	for i in 4:
		var left := left_column.get_child(i) as Button
		var right := _find_button_with_text(right_column, "R%d" % (i + 1))
		puzzle._on_left_pressed(left, i)
		puzzle._on_right_pressed(right, i)
		_expect(
			_border_color(left).is_equal_approx(expected_colors[i]),
			"correct pair %d uses its exact stable color" % i
		)
		_expect(
			_border_color(right).is_equal_approx(expected_colors[i]),
			"correct pair %d shares its exact color on the right" % i
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


func _test_wrong_pair_flashes_and_retries() -> void:
	var puzzle := _spawn_puzzle()
	puzzle.open("Match", [["L1", "R1"], ["L2", "R2"]])
	var left_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn")
	var right_column := puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn")
	var left := left_column.get_child(0) as Button
	var other_left := left_column.get_child(1) as Button
	var wrong := _find_button_with_text(right_column, "R2")
	puzzle._on_left_pressed(left, 0)
	puzzle._on_right_pressed(wrong, 1)
	await process_frame
	_expect(left.disabled and wrong.disabled, "wrong pair locks both cards during feedback")
	_expect(
		_border_color(left).is_equal_approx(Color("ef3340")),
		"wrong feedback begins with a red border"
	)
	puzzle._on_left_pressed(other_left, 1)
	_expect(
		_border_color(other_left).is_equal_approx(Color("705b43")),
		"wrong feedback blocks overlapping selection"
	)
	var red_flash_count := 0
	var was_red := false
	var lock_held := true
	var elapsed := 0.0
	while left.disabled and elapsed < 1.0:
		var is_red := _border_color(left).is_equal_approx(Color("ef3340"))
		if is_red and not was_red:
			red_flash_count += 1
		was_red = is_red
		lock_held = lock_held and wrong.disabled
		await create_timer(0.02).timeout
		elapsed += 0.02
	_expect(red_flash_count == 3, "wrong feedback shows exactly three red flashes")
	_expect(lock_held, "wrong feedback keeps both cards locked throughout all flashes")
	_expect(not left.disabled and not wrong.disabled, "wrong pair is selectable after feedback")
	_expect(
		_border_color(left).is_equal_approx(Color("705b43")),
		"wrong left border returns to neutral"
	)
	_expect(
		_border_color(wrong).is_equal_approx(Color("705b43")),
		"wrong right border returns to neutral"
	)
	puzzle._on_left_pressed(left, 0)
	var correct := _find_button_with_text(right_column, "R1")
	puzzle._on_right_pressed(correct, 0)
	_expect(left.disabled and correct.disabled, "retry can complete the correct pair")
	puzzle.free()


func _test_completion_preserves_signal_audio_and_pause() -> void:
	var puzzle := _spawn_puzzle()
	var solved_state := {"count": 0}
	puzzle.solved.connect(func(): solved_state.count += 1)
	puzzle.open("Match", [["L1", "R1"]])
	var left := (
		puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/LeftColumn").get_child(0) as Button
	)
	var right := (
		puzzle.get_node("Dim/Page/PageMargin/VBox/Columns/RightColumn").get_child(0) as Button
	)
	_events.clear()
	puzzle._on_left_pressed(left, 0)
	await puzzle._on_right_pressed(right, 0)
	_expect(_events == [&"answer_correct"], "completion keeps correct-answer audio")
	_expect(solved_state.count == 1, "completion emits solved once")
	_expect(not paused, "completion unpauses the scene tree")
	_expect(not puzzle.visible, "completion hides the puzzle")
	puzzle.free()


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
