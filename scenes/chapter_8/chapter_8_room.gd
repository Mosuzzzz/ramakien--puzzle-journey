extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"
const CHAPTER_9_SCENE := "res://scenes/chapter_9/chapter_9.tscn"
const CHAPTER_9_SPAWN := Vector2(718, 995)

@onready var _sida: CharacterBody2D = $YSortRoot/Sida
@onready var _player: CharacterBody2D = $YSortRoot/Player

var _transitioning_to_chapter_9 := false


func _ready() -> void:
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)
	if not _sida.following_started.is_connected(_on_sida_following_started):
		_sida.following_started.connect(_on_sida_following_started)
	if GameState.chapter_9_sida_rescued:
		_sida.start_following()
		Quest.set_completed(true)


func _on_sida_following_started() -> void:
	if _transitioning_to_chapter_9:
		return
	_transitioning_to_chapter_9 = true
	GameState.chapter_9_sida_rescued = true
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)
	Quest.set_completed(true)
	GameState.next_spawn = CHAPTER_9_SPAWN
	GameState.next_health = _player.current_health
	await SceneTransition.change_chapter(CHAPTER_9_SCENE)
