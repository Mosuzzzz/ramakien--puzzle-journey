extends CanvasLayer

const HOME_PAGE := "res://scenes/homepage/home_page.tscn"
const SCREEN_MODE_LABELS := ["Windowed", "Fullscreen"]

var _hud_allowed := true

@onready var _gear: TextureButton = $GearButton
@onready var _dim: Control = $Dim
@onready var _volume_slider: HSlider = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/VolumeSlider
@onready var _volume_readout: Label = $Dim/ContentFrame/Margin/VBox/Scroll/Content/MasterVolumeRow/ReadoutBg/Readout
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
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_update_readout(Settings.master_volume)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _update_readout(value: float) -> void:
	_volume_readout.text = "%d%%" % roundi(value * 100.0)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_update_readout(value)

func _on_screen_mode_cycle() -> void:
	Settings.set_fullscreen(not Settings.fullscreen)
	_screen_mode_value.text = SCREEN_MODE_LABELS[1 if Settings.fullscreen else 0]

func _on_reset_pressed() -> void:
	Settings.set_master_volume(1.0)
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
