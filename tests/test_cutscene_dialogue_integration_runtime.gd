extends SceneTree

const GameState := preload("res://scenes/core/game_state.gd")

const SCENE_DIALOGUE_PATHS := {
	"res://scenes/chapter_2/chapter_2.tscn": [
		"Chapter2IntroCutsceneLayer/Chapter2Cutscene/Dialogue",
		"Chapter2AbductionCutsceneLayer/AbductionCutscene/Dialogue",
		"Chapter2DeerCutsceneLayer/Chapter2DeerCutscene/Dialogue",
	],
	"res://scenes/chapter_2/chapter_2_second.tscn": [
		"Chapter2AbductionCutsceneLayer/AbductionCutscene/Dialogue",
	],
	"res://scenes/chapter_3/chapter_3.tscn": [
		"Chapter3CutsceneLayer/Chapter3Cutscene/Dialogue",
		"Chapter3CutsceneLayer/PostBattleCutscene/PostBattleDialogue",
	],
	"res://scenes/chapter_4/chapter_4.tscn": [
		"Chapter4CutsceneLayer/Chapter4Cutscene/Dialogue",
	],
	"res://scenes/chapter_5/chapter_5.tscn": [
		"Chapter5CutsceneLayer/Chapter5PostBossCutscene/Dialogue",
	],
	"res://scenes/chapter_6/chapter_6.tscn": [
		"Chapter6CutsceneLayer/Chapter6Cutscene/Dialogue",
	],
	"res://scenes/chapter_8/chapter_8.tscn": [
		"Chapter8CutsceneLayer/Chapter8Cutscene/Dialogue",
	],
	"res://scenes/chapter_9/chapter_9.tscn": [
		"Chapter9CutsceneLayer/Chapter9Cutscene/Dialogue",
		"Chapter9EndingCutsceneLayer/Chapter9EndingCutscene/Dialogue",
	],
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_presenter_instances()
	var transition := root.get_node("SceneTransition")
	transition.fade_duration = 0.01
	await _test_runtime_wiring(transition)
	transition.fade_duration = 1.0
	paused = false
	_finish()


func _test_presenter_instances() -> void:
	for scene_path: String in SCENE_DIALOGUE_PATHS:
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "%s loads" % scene_path)
		if packed == null:
			continue
		var scene := packed.instantiate()
		for node_path: String in SCENE_DIALOGUE_PATHS[scene_path]:
			var dialogue := scene.get_node_or_null(node_path)
			_expect(dialogue != null, "%s contains %s" % [scene_path, node_path])
			_expect(
				dialogue is CutsceneDialoguePresenter,
				"%s uses CutsceneDialoguePresenter at %s" % [scene_path, node_path]
			)
		scene.free()


func _test_runtime_wiring(transition: Node) -> void:
	var cutscene := await _mount_cutscene(
		"res://scenes/chapter_2/chapter_2.tscn",
		"Chapter2IntroCutsceneLayer/Chapter2Cutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "พระราม พระลักษมณ์ และนางสีดา")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_2/chapter_2.tscn",
		"Chapter2AbductionCutsceneLayer/AbductionCutscene",
		transition
	)
	_set_abduction_dialogues(cutscene)
	_expect_narration(cutscene, "Dialogue", 0, "พระรามไล่ตามจนในที่สุด")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_2/chapter_2.tscn",
		"Chapter2DeerCutsceneLayer/Chapter2DeerCutscene",
		transition
	)
	_expect_spoken(cutscene, "Dialogue", 1, "นางสีดา", "พระสวามี กวางตัวนั้นงดงามนัก")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_2/chapter_2_second.tscn",
		"Chapter2AbductionCutsceneLayer/AbductionCutscene",
		transition
	)
	_set_abduction_dialogues(cutscene)
	_expect_narration(cutscene, "Dialogue", 0, "พระรามไล่ตามจนในที่สุด")
	_release_cutscene(cutscene)

	GameState.chapter_3_intro_played = false
	cutscene = await _mount_cutscene(
		"res://scenes/chapter_3/chapter_3.tscn",
		"Chapter3CutsceneLayer/Chapter3Cutscene",
		transition
	)
	_expect_spoken(cutscene, "Dialogue", 0, "พระลักษมณ์", "พี่ราม ดูตรงนั้นสิ!")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_3/chapter_3.tscn",
		"Chapter3CutsceneLayer/PostBattleCutscene",
		transition
	)
	_expect_narration(cutscene, "PostBattleDialogue", 0, "หลังจากพระรามและพระลักษณ์")
	_expect_spoken(cutscene, "PostBattleDialogue", 3, "พระลักษณ์", "...ใครอยู่ตรงนั้น?")
	_release_cutscene(cutscene)

	GameState.chapter_4_intro_played = false
	cutscene = await _mount_cutscene(
		"res://scenes/chapter_4/chapter_4.tscn",
		"Chapter4CutsceneLayer/Chapter4Cutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "หลังจากหนุมานถวายตัวรับใช้พระราม")
	cutscene.set("_dialogue_phase", 1)
	_expect_spoken(cutscene, "Dialogue", 0, "หนุมาน", "พี่น้องวานรทั้งหลาย!")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_5/chapter_5.tscn",
		"Chapter5CutsceneLayer/Chapter5PostBossCutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "ไมยราพล้มลงกับพื้น")
	_expect_spoken(cutscene, "Dialogue", 3, "พระราม", "หนุมาน...")
	_release_cutscene(cutscene)

	GameState.chapter_6_intro_played = false
	cutscene = await _mount_cutscene(
		"res://scenes/chapter_6/chapter_6.tscn",
		"Chapter6CutsceneLayer/Chapter6Cutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "หลังจากหนุมานช่วยพระรามกลับมา")
	_release_cutscene(cutscene)

	GameState.chapter_8_intro_played = false
	cutscene = await _mount_cutscene(
		"res://scenes/chapter_8/chapter_8.tscn",
		"Chapter8CutsceneLayer/Chapter8Cutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "หลังจากพระรามฝ่าแนวป้องกัน")
	_release_cutscene(cutscene)

	GameState.chapter_9_intro_played = false
	GameState.chapter_9_thotsakan_defeated = false
	cutscene = await _mount_cutscene(
		"res://scenes/chapter_9/chapter_9.tscn",
		"Chapter9CutsceneLayer/Chapter9Cutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "หลังจากพระรามผ่านปริศนา")
	_release_cutscene(cutscene)

	cutscene = await _mount_cutscene(
		"res://scenes/chapter_9/chapter_9.tscn",
		"Chapter9EndingCutsceneLayer/Chapter9EndingCutscene",
		transition
	)
	_expect_narration(cutscene, "Dialogue", 0, "หลังการต่อสู้อันดุเดือด")
	_release_cutscene(cutscene)


func _mount_cutscene(scene_path: String, node_path: String, transition: Node) -> Control:
	var scene := (load(scene_path) as PackedScene).instantiate()
	var cutscene := scene.get_node(node_path) as Control
	cutscene.get_parent().remove_child(cutscene)
	scene.free()
	root.add_child(cutscene)
	while transition.is_busy():
		await process_frame
	await process_frame
	return cutscene


func _set_abduction_dialogues(cutscene: Control) -> void:
	var constants: Dictionary = cutscene.get_script().get_script_constant_map()
	var dialogues: Array[Dictionary] = []
	dialogues.assign(constants["CATCH_OPENING"] + constants["SHARED_TAIL"])
	cutscene.set("_dialogues", dialogues)


func _expect_narration(
	cutscene: Control, dialogue_path: String, index: int, expected_fragment: String
) -> void:
	cutscene.call("_show_dialogue", index, false)
	var presenter := cutscene.get_node(dialogue_path) as CutsceneDialoguePresenter
	var narration := presenter.get_node("Narration") as Label
	_expect(narration.visible, "%s line %d uses narration mode" % [cutscene.name, index])
	_expect(not presenter.get_node("Box").visible, "%s narration hides the box" % cutscene.name)
	_expect(
		narration.text.contains(expected_fragment),
		"%s narration reaches the presenter without its prefix" % cutscene.name
	)


func _expect_spoken(
	cutscene: Control,
	dialogue_path: String,
	index: int,
	expected_speaker: String,
	expected_fragment: String
) -> void:
	cutscene.call("_show_dialogue", index, false)
	var presenter := cutscene.get_node(dialogue_path) as CutsceneDialoguePresenter
	var box := presenter.get_node("Box") as NinePatchRect
	var name_label := presenter.get_node("Box/NameTag/NameLabel") as Label
	var text_label := presenter.get_node("Box/Margin/TextLabel") as Label
	_expect(box.visible, "%s line %d uses spoken mode" % [cutscene.name, index])
	_expect(not presenter.get_node("Narration").visible, "%s spoken line hides narration" % cutscene.name)
	_expect(name_label.text == expected_speaker, "%s shows the separate speaker tag" % cutscene.name)
	_expect(
		text_label.text.contains(expected_fragment),
		"%s sends only the spoken sentence to the body" % cutscene.name
	)
	_expect(not text_label.text.contains("“"), "%s body has no outer smart quotes" % cutscene.name)


func _release_cutscene(cutscene: Control) -> void:
	if is_instance_valid(cutscene):
		cutscene.free()
	paused = false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: cutscene dialogue integration runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
