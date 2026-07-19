extends CanvasLayer

const HOME_PAGE := "res://scenes/homepage/home_page.tscn"
const FONT_LABELS := ["เล็ก", "กลาง", "ใหญ่"]

var _hud_allowed := true

@onready var _gear: TextureButton = $GearButton
@onready var _dim: Control = $Dim
@onready var _volume_slider: HSlider = $Dim/Panel/VBox/VolumeSlider
@onready var _fullscreen_check: CheckButton = $Dim/Panel/VBox/FullscreenCheck
@onready var _font_option: OptionButton = $Dim/Panel/VBox/FontRow/FontOption

func _ready() -> void:
	_dim.visible = false
	for label in FONT_LABELS:
		_font_option.add_item(label)

func _unhandled_input(event: InputEvent) -> void:
	if _hud_allowed and event.is_action_pressed("ui_cancel"):
		_toggle()

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
		_volume_slider.set_value_no_signal(Settings.master_volume)
		_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
		_font_option.select(Settings.font_size_index)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)

func _on_fullscreen_toggled(on: bool) -> void:
	Settings.set_fullscreen(on)

func _on_font_selected(index: int) -> void:
	Settings.set_font_size_index(index)

func _on_resume_pressed() -> void:
	_toggle()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	_dim.visible = false
	get_tree().change_scene_to_file(HOME_PAGE)
