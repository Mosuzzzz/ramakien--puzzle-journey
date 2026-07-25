extends Node

const PATH := "user://settings.cfg"

var master_volume := 1.0
var fullscreen := false

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		master_volume = cfg.get_value("audio", "master", 1.0)
		fullscreen = cfg.get_value("display", "fullscreen", false)
	_apply_volume()
	_apply_fullscreen()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_volume()
	_save()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_save()

func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)

func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), linear_to_db(maxf(master_volume, 0.0001))
	)

func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)
