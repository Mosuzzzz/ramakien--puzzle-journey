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
	GameState.next_spawn = Vector2.INF
	GameState.next_quest = {}
	GameState.chapter_1_intro_played = false
	GameState.chapter_1_audience_done = false
	GameState.tutorial_shown = false
	GameState.chapter_2_intro_played = false
	GameState.chapter_2_deer_defeated = false
	GameState.chapter_2_ashram_puzzle_solved = false
	GameState.chapter_2_deer_intro_played = false
	GameState.chapter_2_aftermath_played = false
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	GameState.chapter_6_left_chest_unlocked = false
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false
	GameState.chapter_8_intro_played = false
	GameState.chapter_9_thotsakan_defeated = false
	GameState.chapter_9_sida_rescued = false
	get_tree().change_scene_to_file(FIRST_CHAPTER)

func _on_load_pressed() -> void:
	SaveSlots.open("load")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_PAGE)
