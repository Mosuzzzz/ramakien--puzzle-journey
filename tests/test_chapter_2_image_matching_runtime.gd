extends SceneTree

var _failures: Array[String] = []
var _chapter2_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_chapter2_script = load("res://scenes/chapter_2/chapter_2.gd") as Script
	_test_chapter_2_image_pair_data()
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
