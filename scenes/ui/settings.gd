extends Node

const PATH := "user://settings.cfg"

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false

func _ready() -> void:
	load_from(PATH)

func load_from(path: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		master_volume = cfg.get_value("audio", "master", 1.0)
		music_volume = cfg.get_value("audio", "music", master_volume)
		sfx_volume = cfg.get_value("audio", "sfx", master_volume)
		fullscreen = cfg.get_value("display", "fullscreen", false)
	_apply_bus_volume(&"Master", master_volume)
	_apply_bus_volume(&"Music", music_volume)
	_apply_bus_volume(&"SFX", sfx_volume)
	_apply_fullscreen()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus_volume(&"Master", master_volume)
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
	_save()

func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)

func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Settings: missing audio bus %s" % bus_name)
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))

func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _save() -> void:
	save_to(PATH)

func save_to(path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(path)
