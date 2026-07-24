extends Node2D

const GameState := preload("res://scenes/game_state.gd")

@onready var _sida: CharacterBody2D = $YSortRoot/Sida


func _ready() -> void:
	$RoomEntranceLeftUpper.locked_prompt_text = "ห้องถูกล็อก ต้องกำจัดทศกัณฐ์ก่อน"
	$RoomEntranceLeftUpper.set_locked(not GameState.chapter_9_thotsakan_defeated)

	if GameState.chapter_9_sida_rescued:
		$YSortRoot/Sida.start_following()
	else:
		_sida.queue_free()
