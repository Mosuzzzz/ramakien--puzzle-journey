extends CanvasLayer

const HOME_PAGE := "res://scenes/homepage/home_page.tscn"
const SCREEN_MODE_LABELS := ["Windowed", "Fullscreen"]

var _hud_allowed := true

@onready var _gear: TextureButton = $GearButton
@onready var _dim: Control = $Dim
@onready var _master_slider: HSlider = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/VolumeSlider
@onready var _master_readout: Label = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/ReadoutBg/Readout
@onready var _music_slider: HSlider = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MusicVolumeRow/VolumeSlider
@onready var _music_readout: Label = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MusicVolumeRow/ReadoutBg/Readout
@onready var _sfx_slider: HSlider = $Dim/ContentFrame/Margin/VBox/Scroll/Content/SFXVolumeRow/VolumeSlider
@onready var _sfx_readout: Label = $Dim/ContentFrame/Margin/VBox/Scroll/Content/SFXVolumeRow/ReadoutBg/Readout
@onready var _screen_mode_value: Label = $Dim/ContentFrame/Margin/VBox/Scroll/Content/ScreenModeRow/ValueBg/Value

func _ready() -> void:
	_dim.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _hud_allowed and event.is_action_pressed("ui_cancel"):
		_toggle()

func is_open() -> bool:
	return _dim.visible

func force_close() -> void:
	_dim.visible = false
	get_tree().paused = false

func set_hud_visible(shown: bool) -> void:
	_hud_allowed = shown
	_gear.visible = shown
	if not shown:
		_dim.visible = false
		get_tree().paused = false

func _toggle() -> void:
	_dim.visible = not _dim.visible
	get_tree().paused = _dim.visible
	if _dim.visible:
		_refresh()

func _refresh() -> void:
	_master_slider.set_value_no_signal(Settings.master_volume)
	_music_slider.set_value_no_signal(Settings.music_volume)
	_sfx_slider.set_value_no_signal(Settings.sfx_volume)
	_update_readout(_master_readout, Settings.master_volume)
	_update_readout(_music_readout, Settings.music_volume)
	_update_readout(_sfx_readout, Settings.sfx_volume)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _update_readout(readout: Label, value: float) -> void:
	readout.text = "%d%%" % roundi(value * 100.0)

func _on_master_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_update_readout(_master_readout, value)

func _on_music_volume_changed(value: float) -> void:
	Settings.set_music_volume(value)
	_update_readout(_music_readout, value)

func _on_sfx_volume_changed(value: float) -> void:
	Settings.set_sfx_volume(value)
	_update_readout(_sfx_readout, value)

func _on_screen_mode_cycle() -> void:
	Settings.set_fullscreen(not Settings.fullscreen)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _on_reset_pressed() -> void:
	Settings.set_master_volume(1.0)
	Settings.set_music_volume(1.0)
	Settings.set_sfx_volume(1.0)
	Settings.set_fullscreen(false)
	_refresh()

func _on_resume_pressed() -> void:
	_toggle()

func _on_save_pressed() -> void:
	SaveSlots.open("save_exit")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	_dim.visible = false
	get_tree().change_scene_to_file(HOME_PAGE)
