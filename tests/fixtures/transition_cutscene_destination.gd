extends Node


func _ready() -> void:
	SceneTransition.open_cutscene(func():
		get_tree().root.set_meta("transition_handoff_prepared", true)
	)
