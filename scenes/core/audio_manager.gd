extends Node

signal sfx_played(sound_key: StringName)

const BACKGROUND := &"background"
const BOSS_FIGHT := &"boss_fight"
const ANSWER_CORRECT := &"answer_correct"
const ANSWER_WRONG := &"answer_wrong"
const BUTTON_CLICK := &"button_click"
const ENEMY_ATTACKING := &"enemy_attacking"
const ENEMY_HIT := &"enemy_hit"
const PICKUP := &"pickup"
const RUN := &"run"
const SWORD_ATTACK := &"sword_attack"
const HURT := &"hurt"
const THRASH := &"thrash"
const GIANT := &"giant"
const WAVE := &"wave"
const JUMP_THROW := &"jump_throw"
const HEAL_AND_PULL := &"heal_and_pull"
const GIANT_ATTACK := &"giant_attack"
const INVITE := &"invite"
const DOOR := &"door"
const SFX_POOL_SIZE := 12
const MENU_MUSIC_GAIN := 1.0
const GAMEPLAY_MUSIC_GAIN := 0.3
const MUSIC_FADE_SECONDS := 1.5
const SILENT_MUSIC_DB := -80.0

const SOUND_PATHS := {
	BACKGROUND: "res://assets/audio/music/background.mp3",
	BOSS_FIGHT: "res://assets/audio/music/boss_fight.mp3",
	ANSWER_CORRECT: "res://assets/audio/sfx/answer_correct.mp3",
	ANSWER_WRONG: "res://assets/audio/sfx/answer_wrong.mp3",
	BUTTON_CLICK: "res://assets/audio/sfx/button_click.mp3",
	ENEMY_ATTACKING: "res://assets/audio/sfx/enemy_attacking.mp3",
	ENEMY_HIT: "res://assets/audio/sfx/enemy_hit.mp3",
	PICKUP: "res://assets/audio/sfx/pickup.mp3",
	RUN: "res://assets/audio/sfx/run.mp3",
	SWORD_ATTACK: "res://assets/audio/sfx/sword_attack.mp3",
	HURT: "res://assets/audio/sfx/hurt.mp3",
	THRASH: "res://assets/audio/sfx/thrash.mp3",
	GIANT: "res://assets/audio/sfx/giant.mp3",
	WAVE: "res://assets/audio/sfx/wave.mp3",
	JUMP_THROW: "res://assets/audio/sfx/jump_throw.mp3",
	HEAL_AND_PULL: "res://assets/audio/sfx/heal_and_pull.mp3",
	GIANT_ATTACK: "res://assets/audio/sfx/giant_attack.mp3",
	INVITE: "res://assets/audio/sfx/invite.mp3",
	DOOR: "res://assets/audio/sfx/door.mp3",
}

const SOUND_GAINS := {
	DOOR: 1.5,
}

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _pool_cursor := 0
var _run_owners: Dictionary[int, WeakRef] = {}
var _last_scene_id := 0
var _last_scene_path := ""
var _music_tween: Tween
var _music_request_serial := 0
var _requested_music_key: StringName = &""
var _requested_music_gain := MENU_MUSIC_GAIN
var _boss_music_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_create_players()
	(get_node("Music") as AudioStreamPlayer).finished.connect(_on_music_finished)
	get_tree().node_added.connect(_on_node_added)
	_register_buttons_recursive(get_tree().root)
	_sync_music_for_current_scene.call_deferred()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	if scene_id != _last_scene_id:
		_last_scene_id = scene_id
		_sync_music_for_current_scene()
	_prune_run_owners()


func has_sound(sound_key: StringName) -> bool:
	return _streams.has(sound_key)


func play_sfx(sound_key: StringName) -> void:
	if not _streams.has(sound_key):
		push_warning("AudioManager: unknown or missing sound '%s'" % sound_key)
		return
	var player := _next_sfx_player()
	player.stream = _streams[sound_key]
	player.volume_db = linear_to_db(float(SOUND_GAINS.get(sound_key, 1.0)))
	player.play()
	sfx_played.emit(sound_key)


func set_run_active(owner: Node, active: bool) -> void:
	if owner == null:
		return
	var owner_id := owner.get_instance_id()
	if active:
		_run_owners[owner_id] = weakref(owner)
	else:
		_run_owners.erase(owner_id)
	_refresh_run_loop()


func stop_run_loop() -> void:
	_run_owners.clear()
	(get_node("RunLoop") as AudioStreamPlayer).stop()


func play_boss_music(fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
	_boss_music_active = true
	_request_music(BOSS_FIGHT, GAMEPLAY_MUSIC_GAIN, true, fade_seconds)


func restore_background_music(fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
	_boss_music_active = false
	_request_music(BACKGROUND, _music_gain_for_scene(_last_scene_path), true, fade_seconds)


func _prune_run_owners() -> void:
	for owner_id: int in _run_owners.keys():
		var owner_ref := _run_owners[owner_id] as WeakRef
		if owner_ref.get_ref() == null:
			_run_owners.erase(owner_id)
	_refresh_run_loop()


func _refresh_run_loop() -> void:
	var player := get_node("RunLoop") as AudioStreamPlayer
	if _run_owners.is_empty():
		player.stop()
	elif not player.playing and _streams.has(RUN):
		player.stream = _streams[RUN]
		player.play()


func sync_music_for_scene_path(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	_last_scene_path = scene_path
	var is_menu := scene_path.begins_with("res://scenes/homepage/")
	var is_gameplay := (
		scene_path == "res://scenes/prologue/prologue.tscn"
		or scene_path.begins_with("res://scenes/chapter_")
		or scene_path.begins_with("res://scenes/cutscene/chapter_")
	)
	if not is_menu and not is_gameplay:
		_boss_music_active = false
		_music_request_serial += 1
		if _music_tween != null and _music_tween.is_valid():
			_music_tween.kill()
		_music_tween = null
		_requested_music_key = &""
		(get_node("Music") as AudioStreamPlayer).stop()
		return
	if _boss_music_active and is_gameplay:
		return
	_boss_music_active = false
	_request_music(
		BACKGROUND,
		GAMEPLAY_MUSIC_GAIN if is_gameplay else MENU_MUSIC_GAIN,
		false,
		MUSIC_FADE_SECONDS
	)


func _request_music(
	sound_key: StringName,
	target_gain: float,
	restart_from_beginning: bool,
	fade_seconds: float
) -> void:
	var music := get_node("Music") as AudioStreamPlayer
	if not _streams.has(sound_key):
		push_warning("AudioManager: unknown or missing music '%s'" % sound_key)
		return
	_requested_music_gain = target_gain
	var target_stream := _streams[sound_key] as AudioStream
	if _requested_music_key == sound_key:
		if (
			_music_tween != null
			and _music_tween.is_valid()
			and _music_tween.is_running()
		):
			return
		if music.stream == target_stream and music.playing:
			music.volume_db = linear_to_db(target_gain)
			return
	_requested_music_key = sound_key
	_music_request_serial += 1
	var serial := _music_request_serial
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if fade_seconds <= 0.0 or not music.playing:
		_swap_and_fade_in(
			sound_key, target_gain, restart_from_beginning, fade_seconds, serial
		)
		return
	_music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(music, "volume_db", SILENT_MUSIC_DB, fade_seconds)
	_music_tween.tween_callback(
		_swap_and_fade_in.bind(
			sound_key, target_gain, restart_from_beginning, fade_seconds, serial
		)
	)


func _swap_and_fade_in(
	sound_key: StringName,
	target_gain: float,
	restart_from_beginning: bool,
	fade_seconds: float,
	serial: int
) -> void:
	if serial != _music_request_serial:
		return
	var music := get_node("Music") as AudioStreamPlayer
	var target_stream := _streams[sound_key] as AudioStream
	var start_position := 0.0
	if not restart_from_beginning and music.stream == target_stream and music.playing:
		start_position = music.get_playback_position()
	music.stream = target_stream
	music.volume_db = (
		SILENT_MUSIC_DB if fade_seconds > 0.0 else linear_to_db(target_gain)
	)
	music.play(start_position)
	if fade_seconds <= 0.0:
		return
	_music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(
		music, "volume_db", linear_to_db(target_gain), fade_seconds
	)


func _music_gain_for_scene(scene_path: String) -> float:
	return (
		MENU_MUSIC_GAIN
		if scene_path.begins_with("res://scenes/homepage/")
		else GAMEPLAY_MUSIC_GAIN
	)


func _on_music_finished() -> void:
	if _requested_music_key.is_empty() or not _streams.has(_requested_music_key):
		return
	_music_request_serial += 1
	var serial := _music_request_serial
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_swap_and_fade_in(
		_requested_music_key,
		_requested_music_gain,
		true,
		MUSIC_FADE_SECONDS,
		serial
	)


func _load_streams() -> void:
	for key: StringName in SOUND_PATHS:
		var path := String(SOUND_PATHS[key])
		if not ResourceLoader.exists(path):
			push_warning("AudioManager: missing resource %s" % path)
			continue
		var stream := ResourceLoader.load(path) as AudioStream
		if stream == null:
			push_warning("AudioManager: failed to load %s" % path)
			continue
		if stream is AudioStreamMP3:
			stream.loop = key == RUN
		_streams[key] = stream


func _create_players() -> void:
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.bus = &"Music"
	add_child(music)
	var run_loop := AudioStreamPlayer.new()
	run_loop.name = "RunLoop"
	run_loop.bus = &"SFX"
	add_child(run_loop)
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%02d" % index
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


func _next_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	var player := _sfx_players[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % _sfx_players.size()
	return player


func _sync_music_for_current_scene() -> void:
	var scene := get_tree().current_scene
	sync_music_for_scene_path(scene.scene_file_path if scene != null else "")


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_button(node)


func _register_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		_register_button(node)
	for child in node.get_children():
		_register_buttons_recursive(child)


func _register_button(button: BaseButton) -> void:
	if button.has_meta("audio_click_connected"):
		return
	button.set_meta("audio_click_connected", true)
	button.button_down.connect(play_sfx.bind(BUTTON_CLICK))
