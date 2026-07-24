extends Node2D

const GameState := preload("res://scenes/game_state.gd")

@onready var _sida: CharacterBody2D = $YSortRoot/Sida


func _ready() -> void:
	if not _sida.following_started.is_connected(_on_sida_following_started):
		_sida.following_started.connect(_on_sida_following_started)
	if GameState.chapter_9_sida_rescued:
		_sida.start_following()


func _on_sida_following_started() -> void:
	GameState.chapter_9_sida_rescued = true
