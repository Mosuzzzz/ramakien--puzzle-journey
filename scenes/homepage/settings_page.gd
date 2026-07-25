extends Control

const HOME_PAGE := "res://scenes/homepage/home_page.tscn"
const SCREEN_MODE_LABELS := ["Windowed", "Fullscreen"]

@onready var _volume_slider: HSlider = $ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/VolumeSlider
@onready var _volume_readout: Label = $ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/ReadoutBg/Readout
@onready var _screen_mode_value: Label = $ContentFrame/Margin/VBox/Scroll/Content/ScreenModeRow/ValueBg/Value

func _ready() -> void:
	PauseMenu.set_hud_visible(false)
	Inv.set_hud_visible(false)
	Quest.set_hud_visible(false)
	_refresh()

func _refresh() -> void:
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_update_readout(Settings.master_volume)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_update_readout(value)

func _update_readout(value: float) -> void:
	_volume_readout.text = "%d%%" % roundi(value * 100.0)

func _on_screen_mode_cycle() -> void:
	Settings.set_fullscreen(not Settings.fullscreen)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _on_reset_pressed() -> void:
	Settings.set_master_volume(1.0)
	Settings.set_fullscreen(false)
	_refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HOME_PAGE)
