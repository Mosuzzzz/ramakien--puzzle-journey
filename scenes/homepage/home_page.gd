extends Control

const GameState := preload("res://scenes/game_state.gd")
const FIRST_CHAPTER := "res://scenes/prologue/prologue.tscn"

@onready var _start_button: Button = $Menu/StartButton

func _ready() -> void:
	_start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_start_pressed()

func _on_start_pressed() -> void:
	GameState.next_spawn = Vector2.INF
	GameState.chapter_1_intro_played = false
	get_tree().change_scene_to_file(FIRST_CHAPTER)

func _on_quit_pressed() -> void:
	get_tree().quit()
