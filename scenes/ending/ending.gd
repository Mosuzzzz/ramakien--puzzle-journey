extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const HOME_PAGE := "res://scenes/homepage/home_page.tscn"

func _ready() -> void:
	PauseMenu.set_hud_visible(false)
	Inv.set_hud_visible(false)
	Quest.set_hud_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E:
			Inv.reset_for_new_story()
			GameState.next_spawn = Vector2.INF
			get_tree().change_scene_to_file(HOME_PAGE)
