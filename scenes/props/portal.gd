extends Area2D

signal activated(portal: Area2D)
signal locked_interaction(portal: Area2D)

const GameState := preload("res://scenes/core/game_state.gd")
const SaveGame := preload("res://scenes/core/save_game.gd")

@export_file("*.tscn") var target_scene: String
@export var target_spawn := Vector2.ZERO
@export var prompt_text := "กด E"
@export var interaction_size := Vector2(110, 60)
@export var locked := false
@export var locked_prompt_text := "ทางยังถูกปิดกั้นอยู่"
# when true, walking into the zone teleports immediately (no E press needed)
@export var auto := false

var _player: Node2D = null

@onready var _prompt: Label = $Prompt
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var rectangle := _collision.shape.duplicate() as RectangleShape2D
	rectangle.size = interaction_size
	_collision.shape = rectangle
	input_event.connect(_on_input_event)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player = body
		if auto and not locked:
			_use_portal()
			return
		_update_prompt()
		_prompt.show()

func set_locked(value: bool) -> void:
	locked = value
	if _player:
		_update_prompt()

func _update_prompt() -> void:
	_prompt.text = locked_prompt_text if locked else prompt_text

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_prompt.hide()

func _process(_delta: float) -> void:
	if _player:
		_prompt.global_position = _player.global_position + Vector2(-90, -68)

func _input(event: InputEvent) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_use_portal()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_use_portal()

func _use_portal() -> void:
	if locked:
		locked_interaction.emit(self)
		get_viewport().set_input_as_handled()
		return
	var current_scene := get_tree().current_scene
	play_transition_sound_for_scene_path(
		current_scene.scene_file_path if current_scene != null else ""
	)
	activated.emit(self)
	GameState.next_spawn = target_spawn
	GameState.next_health = _player.current_health
	# save before the scene changes out from under us — save_autosave() reads
	# the *current* scene, so it must run synchronously, not deferred
	if Settings.auto_save_enabled:
		SaveGame.save_autosave()
	get_tree().change_scene_to_file.call_deferred(target_scene)
	get_viewport().set_input_as_handled()


func play_transition_sound_for_scene_path(current_scene_path: String) -> void:
	if locked:
		return
	if _is_room_scene_path(current_scene_path) or _is_room_scene_path(target_scene):
		AudioManager.play_sfx(AudioManager.DOOR)


func _is_room_scene_path(scene_path: String) -> bool:
	return (
		scene_path == "res://scenes/chapter_1/throne_room.tscn"
		or scene_path.contains("/chapter_6/chapter_6_room_")
		or scene_path.contains("/chapter_8/chapter_8_room")
	)
