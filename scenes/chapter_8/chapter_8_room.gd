extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"

@onready var _sida: CharacterBody2D = $YSortRoot/Sida


func _ready() -> void:
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)
	if not _sida.following_started.is_connected(_on_sida_following_started):
		_sida.following_started.connect(_on_sida_following_started)
	if GameState.chapter_9_sida_rescued:
		_sida.start_following()
		Quest.set_completed(true)


func _on_sida_following_started() -> void:
	GameState.chapter_9_sida_rescued = true
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)
	Quest.set_completed(true)
