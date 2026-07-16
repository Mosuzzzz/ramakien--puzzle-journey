extends Node2D

const GameState := preload("res://scenes/game_state.gd")

func _ready() -> void:
	if GameState.chapter_1_intro_played:
		return
	GameState.chapter_1_intro_played = true
	Quest.set_quest("เข้าเฝ้าท้าวทศรถ")
