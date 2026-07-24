extends Node2D

const GameState := preload("res://scenes/game_state.gd")

@onready var _thotsakan: CharacterBody2D = $YSortRoot/Thotsakan
@onready var _sida: CharacterBody2D = $YSortRoot/Sida
@onready var _ending_cutscene: Control = $Chapter9EndingCutsceneLayer/Chapter9EndingCutscene


func _ready() -> void:
	if GameState.chapter_9_thotsakan_defeated:
		_thotsakan.queue_free()
	elif not _thotsakan.defeated.is_connected(_on_thotsakan_defeated):
		_thotsakan.defeated.connect(_on_thotsakan_defeated)

	if GameState.chapter_9_sida_rescued:
		_sida.start_following()
	else:
		_sida.queue_free()


func _on_thotsakan_defeated() -> void:
	GameState.chapter_9_thotsakan_defeated = true


func show_ending_cutscene() -> void:
	_ending_cutscene.show_cutscene()
