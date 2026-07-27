extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E:
			Inv.reset_for_new_story()
			GameState.next_spawn = Vector2.INF
			get_tree().change_scene_to_file("res://scenes/chapter_1/chapter_1.tscn")
