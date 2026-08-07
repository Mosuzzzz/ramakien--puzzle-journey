extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const QUEST_EXPLORE_NAME := "สำรวจพระราชวังเพื่อหานางสีดา"
const QUEST_EXPLORE_DETAIL := "สำรวจห้องต่าง ๆ ภายในพระราชวังและตามหานางสีดา"
const QUEST_BOSS_NAME := "เดินทางไปปราบทศกัณฐ์"
const QUEST_BOSS_DETAIL := "หาทางไปยังท้องพระโรงและปราบทศกัณฐ์เพื่อปลดล็อกห้องนางสีดา"
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"

@onready var _sida: CharacterBody2D = $YSortRoot/Sida


func _ready() -> void:
	$RoomEntranceLeftUpper.locked_prompt_text = "ห้องถูกล็อก ต้องกำจัดทศกัณฐ์ก่อน"
	$RoomEntranceLeftUpper.set_locked(not GameState.chapter_9_thotsakan_defeated)
	if not $RoomEntranceLeftUpper.locked_interaction.is_connected(_on_sida_room_locked_interaction):
		$RoomEntranceLeftUpper.locked_interaction.connect(_on_sida_room_locked_interaction)

	if GameState.chapter_9_sida_rescued:
		_show_rescue_quest()
		Quest.set_completed(true)
	elif GameState.chapter_9_thotsakan_defeated:
		_show_rescue_quest()
	elif GameState.chapter_8_sida_room_discovered:
		_show_defeat_thotsakan_quest()
	else:
		Quest.set_quest(QUEST_EXPLORE_NAME, QUEST_EXPLORE_DETAIL)

	if GameState.chapter_9_sida_rescued:
		$YSortRoot/Sida.start_following()
	else:
		_sida.queue_free()


func _on_sida_room_locked_interaction(_portal: Area2D) -> void:
	if GameState.chapter_8_sida_room_discovered:
		return
	GameState.chapter_8_sida_room_discovered = true
	_show_defeat_thotsakan_quest()


func _show_defeat_thotsakan_quest() -> void:
	Quest.set_quest(QUEST_BOSS_NAME, QUEST_BOSS_DETAIL)


func _show_rescue_quest() -> void:
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)
