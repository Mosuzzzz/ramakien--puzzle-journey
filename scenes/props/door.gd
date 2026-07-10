extends StaticBody2D

const GameState := preload("res://scenes/game_state.gd")

@export var north_spot := Vector2(0, -180)
@export var south_spot := Vector2(0, 30)
@export_file("*.tscn") var exit_scene: String = ""
@export var exit_spawn := Vector2.ZERO

var _player: Node2D = null

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

func _unhandled_input(event: InputEvent) -> void:
	if _player and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_cross()

func _is_inside() -> bool:
	return _player.global_position.y < global_position.y - 65.0

func _cross() -> void:
	if _is_inside() and exit_scene != "":
		GameState.next_spawn = exit_spawn
		get_tree().change_scene_to_file.call_deferred(exit_scene)
		return
	_player.global_position = global_position + (south_spot if _is_inside() else north_spot)
	_update_prompt()

func _update_prompt() -> void:
	_prompt.text = "กด E เพื่อออกจากวัง" if _is_inside() else "กด E เพื่อเข้าวัง"
