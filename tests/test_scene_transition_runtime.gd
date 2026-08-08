extends SceneTree

const TRANSITION_SCRIPT_PATH := "res://scenes/core/scene_transition.gd"
const HANDOFF_SCENE := "res://tests/fixtures/transition_cutscene_destination.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var transition_script := load(TRANSITION_SCRIPT_PATH) as GDScript
	_expect(transition_script != null, "SceneTransition service exists")
	if transition_script == null:
		_finish()
		return

	var transition := transition_script.new() as CanvasLayer
	transition.name = "SceneTransitionUnderTest"
	_expect(
		is_equal_approx(transition.fade_duration, 1.0),
		"production fade duration defaults to one second"
	)
	transition.fade_duration = 0.01
	root.add_child(transition)
	await process_frame

	var first_open := {"prepared": false}
	transition.open_cutscene(func(): first_open.prepared = true)
	await process_frame
	_expect(transition.is_busy(), "opening locks overlapping transition input")
	var rejected_close := {"finalized": false}
	transition.close_cutscene(func(): rejected_close.finalized = true)
	_expect(not rejected_close.finalized, "busy transition rejects overlapping close")
	while transition.is_busy():
		await process_frame
	_expect(first_open.prepared, "accepted opening still completes")

	var second_open := {"prepared": false}
	await transition.open_cutscene(func(): second_open.prepared = true)
	_expect(second_open.prepared, "opening prepares cutscene while black")
	_expect(not transition.is_busy(), "opening unlocks after reveal")
	_expect(is_zero_approx(transition.overlay_alpha()), "opening ends clear")

	var close_result := {"finalized": false}
	await transition.close_cutscene(func(): close_result.finalized = true)
	_expect(close_result.finalized, "closing finalizes cutscene while black")
	_expect(not transition.is_busy(), "closing unlocks after reveal")
	_expect(is_zero_approx(transition.overlay_alpha()), "closing ends clear")

	transition.free()

	var shared_transition := root.get_node_or_null("SceneTransition")
	_expect(shared_transition != null, "SceneTransition autoload exists")
	if shared_transition != null:
		root.set_meta("transition_handoff_prepared", false)
		shared_transition.fade_duration = 0.01
		var handoff_fades: Array[float] = []
		shared_transition.fade_started.connect(
			func(alpha: float): handoff_fades.append(alpha)
		)
		var error: Error = await shared_transition.change_chapter(HANDOFF_SCENE)
		while shared_transition.is_busy():
			await process_frame
		_expect(error == OK, "chapter handoff loads destination")
		_expect(
			root.get_meta("transition_handoff_prepared", false),
			"destination cutscene claims handoff"
		)
		_expect(handoff_fades == [1.0, 0.0], "chapter plus cutscene uses one fade pair")
		shared_transition.fade_duration = 1.0

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: scene transition runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
