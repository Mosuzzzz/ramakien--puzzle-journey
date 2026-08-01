extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const QUEST_DEFEND_NAME := "ปราบยักษ์ป้องกันเมือง"
const QUEST_DEFEND_DETAIL := "กำจัดยักษ์ทั้งสามตนที่ป้องกันเส้นทางเข้าเมือง"
const QUEST_INFILTRATE_NAME := "ลักลอบเข้าไปในวังทศกัณฐ์"
const QUEST_INFILTRATE_DETAIL := "เดินทางต่อและหาทางลักลอบเข้าไปในพระราชวังลงกา"

var _defeated_ids: Dictionary = {}

func _ready() -> void:
	var defenders: Array[Node] = []
	for defender_name in [&"Mob1", &"Mob2", &"Mob3"]:
		var defender := get_node_or_null("YSortRoot/%s" % defender_name)
		if defender != null:
			defenders.append(defender)
	if GameState.chapter_7_defenders_cleared:
		for defender in defenders:
			defender.queue_free()
		_show_infiltration_quest()
		return
	Quest.set_quest(QUEST_DEFEND_NAME, QUEST_DEFEND_DETAIL)
	for defender in defenders:
		if defender.has_signal("defeated"):
			defender.defeated.connect(_on_defender_defeated)

func _on_defender_defeated(defender: CharacterBody2D) -> void:
	var defender_id := defender.get_instance_id()
	if _defeated_ids.has(defender_id):
		return
	_defeated_ids[defender_id] = true
	if _defeated_ids.size() < 3:
		return
	GameState.chapter_7_defenders_cleared = true
	_show_infiltration_quest()

func _show_infiltration_quest() -> void:
	Quest.set_quest(QUEST_INFILTRATE_NAME, QUEST_INFILTRATE_DETAIL)
