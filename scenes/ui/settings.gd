extends Node

const PATH := "user://settings.cfg"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false
var muted := false
var brightness := 1.0
var resolution_index := 2
var hints_enabled := true
var tutorial_tips_enabled := true
var auto_save_enabled := true

func _ready() -> void:
	load_from(PATH)

func load_from(path: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		master_volume = cfg.get_value("audio", "master", 1.0)
		music_volume = cfg.get_value("audio", "music", master_volume)
		sfx_volume = cfg.get_value("audio", "sfx", master_volume)
		muted = cfg.get_value("audio", "muted", false)
		fullscreen = cfg.get_value("display", "fullscreen", false)
		brightness = cfg.get_value("display", "brightness", 1.0)
		resolution_index = cfg.get_value("display", "resolution_index", RESOLUTIONS.size() - 1)
		hints_enabled = cfg.get_value("gameplay", "hints", true)
		tutorial_tips_enabled = cfg.get_value("gameplay", "tutorial_tips", true)
		auto_save_enabled = cfg.get_value("gameplay", "auto_save", true)
	_apply_bus_volume(&"Master", master_volume)
	_apply_bus_volume(&"Music", music_volume)
	_apply_bus_volume(&"SFX", sfx_volume)
	_apply_master_mute()
	_apply_fullscreen()
	_apply_resolution()
	_apply_brightness()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(&"Master", master_volume)
	_apply_master_mute()
	_save()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(&"Music", music_volume)
	_save()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(&"SFX", sfx_volume)
	_save()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_apply_resolution()
	_save()

func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)

func set_muted(on: bool) -> void:
	muted = on
	_apply_master_mute()
	_save()

func toggle_muted() -> void:
	set_muted(not muted)

func set_brightness(v: float) -> void:
	brightness = clampf(v, 0.0, 1.0)
	_apply_brightness()
	_save()

func cycle_resolution(delta: int) -> void:
	resolution_index = wrapi(resolution_index + delta, 0, RESOLUTIONS.size())
	_apply_resolution()
	_save()

func resolution_label() -> String:
	var res: Vector2i = RESOLUTIONS[resolution_index]
	return "%d x %d" % [res.x, res.y]

func set_hints_enabled(on: bool) -> void:
	hints_enabled = on
	_save()

func set_tutorial_tips_enabled(on: bool) -> void:
	tutorial_tips_enabled = on
	_save()

func set_auto_save_enabled(on: bool) -> void:
	auto_save_enabled = on
	_save()

func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Settings: missing audio bus %s" % bus_name)
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
	if bus_name != &"Master":
		AudioServer.set_bus_mute(bus_index, value <= 0.0)

func _apply_master_mute() -> void:
	var bus_index := AudioServer.get_bus_index(&"Master")
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, muted or master_volume <= 0.0)

func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _apply_resolution() -> void:
	if fullscreen:
		return
	var size: Vector2i = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(size)
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - size) / 2)

func _apply_brightness() -> void:
	# ponytail: a single global dim overlay, not per-scene color grading
	if is_instance_valid(ScreenDim):
		ScreenDim.set_brightness(brightness)

func _save() -> void:
	save_to(PATH)

func save_to(path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "brightness", brightness)
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.set_value("gameplay", "hints", hints_enabled)
	cfg.set_value("gameplay", "tutorial_tips", tutorial_tips_enabled)
	cfg.set_value("gameplay", "auto_save", auto_save_enabled)
	cfg.save(path)
