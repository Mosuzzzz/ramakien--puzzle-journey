extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const QUEST_BOSS_NAME := "ปราบทศกัณฐ์"
const QUEST_BOSS_DETAIL := "เอาชนะทศกัณฐ์เพื่อปลดล็อกห้องที่คุมขังนางสีดา"
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"

@onready var _thotsakan: CharacterBody2D = $YSortRoot/Thotsakan
@onready var _sida: CharacterBody2D = $YSortRoot/Sida
@onready var _ending_cutscene: Control = $Chapter9EndingCutsceneLayer/Chapter9EndingCutscene


func _ready() -> void:
	if GameState.chapter_9_thotsakan_defeated:
		_show_rescue_quest()
		if GameState.chapter_9_sida_rescued:
			Quest.set_completed(true)
		AudioManager.restore_background_music(0.0)
		_thotsakan.queue_free()
	elif not _thotsakan.defeated.is_connected(_on_thotsakan_defeated):
		Quest.set_quest(QUEST_BOSS_NAME, QUEST_BOSS_DETAIL)
		AudioManager.play_boss_music()
		_thotsakan.defeated.connect(_on_thotsakan_defeated)

	if GameState.chapter_9_sida_rescued:
		_sida.start_following()
	else:
		_sida.queue_free()


func _on_thotsakan_defeated(_defeated_thotsakan: CharacterBody2D) -> void:
	GameState.chapter_9_thotsakan_defeated = true
	AudioManager.restore_background_music()
	_show_rescue_quest()


func _show_rescue_quest() -> void:
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)


func show_ending_cutscene() -> void:
	_ending_cutscene.show_cutscene()
