extends Node

signal sfx_played(sound_key: StringName)

const BACKGROUND := &"background"
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
const SFX_POOL_SIZE := 12

const SOUND_PATHS := {
	BACKGROUND: "res://assets/audio/music/background.mp3",
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
}

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _pool_cursor := 0
var _run_owner: Node
var _last_scene_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_create_players()
	get_tree().node_added.connect(_on_node_added)
	_register_buttons_recursive(get_tree().root)
	_sync_music_for_current_scene.call_deferred()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	if scene_id != _last_scene_id:
		_last_scene_id = scene_id
		_sync_music_for_current_scene()
	if _run_owner != null and not is_instance_valid(_run_owner):
		stop_run_loop()


func has_sound(sound_key: StringName) -> bool:
	return _streams.has(sound_key)


func play_sfx(sound_key: StringName) -> void:
	if not _streams.has(sound_key):
		push_warning("AudioManager: unknown or missing sound '%s'" % sound_key)
		return
	var player := _next_sfx_player()
	player.stream = _streams[sound_key]
	player.play()
	sfx_played.emit(sound_key)


func set_run_active(owner: Node, active: bool) -> void:
	if active:
		_run_owner = owner
		var player := get_node("RunLoop") as AudioStreamPlayer
		if not player.playing and _streams.has(RUN):
			player.stream = _streams[RUN]
			player.play()
	elif _run_owner == owner or _run_owner == null:
		stop_run_loop()


func stop_run_loop() -> void:
	_run_owner = null
	(get_node("RunLoop") as AudioStreamPlayer).stop()


func sync_music_for_scene_path(scene_path: String) -> void:
	var should_play := (
		scene_path.begins_with("res://scenes/chapter_")
		or scene_path.begins_with("res://scenes/cutscene/chapter_")
	)
	var music := get_node("Music") as AudioStreamPlayer
	if should_play:
		if not music.playing and _streams.has(BACKGROUND):
			music.stream = _streams[BACKGROUND]
			music.play()
	else:
		music.stop()


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
		if stream is AudioStreamMP3 and key in [BACKGROUND, RUN]:
			stream.loop = true
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
