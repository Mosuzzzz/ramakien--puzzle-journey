extends "res://scenes/props/portal.gd"

@export var sida_arrival_distance := 140.0


func _process(delta: float) -> void:
	super._process(delta)
	if _player:
		_update_prompt()


func _update_prompt() -> void:
	if not GameState.chapter_9_thotsakan_defeated:
		_prompt.text = "ต้องกำจัดทศกัณฐ์ก่อน"
	elif not GameState.chapter_9_sida_rescued:
		_prompt.text = "ต้องไปรับนางสีดาก่อน"
	elif not _is_sida_at_gate():
		_prompt.text = "พานางสีดามาที่จุดนี้"
	else:
		_prompt.text = prompt_text


func _use_portal() -> void:
	if (
		not GameState.chapter_9_thotsakan_defeated
		or not GameState.chapter_9_sida_rescued
		or not _is_sida_at_gate()
	):
		_update_prompt()
		get_viewport().set_input_as_handled()
		return

	var tree := get_tree()
	if tree == null:
		return
	var chapter := tree.current_scene
	if chapter != null and chapter.has_method("show_ending_cutscene"):
		chapter.call("show_ending_cutscene")
	get_viewport().set_input_as_handled()


func _is_sida_at_gate() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var chapter := tree.current_scene
	if chapter == null:
		return false
	var sida := chapter.get_node_or_null("YSortRoot/Sida") as Node2D
	return sida != null and sida.global_position.distance_to(global_position) <= sida_arrival_distance
