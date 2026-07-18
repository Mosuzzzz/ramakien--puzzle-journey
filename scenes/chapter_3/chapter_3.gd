extends Node2D

var _post_battle_cutscene_started := false

@onready var _post_battle_cutscene: Control = $Chapter3CutsceneLayer/PostBattleCutscene
@onready var _hanuman: CharacterBody2D = $YSortRoot/Hanuman


func _ready() -> void:
	_hide_hanuman_until_all_cutscenes_finish()
	for mob_name: String in ["Mob1", "Mob2"]:
		var mob := get_node_or_null("YSortRoot/%s" % mob_name)
		if mob != null:
			mob.tree_exited.connect(_on_mob_removed)


func _on_mob_removed() -> void:
	call_deferred("_check_all_mobs_defeated")


func _check_all_mobs_defeated() -> void:
	if _post_battle_cutscene_started or not is_inside_tree():
		return
	if get_node_or_null("YSortRoot/Mob1") != null:
		return
	if get_node_or_null("YSortRoot/Mob2") != null:
		return
	_post_battle_cutscene_started = true
	_post_battle_cutscene.call("show_cutscene")


func _hide_hanuman_until_all_cutscenes_finish() -> void:
	_hanuman.hide()
	_hanuman.process_mode = Node.PROCESS_MODE_DISABLED


func reveal_hanuman_after_all_cutscenes() -> void:
	# Call this from the final Chapter 3 cutscene when the remaining story is ready.
	_hanuman.process_mode = Node.PROCESS_MODE_INHERIT
	_hanuman.show()
