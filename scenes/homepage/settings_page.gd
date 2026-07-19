extends Control

const HOME_PAGE := "res://scenes/homepage/home_page.tscn"
const FONT_LABELS := ["เล็ก", "กลาง", "ใหญ่"]

@onready var _volume_slider: HSlider = $Panel/VBox/VolumeSlider
@onready var _fullscreen_check: CheckButton = $Panel/VBox/FullscreenCheck
@onready var _font_option: OptionButton = $Panel/VBox/FontRow/FontOption

func _ready() -> void:
	PauseMenu.set_hud_visible(false)
	Inv.set_hud_visible(false)
	Quest.set_hud_visible(false)
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	for label in FONT_LABELS:
		_font_option.add_item(label)
	_font_option.select(Settings.font_size_index)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)

func _on_fullscreen_toggled(on: bool) -> void:
	Settings.set_fullscreen(on)

func _on_font_selected(index: int) -> void:
	Settings.set_font_size_index(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HOME_PAGE)
