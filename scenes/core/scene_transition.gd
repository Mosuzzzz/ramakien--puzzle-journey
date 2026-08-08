extends CanvasLayer

const DEFAULT_FADE_DURATION := 1.0

enum HandoffState {
	NONE,
	PENDING,
	CLAIMED,
}

signal fade_started(target_alpha: float)

var fade_duration := DEFAULT_FADE_DURATION
var _busy := false
var _handoff_state := HandoffState.NONE
var _shade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5000
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = Color(0, 0, 0, 0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func is_busy() -> bool:
	return _busy


func overlay_alpha() -> float:
	return _shade.color.a if is_instance_valid(_shade) else 0.0


func open_cutscene(prepare: Callable) -> void:
	if _handoff_state == HandoffState.PENDING and _busy:
		_handoff_state = HandoffState.CLAIMED
		prepare.call()
		await _fade_to(0.0)
		_release()
		_handoff_state = HandoffState.NONE
		return
	if _busy:
		return
	_acquire()
	await _fade_to(1.0)
	prepare.call()
	await _fade_to(0.0)
	_release()


func close_cutscene(finalize: Callable) -> void:
	if _busy:
		return
	_acquire()
	await _fade_to(1.0)
	finalize.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_release()


func change_chapter(scene_path: String) -> Error:
	if _busy:
		return ERR_BUSY
	_acquire()
	await _fade_to(1.0)
	_handoff_state = HandoffState.PENDING
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_handoff_state = HandoffState.NONE
		await _fade_to(0.0)
		_release()
		return error
	await get_tree().process_frame
	await get_tree().process_frame
	if _handoff_state == HandoffState.PENDING:
		_handoff_state = HandoffState.NONE
		await _fade_to(0.0)
		_release()
	return OK


func _acquire() -> void:
	_busy = true
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	AudioManager.stop_run_loop()


func _release() -> void:
	_busy = false
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_to(alpha: float) -> void:
	fade_started.emit(alpha)
	var tween := create_tween()
	tween.tween_property(_shade, "color:a", alpha, fade_duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
