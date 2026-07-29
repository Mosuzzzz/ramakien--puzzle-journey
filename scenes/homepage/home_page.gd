extends Control

const GameState := preload("res://scenes/core/game_state.gd")
const FIRST_CHAPTER := "res://scenes/prologue/prologue.tscn"
const SETTINGS_PAGE := "res://scenes/homepage/settings_page.tscn"

@onready var _start_button: Button = $Menu/StartButton

func _ready() -> void:
	_start_button.grab_focus()
	PauseMenu.set_hud_visible(false)
	Inv.set_hud_visible(false)
	Quest.set_hud_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_start_pressed()

func _on_start_pressed() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file(FIRST_CHAPTER)

func _on_load_pressed() -> void:
	SaveSlots.open("load")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_PAGE)
