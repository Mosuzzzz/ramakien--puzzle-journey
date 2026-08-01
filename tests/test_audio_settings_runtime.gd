extends SceneTree

const TEST_PATH := "/tmp/ramakien-audio-settings-test.cfg"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := root.get_node("Settings")
	_expect(settings.has_method("set_music_volume"), "music setter exists")
	_expect(settings.has_method("set_sfx_volume"), "SFX setter exists")
	_expect(settings.has_method("save_to"), "settings can save to an explicit path")
	_expect(settings.has_method("load_from"), "settings can load from an explicit path")
	if _failures.is_empty():
		settings.set_master_volume(0.9)
		settings.set_music_volume(0.25)
		settings.set_sfx_volume(0.7)
		_expect(is_equal_approx(settings.music_volume, 0.25), "music is independent")
		_expect(is_equal_approx(settings.sfx_volume, 0.7), "SFX is independent")
		_expect(_bus_matches(&"Music", 0.25), "Music bus updated")
		_expect(_bus_matches(&"SFX", 0.7), "SFX bus updated")
		settings.save_to(TEST_PATH)
		settings.music_volume = 1.0
		settings.sfx_volume = 1.0
		settings.load_from(TEST_PATH)
		_expect(is_equal_approx(settings.music_volume, 0.25), "music persisted")
		_expect(is_equal_approx(settings.sfx_volume, 0.7), "SFX persisted")
		DirAccess.remove_absolute(TEST_PATH)
	_test_settings_screen("res://scenes/homepage/settings_page.tscn")
	_test_settings_screen("res://scenes/ui/pause_menu.tscn")
	_finish()


func _bus_matches(bus_name: StringName, linear_value: float) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	return bus_index >= 0 and is_equal_approx(
		AudioServer.get_bus_volume_db(bus_index),
		linear_to_db(linear_value)
	)


func _test_settings_screen(scene_path: String) -> void:
	var screen := (load(scene_path) as PackedScene).instantiate()
	_expect(screen.has_method("_on_music_volume_changed"), "%s wires Music slider" % scene_path)
	_expect(screen.has_method("_on_sfx_volume_changed"), "%s wires SFX slider" % scene_path)
	screen.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: audio settings runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
