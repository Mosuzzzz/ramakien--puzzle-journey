extends SceneTree

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
	_finish()


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
