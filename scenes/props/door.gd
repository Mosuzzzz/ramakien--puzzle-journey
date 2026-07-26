extends StaticBody2D

const GameState := preload("res://scenes/core/game_state.gd")

@export var north_spot := Vector2(0, -180)
@export var south_spot := Vector2(0, 30)
@export_file("*.tscn") var exit_scene: String = ""
@export var exit_spawn := Vector2.ZERO
@export var farewell_lines: Array[String] = []
@export var farewell_title: String = ""

var _player: Node2D = null
var _farewell_played := false

@onready var _prompt: Label = $Prompt

func _on_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player = body
		_update_prompt()
		_prompt.show()

func _on_zone_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_prompt.hide()

func _process(_delta: float) -> void:
	if _player:
		# keep the prompt floating above the player's head (label is 180 px wide)
		_prompt.global_position = _player.global_position + Vector2(-90, -68)

func _input(event: InputEvent) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_cross()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cross()
		get_viewport().set_input_as_handled()

func _is_inside() -> bool:
	return _player.global_position.y < global_position.y - 65.0

func _cross() -> void:
	if _is_inside() and exit_scene != "":
		if farewell_lines.is_empty() or _farewell_played:
			_go_to_exit_scene()
		else:
			_farewell_played = true
			Dialogue.finished.connect(_go_to_exit_scene, CONNECT_ONE_SHOT)
			Dialogue.start_narration(farewell_lines, farewell_title)
		return
	_player.global_position = global_position + (south_spot if _is_inside() else north_spot)
	_update_prompt()

func _go_to_exit_scene() -> void:
	GameState.next_spawn = exit_spawn
	get_tree().change_scene_to_file.call_deferred(exit_scene)

func _update_prompt() -> void:
	_prompt.text = "กด E เพื่อออกจากวัง" if _is_inside() else "กด E เพื่อเข้าวัง"
